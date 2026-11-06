/*
 * Nova Airstrike - original PS2 homebrew arcade shooter.
 * D-pad moves the fighter. CROSS / SQUARE / CIRCLE / R1 fires.
 * START restarts after game over.
 */
#include <tamtypes.h>
#include <kernel.h>
#include <sifrpc.h>
#include <loadfile.h>
#include <libpad.h>
#include <stdio.h>

#include <gif_tags.h>
#include <gs_gp.h>
#include <gs_psm.h>
#include <dma.h>
#include <dma_tags.h>
#include <draw.h>
#include <graph.h>
#include <packet.h>

#define SCREEN_W 512
#define SCREEN_H 512
#define PLAYER_W 28
#define PLAYER_H 42
#define ENEMY_COUNT 5
#define BULLET_COUNT 16
#define STAR_COUNT 28

typedef struct { int x, y, w, h, speed, hp; } Enemy;
typedef struct { int x, y, active, speed; } Bullet;
typedef struct { int x, y, speed; } Star;

static char pad_dma_buffer[256] __attribute__((aligned(64)));
static int pad_ready = 0;
static int stick_x = 0, stick_y = 0;
static u32 rng_state = 0x4E4F5641u;

static int clamp_int(int v, int lo, int hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}
static int random_x(void) {
    rng_state = rng_state * 1664525u + 1013904223u;
    return 24 + (int)(rng_state % 464u);
}
static void init_pad(void) {
    int i, ret;
    sceSifInitRpc(0);
    ret = SifLoadModule("rom0:SIO2MAN", 0, NULL);
    if (ret < 0) return;
    ret = SifLoadModule("rom0:PADMAN", 0, NULL);
    if (ret < 0) return;
    padInit(0);
    if (padPortOpen(0, 0, pad_dma_buffer) == 0) return;
    for (i = 0; i < 300; ++i) {
        int state = padGetState(0, 0);
        if (state == PAD_STATE_STABLE || state == PAD_STATE_FINDCTP1) {
            pad_ready = 1;
            return;
        }
        graph_wait_vsync();
    }
}
static u32 read_pad(void) {
    struct padButtonStatus b;
    int state;
    stick_x = 0; stick_y = 0;
    if (!pad_ready) return 0;
    state = padGetState(0, 0);
    if (state != PAD_STATE_STABLE && state != PAD_STATE_FINDCTP1) return 0;
    if (padRead(0, 0, &b) == 0) return 0;
    stick_x = (int)b.ljoy_h - 128;
    stick_y = (int)b.ljoy_v - 128;
    return (u32)(0xffffu ^ b.btns);
}
static int overlaps(int ax, int ay, int aw, int ah,
                    int bx, int by, int bw, int bh) {
    return ax < bx + bw && ax + aw > bx &&
           ay < by + bh && ay + ah > by;
}
static qword_t *draw_rect(qword_t *q, int x, int y, int w, int h,
                          int r, int g, int b) {
    int x0 = (x << 4) + (2048 << 4);
    int y0 = (y << 4) + (2048 << 4);
    int x1 = ((x + w) << 4) + (2048 << 4);
    int y1 = ((y + h) << 4) + (2048 << 4);
    PACK_GIFTAG(q, GIF_SET_TAG(4, 1, 0, 0, 0, 1), GIF_REG_AD); q++;
    PACK_GIFTAG(q, GIF_SET_PRIM(6, 0, 0, 0, 0, 0, 0, 0, 0), GIF_REG_PRIM); q++;
    PACK_GIFTAG(q, GIF_SET_RGBAQ(r, g, b, 0x80, 0x3f800000), GIF_REG_RGBAQ); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ(x0, y0, 0), GIF_REG_XYZ2); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ(x1, y1, 0), GIF_REG_XYZ2); q++;
    return q;
}
/* One flat-shaded triangle: three packed RGBAQ/XYZ2 vertex pairs. */
static qword_t *draw_triangle(qword_t *q, int x0, int y0, int x1, int y1,
                              int x2, int y2, int r, int g, int b) {
    u64 color = GIF_SET_RGBAQ(r, g, b, 0x80, 0x3f800000);
    /* Select triangle primitive before sending the three packed vertices. */
    PACK_GIFTAG(q, GIF_SET_TAG(1, 1, 0, 0, 0, 1), GIF_REG_AD); q++;
    PACK_GIFTAG(q, GIF_SET_PRIM(3, 0, 0, 0, 0, 0, 0, 0, 0), GIF_REG_PRIM); q++;
    PACK_GIFTAG(q, GIF_SET_TAG(6, 1, 0, 0, 0, 2),
                GIF_REG_RGBAQ | (GIF_REG_XYZ2 << 4)); q++;
    PACK_GIFTAG(q, color, GIF_REG_RGBAQ); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ((x0 << 4) + (2048 << 4),
                               (y0 << 4) + (2048 << 4), 0), GIF_REG_XYZ2); q++;
    PACK_GIFTAG(q, color, GIF_REG_RGBAQ); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ((x1 << 4) + (2048 << 4),
                               (y1 << 4) + (2048 << 4), 0), GIF_REG_XYZ2); q++;
    PACK_GIFTAG(q, color, GIF_REG_RGBAQ); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ((x2 << 4) + (2048 << 4),
                               (y2 << 4) + (2048 << 4), 0), GIF_REG_XYZ2); q++;
    return q;
}
/* Detailed top-down fighter silhouette built from layered polygons. */
static qword_t *draw_fighter(qword_t *q, int x, int y, int enemy) {
    int bodyR = enemy ? 220 : 170, bodyG = enemy ? 62 : 205;
    int bodyB = enemy ? 68 : 235;
    int edgeR = enemy ? 105 : 35, edgeG = enemy ? 22 : 105;
    int edgeB = enemy ? 28 : 190;
    /* swept wings */
    q = draw_triangle(q, x+14,y+8, x-2,y+27, x+12,y+25, edgeR,edgeG,edgeB);
    q = draw_triangle(q, x+14,y+8, x+16,y+25, x+30,y+27, edgeR,edgeG,edgeB);
    q = draw_triangle(q, x+14,y+1, x+9,y+32, x+19,y+32, bodyR,bodyG,bodyB);
    /* tailplanes and vertical stabilizer */
    q = draw_triangle(q, x+14,y+27, x+4,y+39, x+13,y+35, edgeR,edgeG,edgeB);
    q = draw_triangle(q, x+14,y+27, x+15,y+35, x+25,y+39, edgeR,edgeG,edgeB);
    q = draw_triangle(q, x+14,y+30, x+10,y+41, x+18,y+41, bodyR,bodyG,bodyB);
    /* cockpit, nose glint, engines */
    q = draw_rect(q, x+11,y+12, 6,12, 35,55,85);
    q = draw_rect(q, x+12,y+13, 4,8, 100,205,235);
    q = draw_rect(q, x+6,y+34, 4,5, 255,150,45);
    q = draw_rect(q, x+19,y+34, 4,5, 255,150,45);
    q = draw_triangle(q, x+14,y-5, x+10,y+8, x+18,y+8, 245,250,255);
    return q;
}
static void init_game(int *px, int *py, int *lives, int *score,
                      int *over, Enemy e[ENEMY_COUNT],
                      Bullet b[BULLET_COUNT], Star s[STAR_COUNT]) {
    int i;
    *px = (SCREEN_W - PLAYER_W)/2;
    *py = SCREEN_H - 72;
    *lives = 3; *score = 0; *over = 0;
    for (i=0;i<ENEMY_COUNT;i++) {
        e[i].w=28; e[i].h=42; e[i].x=24+i*94;
        e[i].y=-60-i*100; e[i].speed=2+i%3; e[i].hp=1;
    }
    for (i=0;i<BULLET_COUNT;i++) b[i].active=0;
    for (i=0;i<STAR_COUNT;i++) {
        s[i].x=(i*73+19)%SCREEN_W; s[i].y=(i*47+11)%SCREEN_H;
        s[i].speed=1+(i%3);
    }
}
static void fire_bullet(Bullet b[BULLET_COUNT], int x, int y) {
    int i;
    for (i=0;i<BULLET_COUNT;i++) if (!b[i].active) {
        b[i].x=x+12; b[i].y=y-8; b[i].speed=9; b[i].active=1; return;
    }
}
static void render(packet_t *packet, int px, int py, Enemy e[ENEMY_COUNT],
                   Bullet b[BULLET_COUNT], Star s[STAR_COUNT],
                   int lives, int score, int over) {
    int i, progress=score*4;
    qword_t *q;
    if (progress>250) progress=250;
    dma_wait_fast();
    q=draw_clear(packet->data, 0,0,0,SCREEN_W,SCREEN_H, 5,12,29);
    /* layered atmosphere and animated stars */
    q=draw_rect(q,0,0,SCREEN_W,70, 8,20,43);
    q=draw_rect(q,0,440,SCREEN_W,72, 7,17,36);
    for(i=0;i<STAR_COUNT;i++) {
        int size=(i%5==0)?3:2;
        q=draw_rect(q,s[i].x,s[i].y,size,size, 115,160,205);
    }
    /* compact arcade HUD */
    q=draw_rect(q,16,15,260,9, 32,52,78);
    q=draw_rect(q,16,15,progress,9, 30,220,170);
    q=draw_rect(q,16,31,88,3, 70,105,145);
    for(i=0;i<lives;i++) {
        q=draw_triangle(q, 424+i*24,34, 430+i*24,19, 436+i*24,34, 255,85,95);
    }
    for(i=0;i<ENEMY_COUNT;i++) q=draw_fighter(q,e[i].x,e[i].y,1);
    for(i=0;i<BULLET_COUNT;i++) if(b[i].active) {
        q=draw_rect(q,b[i].x+4,b[i].y,3,13, 255,235,120);
        q=draw_rect(q,b[i].x+2,b[i].y+4,7,7, 255,145,45);
    }
    /* player exhaust glow and fighter */
    q=draw_rect(q,px+9,py+34,5,12, 255,105,35);
    q=draw_rect(q,px+16,py+34,5,12, 255,105,35);
    q=draw_fighter(q,px,py,0);
    if(over) {
        q=draw_rect(q,72,205,368,105, 10,20,42);
        q=draw_rect(q,92,225,328,4, 235,65,75);
        q=draw_rect(q,145,250,222,12, 245,185,65);
        q=draw_rect(q,180,278,152,5, 60,220,170);
    }
    q=draw_finish(q);
    dma_channel_send_normal(DMA_CHANNEL_GIF,packet->data,q-packet->data,0,0);
    draw_wait_finish();
    graph_wait_vsync();
}
int main(void) {
    framebuffer_t frame; zbuffer_t z; packet_t *packet;
    Enemy enemies[ENEMY_COUNT]; Bullet bullets[BULLET_COUNT]; Star stars[STAR_COUNT];
    int px,py,lives,score,over,frame_no=0,i;
    dma_channel_initialize(DMA_CHANNEL_GIF,NULL,0);
    dma_channel_fast_waits(DMA_CHANNEL_GIF);
    frame.width=SCREEN_W; frame.height=SCREEN_H; frame.mask=0; frame.psm=GS_PSM_32;
    frame.address=graph_vram_allocate(frame.width,frame.height,frame.psm,GRAPH_ALIGN_PAGE);
    z.enable=0; z.address=0; z.mask=0; z.zsm=0;
    graph_initialize(frame.address,frame.width,frame.height,frame.psm,0,0);
    packet=packet_init(1024,PACKET_NORMAL);
    if(packet==NULL) { graph_shutdown(); dma_channel_shutdown(DMA_CHANNEL_GIF,0); SleepThread(); return 1; }
    {
        qword_t *q=draw_setup_environment(packet->data,0,&frame,&z);
        q=draw_finish(q);
        dma_channel_send_normal(DMA_CHANNEL_GIF,packet->data,q-packet->data,0,0);
        draw_wait_finish();
    }
    init_pad();
    init_game(&px,&py,&lives,&score,&over,enemies,bullets,stars);
    for(;;) {
        u32 buttons=read_pad();
        if(over) {
            if(buttons & PAD_START) init_game(&px,&py,&lives,&score,&over,enemies,bullets,stars);
        } else {
            if(buttons & PAD_LEFT) px-=5;
            if(buttons & PAD_RIGHT) px+=5;
            if(buttons & PAD_UP) py-=5;
            if(buttons & PAD_DOWN) py+=5;
            /* Also support the left virtual/physical analog stick. */
            if(stick_x < -24) px-=5;
            if(stick_x > 24) px+=5;
            if(stick_y < -24) py-=5;
            if(stick_y > 24) py+=5;
            px=clamp_int(px,8,SCREEN_W-PLAYER_W-8);
            py=clamp_int(py,48,SCREEN_H-PLAYER_H-8);
            /* Common Android/emulator mappings: any main face button or R1 fires. */
            if((buttons & (PAD_TRIANGLE|PAD_CROSS|PAD_SQUARE|PAD_CIRCLE|PAD_R1|PAD_R2)) && frame_no%7==0)
                fire_bullet(bullets,px,py);
            for(i=0;i<BULLET_COUNT;i++) if(bullets[i].active) {
                bullets[i].y-=bullets[i].speed;
                if(bullets[i].y < -16) bullets[i].active=0;
                else {
                    int j;
                    for(j=0;j<ENEMY_COUNT;j++) if(enemies[j].y>=-45 &&
                        overlaps(bullets[i].x,bullets[i].y,7,13,
                                 enemies[j].x,enemies[j].y,28,42)) {
                        bullets[i].active=0; enemies[j].hp=0; ++score;
                        enemies[j].y=-100; enemies[j].x=random_x(); enemies[j].hp=1;
                        break;
                    }
                }
            }
            for(i=0;i<ENEMY_COUNT;i++) {
                enemies[i].y+=enemies[i].speed+score/18;
                if(enemies[i].y>SCREEN_H) {
                    enemies[i].y=-50; enemies[i].x=random_x(); ++score;
                }
                if(overlaps(px+4,py+4,20,32,enemies[i].x+4,enemies[i].y+4,20,32)) {
                    --lives; enemies[i].y=-70; enemies[i].x=random_x();
                    if(lives<=0) over=1;
                }
            }
            for(i=0;i<STAR_COUNT;i++) {
                stars[i].y+=stars[i].speed;
                if(stars[i].y>=SCREEN_H) { stars[i].y=0; stars[i].x=random_x(); }
            }
        }
        ++frame_no;
        render(packet,px,py,enemies,bullets,stars,lives,score,over);
    }
    return 0;
}
