/*
 * Nova Airstrike 3D prototype
 * PS2SDK Graphics Synthesizer path with hardware Z-buffer depth testing.
 * Original homebrew code; no commercial game assets.
 */
#include <tamtypes.h>
#include <kernel.h>
#include <sifrpc.h>
#include <loadfile.h>
#include <libpad.h>
#include <gif_tags.h>
#include <gs_gp.h>
#include <gs_psm.h>
#include <dma.h>
#include <dma_tags.h>
#include <draw.h>
#include <graph.h>
#include <packet.h>
#include <stdio.h>
#include "audio.h"

#define SW 512
#define SH 512
#define ENEMIES 6
#define SHOTS 18
#define PARTICLES 24
#define FOCAL 170
#define NEAR_Z 8.0f
#define PACKET_QWORDS 4096
#define DEPTH_CLEAR 0u
#define DEPTH_UI 0x7fffffffu

typedef struct { float x,y,z; } V3;
typedef struct { float x,y,z; int hp,kind; } Enemy;
typedef struct { float x,y,z; int active,kind; } Shot;
typedef struct { float x,y,z,vx,vy,vz; int life; } Particle;
static char pad_dma[256] __attribute__((aligned(64)));
static int pad_ok=0, stick_x=0, stick_y=0;
static u32 rng=0x4E4F5641u;

static float absf(float v){ return v<0?-v:v; }
static float clampf(float v,float a,float b){ return v<a?a:(v>b?b:v); }
static int clampi(int v,int a,int b){ return v<a?a:(v>b?b:v); }
static int rnd(int n){ rng=rng*1664525u+1013904223u; return (int)(rng%(u32)n); }

/* GS uses greater-equal depth: nearer camera-space Z maps to a larger value. */
static u32 depth_from_z(float z){
 float d=2147483647.0f-z*8388608.0f;
 if(d<1.0f)d=1.0f;
 return (u32)d;
}
static void pad_init(void){
 int i,r;
 r=SifLoadModule("rom0:SIO2MAN",0,NULL); if(r<0)return;
 r=SifLoadModule("rom0:PADMAN",0,NULL); if(r<0)return;
 padInit(0); if(padPortOpen(0,0,pad_dma)==0)return;
 for(i=0;i<300;i++){ int s=padGetState(0,0);
  if(s==PAD_STATE_STABLE||s==PAD_STATE_FINDCTP1){pad_ok=1;return;}
  graph_wait_vsync();
 }
}
static u32 pad_read(void){
 struct padButtonStatus b; int s; stick_x=stick_y=0;
 if(!pad_ok)return 0;
 s=padGetState(0,0);
 if(s!=PAD_STATE_STABLE&&s!=PAD_STATE_FINDCTP1)return 0;
 if(padRead(0,0,&b)==0)return 0;
 stick_x=(int)b.ljoy_h-128; stick_y=128-(int)b.ljoy_v;
 return (u32)(0xffffu^b.btns);
}
static qword_t *rect(qword_t*q,int x,int y,int w,int h,int r,int g,int b,u32 z){
 int x0=(x<<4)+(2048<<4),y0=(y<<4)+(2048<<4);
 int x1=((x+w)<<4)+(2048<<4),y1=((y+h)<<4)+(2048<<4);
 PACK_GIFTAG(q,GIF_SET_TAG(4,1,0,0,0,1),GIF_REG_AD);q++;
 PACK_GIFTAG(q,GIF_SET_PRIM(6,0,0,0,0,0,0,0,0),GIF_REG_PRIM);q++;
 PACK_GIFTAG(q,GIF_SET_RGBAQ(r,g,b,0x80,0x3f800000),GIF_REG_RGBAQ);q++;
 PACK_GIFTAG(q,GIF_SET_XYZ(x0,y0,z),GIF_REG_XYZ2);q++;
 PACK_GIFTAG(q,GIF_SET_XYZ(x1,y1,z),GIF_REG_XYZ2);q++;
 return q;
}
static qword_t *tri2(qword_t*q,int x0,int y0,u32 z0,int x1,int y1,u32 z1,
                     int x2,int y2,u32 z2,int r,int g,int b){
 u64 c=GIF_SET_RGBAQ(r,g,b,0x80,0x3f800000);
 /* This is an intermediate tag: EOP must stay 0 or the triangle tag below is discarded. */
  PACK_GIFTAG(q,GIF_SET_TAG(1,0,0,0,0,1),GIF_REG_AD);q++;
 PACK_GIFTAG(q,GIF_SET_PRIM(3,0,0,0,0,0,0,0,0),GIF_REG_PRIM);q++;
 PACK_GIFTAG(q,GIF_SET_TAG(3,1,0,0,0,2),GIF_REG_RGBAQ|(GIF_REG_XYZ2<<4));q++;
 PACK_GIFTAG(q,c,GIF_REG_RGBAQ);q++; PACK_GIFTAG(q,GIF_SET_XYZ((x0<<4)+(2048<<4),(y0<<4)+(2048<<4),z0),GIF_REG_XYZ2);q++;
 PACK_GIFTAG(q,c,GIF_REG_RGBAQ);q++; PACK_GIFTAG(q,GIF_SET_XYZ((x1<<4)+(2048<<4),(y1<<4)+(2048<<4),z1),GIF_REG_XYZ2);q++;
 PACK_GIFTAG(q,c,GIF_REG_RGBAQ);q++; PACK_GIFTAG(q,GIF_SET_XYZ((x2<<4)+(2048<<4),(y2<<4)+(2048<<4),z2),GIF_REG_XYZ2);q++;
 return q;
}
static int project(V3 v,float camx,int *sx,int *sy,u32 *depth){
 float scale;
 if(v.z<NEAR_Z)return 0;
 scale=FOCAL/v.z;
 *sx=clampi((int)(256.0f+(v.x-camx)*scale),-1024,1536);
 *sy=clampi((int)(190.0f+1500.0f/v.z-v.y*scale),-1024,1536);
 *depth=depth_from_z(v.z);
 return 1;
}
/* Clip triangles against the near plane before perspective division.
   A crossing triangle becomes a quad and is submitted as two triangles. */
static int clip_near(const V3 in[3],V3 out[4]){
 int i,n=0;
 for(i=0;i<3;i++){
  V3 a=in[i],b=in[(i+1)%3];
  int ai=(a.z>=NEAR_Z),bi=(b.z>=NEAR_Z);
  if(ai&&bi){out[n++]=b;}
  else if(ai&&!bi){float t=(NEAR_Z-a.z)/(b.z-a.z);out[n++]=(V3){a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,NEAR_Z};}
  else if(!ai&&bi){float t=(NEAR_Z-a.z)/(b.z-a.z);out[n++]=(V3){a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,NEAR_Z};out[n++]=b;}
 }
 return n;
}
static qword_t *projected_tri(qword_t*q,V3 a,V3 b,V3 c,float camx,int r,int g,int bl){
 int ax,ay,bx,by,cx,cy; u32 az,bz,cz;
 if(!project(a,camx,&ax,&ay,&az)||!project(b,camx,&bx,&by,&bz)||!project(c,camx,&cx,&cy,&cz))return q;
 if((ax<0&&bx<0&&cx<0)||(ax>=SW&&bx>=SW&&cx>=SW)||(ay<0&&by<0&&cy<0)||(ay>=SH&&by>=SH&&cy>=SH))return q;
 return tri2(q,ax,ay,az,bx,by,bz,cx,cy,cz,r,g,bl);
}
static qword_t *tri3(qword_t*q,V3 a,V3 b,V3 c,float camx,int r,int g,int bl){
 V3 in[3],out[4];int n;in[0]=a;in[1]=b;in[2]=c;n=clip_near(in,out);
 if(n<3)return q;
 q=projected_tri(q,out[0],out[1],out[2],camx,r,g,bl);
 if(n==4)q=projected_tri(q,out[0],out[2],out[3],camx,r,g,bl);
 return q;
}
static qword_t *jet(qword_t*q,float x,float y,float z,float camx,int enemy){
 int br=enemy?190:85,bg=enemy?55:175,bb=enemy?55:235;
 int wr=enemy?105:35,wg=enemy?28:95,wb=enemy?32:185;
 V3 nose={x,y,z+2.2f},tail={x,y,z-2.0f};
 V3 wl={x-3.2f,y,z-0.6f},wrn={x+3.2f,y,z-0.6f};
 V3 tl={x-1.0f,y,z-1.5f},tr={x+1.0f,y,z-1.5f};
 V3 top={x,y+0.65f,z-0.8f},bot={x,y-0.45f,z-0.7f};
 V3 cockpit={x,y+0.9f,z+0.2f};
 q=tri3(q,nose,wl,top,camx,wr,wg,wb);
 q=tri3(q,nose,top,wrn,camx,br,bg,bb);
 q=tri3(q,nose,bot,wl,camx,br,bg,bb);
 q=tri3(q,nose,wrn,bot,camx,wr,wg,wb);
 q=tri3(q,tail,tl,top,camx,wr,wg,wb);
 q=tri3(q,tail,top,tr,camx,br,bg,bb);
 q=tri3(q,nose,tail,cockpit,camx,70,145,210);
 q=tri3(q,tail,tl,tr,camx,br/2,bg/2,bb/2);
 return q;
}
static qword_t *ocean(qword_t*q,float camx,int phase){
 int i; float z0,z1,shift=(float)(phase%24)*0.25f;
 for(i=0;i<9;i++){
  z0=18.0f+(float)i*15.0f+shift; z1=z0+15.0f;
  { V3 a={-34,-5,z0},b={34,-5,z0},c={34,-5,z1},d={-34,-5,z1};
    int shade=18+i*2;
    q=tri3(q,a,b,c,camx,5,shade,shade+24);
    q=tri3(q,a,c,d,camx,5,shade,shade+24);
    q=tri3(q,(V3){-34,-4.92f,z0},(V3){34,-4.92f,z0},(V3){34,-4.92f,z0+0.18f},camx,18,45,67);
  }
 }
 return q;
}
static void reset(float *px,float *py,int *lives,int *score,int *over,Enemy e[ENEMIES],Shot s[SHOTS]){
 int i; *px=0;*py=0;*lives=3;*score=0;*over=0;
 for(i=0;i<ENEMIES;i++){e[i].x=(float)(rnd(25)-12);e[i].y=(float)(rnd(9)-4)*0.45f;e[i].z=38.0f+i*23.0f;e[i].hp=1;e[i].kind=i%3;}
 for(i=0;i<SHOTS;i++)s[i].active=0;
}
static void burst(Particle p[PARTICLES],float x,float y,float z){
 int i;
 audio_play_sfx(NOVA_SFX_EXPLOSION);for(i=0;i<PARTICLES;i++)if(p[i].life<=0){
  float a=(float)(rnd(200)-100)*0.01f;
  p[i].x=x;p[i].y=y;p[i].z=z;p[i].vx=a*0.055f;
  p[i].vy=(float)(rnd(160)-80)*0.001f;p[i].vz=(float)(rnd(100)-50)*0.018f;
  p[i].life=12+rnd(12);
 }
}
static void update_particles(Particle p[PARTICLES]){
 int i;for(i=0;i<PARTICLES;i++)if(p[i].life>0){
  p[i].x+=p[i].vx;p[i].y+=p[i].vy;p[i].z+=p[i].vz;
  p[i].vx*=0.94f;p[i].vy-=0.0015f;--p[i].life;
 }
}
static void fire(Shot s[SHOTS],float x,float y){
 int i;
 audio_play_sfx(NOVA_SFX_FIRE);for(i=0;i<SHOTS;i++)if(!s[i].active){s[i].x=x;s[i].y=y;s[i].z=13.0f;s[i].active=1;s[i].kind=0;return;}
}
static void render(packet_t*p,zbuffer_t*zb,float px,float py,Enemy e[ENEMIES],Shot s[SHOTS],Particle particles[PARTICLES],
                   int lives,int score,int over,int frame){
 int i,progress=score*3; qword_t*q;
 if(progress>250)progress=250;
 dma_wait_fast();
 q=p->data;
 /* Clear colour and depth independently. A depth-zero full-screen sprite
    seeds the Z buffer before any perspective geometry is submitted. */
 q=draw_disable_tests(q,0,zb);
 q=draw_clear(q,0,0,0,SW,SH,2,7,19);
 q=rect(q,0,0,SW,SH,2,7,19,DEPTH_CLEAR);
 q=draw_enable_tests(q,0,zb);
 q=rect(q,0,0,SW,190,4,13,31,DEPTH_CLEAR);
 q=rect(q,0,185,SW,5,35,95,125,DEPTH_CLEAR);
 q=rect(q,0,190,SW,322,4,17,29,DEPTH_CLEAR);
 for(i=0;i<6;i++){int x=(i*103+(frame/3)%103)%SW;q=rect(q,x,150+(i%3)*8,42,3,25,55,77,DEPTH_CLEAR);}
 q=ocean(q,px*0.25f,frame);
 for(i=0;i<ENEMIES;i++)if(e[i].z>NEAR_Z)
  q=jet(q,e[i].x,e[i].y,e[i].z,px*0.25f,1);
 for(i=0;i<SHOTS;i++)if(s[i].active){
  V3 a={s[i].x-0.12f,s[i].y,s[i].z},b={s[i].x+0.12f,s[i].y,s[i].z},c={s[i].x,s[i].y,s[i].z+2.2f};
  q=tri3(q,a,b,c,px*0.25f,255,230,105);
 }
 for(i=0;i<PARTICLES;i++)if(particles[i].life>0){
  float size=0.10f+(float)particles[i].life*0.012f;
  int glow=clampi(255-particles[i].life*5,90,255);
  V3 a={particles[i].x-size,particles[i].y,particles[i].z};
  V3 b={particles[i].x+size,particles[i].y,particles[i].z};
  V3 c={particles[i].x,particles[i].y+size,particles[i].z};
  V3 d={particles[i].x,particles[i].y-size,particles[i].z};
  q=tri3(q,a,b,c,px*0.25f,glow,glow/2,35);
  q=tri3(q,a,c,d,px*0.25f,255,glow/3,25);
 }
 /* Engine exhaust is a small warm plume behind the player aircraft. */
 q=tri3(q,(V3){px-0.22f,py,9.2f},(V3){px+0.22f,py,9.2f},(V3){px,py,7.8f},px*0.25f,255,125,35);
 q=jet(q,px,py,11.0f,px*0.25f,0);
 q=rect(q,16,15,260,8,28,48,69,DEPTH_UI);
 q=rect(q,16,15,progress,8,25,220,165,DEPTH_UI);
 for(i=0;i<lives;i++)q=tri2(q,420+i*23,34,DEPTH_UI,426+i*23,19,DEPTH_UI,432+i*23,34,DEPTH_UI,255,80,90);
 q=rect(q,16,31,105,3,80,125,155,DEPTH_UI);
 if(over){q=rect(q,70,205,372,105,8,18,38,DEPTH_UI);q=rect(q,92,226,328,4,235,65,75,DEPTH_UI);q=rect(q,145,252,222,12,245,185,65,DEPTH_UI);}
 /* Fixed scene pools keep the packet comfortably below its 4096-qword cap. */
 if((u32)(q-p->data)>PACKET_QWORDS-16u)return;
 q=draw_finish(q);
 dma_channel_send_normal(DMA_CHANNEL_GIF,p->data,q-p->data,0,0);
 draw_wait_finish();graph_wait_vsync();
}
int main(void){
 framebuffer_t fb;zbuffer_t zb;packet_t*p;
 Enemy enemies[ENEMIES];Shot shots[SHOTS];Particle particles[PARTICLES];float px,py,vx=0.0f,vy=0.0f;int lives,score,over,frame=0,i;
 dma_channel_initialize(DMA_CHANNEL_GIF,NULL,0);dma_channel_fast_waits(DMA_CHANNEL_GIF);
 fb.width=SW;fb.height=SH;fb.mask=0;fb.psm=GS_PSM_32;
 fb.address=graph_vram_allocate(fb.width,fb.height,fb.psm,GRAPH_ALIGN_PAGE);
 zb.enable=DRAW_ENABLE;zb.mask=0;zb.method=ZTEST_METHOD_GREATER_EQUAL;zb.zsm=GS_ZBUF_32;
 zb.address=graph_vram_allocate(fb.width,fb.height,zb.zsm,GRAPH_ALIGN_PAGE);
 graph_initialize(fb.address,fb.width,fb.height,fb.psm,0,0);
 p=packet_init(PACKET_QWORDS,PACKET_NORMAL);
 if(!p){graph_shutdown();dma_channel_shutdown(DMA_CHANNEL_GIF,0);SleepThread();return 1;}
 {qword_t*q=draw_setup_environment(p->data,0,&fb,&zb);q=draw_finish(q);
  dma_channel_send_normal(DMA_CHANNEL_GIF,p->data,q-p->data,0,0);draw_wait_finish();}
 for(i=0;i<PARTICLES;i++)particles[i].life=0;
 sceSifInitRpc(0);
 audio_init(graph_get_region());
 pad_init();reset(&px,&py,&lives,&score,&over,enemies,shots);
 for(;;){
  u32 buttons=pad_read();
  if(over){if(buttons&PAD_START){int k;vx=vy=0.0f;for(k=0;k<PARTICLES;k++)particles[k].life=0;reset(&px,&py,&lives,&score,&over,enemies,shots);audio_play_sfx(NOVA_SFX_START);}}
  else{
   vx+=(buttons&PAD_LEFT)?-0.11f:0.0f;vx+=(buttons&PAD_RIGHT)?0.11f:0.0f;
   vy+=(buttons&PAD_UP)?0.09f:0.0f;vy+=(buttons&PAD_DOWN)?-0.09f:0.0f;
   if (stick_x < -24) vx += (float)stick_x * 0.0009f;
   if (stick_x > 24)  vx += (float)stick_x * 0.0009f;
   if (stick_y < -24) vy += (float)stick_y * 0.0008f;
   if (stick_y > 24)  vy += (float)stick_y * 0.0008f;

   vx *= 0.82f;
   vy *= 0.82f;
   px = clampf(px + vx, -13.0f, 13.0f);
   py = clampf(py + vy, -3.5f, 3.5f);
   if (px <= -13.0f || px >= 13.0f) vx = 0.0f;
   if (py <= -3.5f || py >= 3.5f) vy = 0.0f;
   if((buttons&(PAD_CROSS|PAD_SQUARE|PAD_CIRCLE|PAD_TRIANGLE|PAD_R1|PAD_R2))&&frame%7==0)fire(shots,px,py);
   for(i=0;i<SHOTS;i++)if(shots[i].active){
    shots[i].z+=2.6f;
    if(shots[i].z>125.0f)shots[i].active=0;
    else {int j;for(j=0;j<ENEMIES;j++)if(absf(shots[i].x-enemies[j].x)<2.1f&&absf(shots[i].y-enemies[j].y)<1.7f&&absf(shots[i].z-enemies[j].z)<3.0f){
      shots[i].active=0;burst(particles,enemies[j].x,enemies[j].y,enemies[j].z);enemies[j].z=145.0f+(float)rnd(55);enemies[j].x=(float)(rnd(25)-12);enemies[j].y=(float)(rnd(9)-4)*0.45f;++score;break;
    }}
   }
   for(i=0;i<ENEMIES;i++){
    enemies[i].z-=0.32f+(float)(score/30)*0.04f;
    if(enemies[i].z<NEAR_Z+2.0f){
     if(absf(enemies[i].x-px)<2.5f&&absf(enemies[i].y-py)<2.0f){burst(particles,px,py,11.0f);audio_play_sfx(NOVA_SFX_HIT);--lives;if(lives<=0){over=1;audio_play_sfx(NOVA_SFX_GAMEOVER);}}
     enemies[i].z=130.0f+(float)rnd(70);enemies[i].x=(float)(rnd(25)-12);enemies[i].y=(float)(rnd(9)-4)*0.45f;++score;
    }
   }
  }
  audio_set_engine(over?0:clampi((int)((absf(vx)+absf(vy))*90.0f),0,100));
  audio_tick();
  update_particles(particles);++frame;render(p,&zb,px,py,enemies,shots,particles,lives,score,over,frame);
 }
 return 0;
}
