/*
 * Nova Dodge - original PS2 homebrew mini-game.
 * Controls: D-pad moves the green ship; avoid red blocks.
 * START restarts after game over.
 * Built against the open-source PS2SDK.
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
#define PLAYER_W 24
#define PLAYER_H 24
#define ENEMY_COUNT 4

typedef struct {
    int x, y, w, h, speed;
} Enemy;

static char pad_dma_buffer[256] __attribute__((aligned(64)));
static int pad_ready = 0;
static u32 rng_state = 0x4E4F5641;

static int clamp_int(int value, int low, int high)
{
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

static int random_x(void)
{
    rng_state = rng_state * 1664525u + 1013904223u;
    return 18 + (int)(rng_state % 440u);
}

static void init_pad(void)
{
    int i;
    int ret;

    sceSifInitRpc(0);
    ret = SifLoadModule("rom0:SIO2MAN", 0, NULL);
    if (ret < 0) return;
    ret = SifLoadModule("rom0:PADMAN", 0, NULL);
    if (ret < 0) return;

    padInit(0);
    if (padPortOpen(0, 0, pad_dma_buffer) == 0) return;

    for (i = 0; i < 240; ++i) {
        int state = padGetState(0, 0);
        if (state == PAD_STATE_STABLE || state == PAD_STATE_FINDCTP1) {
            pad_ready = 1;
            return;
        }
        graph_wait_vsync();
    }
}

static u32 read_pad(void)
{
    struct padButtonStatus buttons;
    int state;

    if (!pad_ready) return 0;
    state = padGetState(0, 0);
    if (state != PAD_STATE_STABLE && state != PAD_STATE_FINDCTP1) return 0;
    if (padRead(0, 0, &buttons) == 0) return 0;
    return (u32)(0xffffu ^ buttons.btns);
}

static int overlaps(int ax, int ay, int aw, int ah,
                    int bx, int by, int bw, int bh)
{
    return ax < bx + bw && ax + aw > bx &&
           ay < by + bh && ay + ah > by;
}

static void reset_game(int *player_x, int *player_y,
                       Enemy enemies[ENEMY_COUNT],
                       int *lives, int *score, int *game_over)
{
    int i;
    *player_x = (SCREEN_W - PLAYER_W) / 2;
    *player_y = SCREEN_H - 58;
    *lives = 3;
    *score = 0;
    *game_over = 0;

    for (i = 0; i < ENEMY_COUNT; ++i) {
        enemies[i].w = 24 + (i % 3) * 8;
        enemies[i].h = 22 + (i % 2) * 10;
        enemies[i].x = 28 + i * 112;
        enemies[i].y = -70 - i * 118;
        enemies[i].speed = 3 + i / 2;
    }
}

static qword_t *draw_rect(qword_t *q, int x, int y, int w, int h,
                          int red, int green, int blue)
{
    int x1 = ((x + w) << 4) + (2048 << 4);
    int y1 = ((y + h) << 4) + (2048 << 4);
    int x0 = (x << 4) + (2048 << 4);
    int y0 = (y << 4) + (2048 << 4);

    PACK_GIFTAG(q, GIF_SET_TAG(4, 1, 0, 0, 0, 1), GIF_REG_AD); q++;
    PACK_GIFTAG(q, GIF_SET_PRIM(6, 0, 0, 0, 0, 0, 0, 0, 0), GIF_REG_PRIM); q++;
    PACK_GIFTAG(q, GIF_SET_RGBAQ(red, green, blue, 0x80, 0x3f800000), GIF_REG_RGBAQ); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ(x0, y0, 0), GIF_REG_XYZ2); q++;
    PACK_GIFTAG(q, GIF_SET_XYZ(x1, y1, 0), GIF_REG_XYZ2); q++;
    return q;
}

static void init_graphics(framebuffer_t *frame, zbuffer_t *z)
{
    frame->width = SCREEN_W;
    frame->height = SCREEN_H;
    frame->mask = 0;
    frame->psm = GS_PSM_32;
    frame->address = graph_vram_allocate(frame->width, frame->height,
                                         frame->psm, GRAPH_ALIGN_PAGE);

    z->enable = 0;
    z->address = 0;
    z->mask = 0;
    z->zsm = 0;

    graph_initialize(frame->address, frame->width, frame->height,
                     frame->psm, 0, 0);
}

static void init_draw_environment(packet_t *packet,
                                  framebuffer_t *frame, zbuffer_t *z)
{
    qword_t *q = draw_setup_environment(packet->data, 0, frame, z);
    q = draw_finish(q);
    dma_channel_send_normal(DMA_CHANNEL_GIF, packet->data,
                            q - packet->data, 0, 0);
    draw_wait_finish();
}

static void render(packet_t *packet, framebuffer_t *frame,
                   int player_x, int player_y,
                   Enemy enemies[ENEMY_COUNT], int lives, int score,
                   int game_over)
{
    int i;
    int progress = score * 3;
    qword_t *q;

    if (progress > 250) progress = 250;
    dma_wait_fast();
    q = draw_clear(packet->data, 0, 0, 0, SCREEN_W, SCREEN_H, 7, 13, 25);

    /* Score/progress bar and remaining lives. */
    q = draw_rect(q, 18, 18, 260, 8, 30, 45, 65);
    q = draw_rect(q, 18, 18, progress, 8, 40, 210, 150);
    for (i = 0; i < lives; ++i)
        q = draw_rect(q, 440 + i * 18, 16, 12, 12, 255, 190, 45);

    for (i = 0; i < ENEMY_COUNT; ++i)
        q = draw_rect(q, enemies[i].x, enemies[i].y,
                      enemies[i].w, enemies[i].h, 235, 65, 75);

    q = draw_rect(q, player_x, player_y, PLAYER_W, PLAYER_H, 55, 220, 145);
    q = draw_rect(q, player_x + 8, player_y - 7, 8, 7, 100, 245, 205);

    if (game_over) {
        q = draw_rect(q, 178, 220, 156, 18, 245, 55, 65);
        q = draw_rect(q, 205, 248, 102, 10, 245, 180, 50);
    }

    q = draw_finish(q);
    dma_channel_send_normal(DMA_CHANNEL_GIF, packet->data,
                            q - packet->data, 0, 0);
    draw_wait_finish();
    graph_wait_vsync();
}

int main(void)
{
    framebuffer_t frame;
    zbuffer_t z;
    packet_t *packet;
    Enemy enemies[ENEMY_COUNT];
    int player_x, player_y, lives, score, game_over;
    int i;

    dma_channel_initialize(DMA_CHANNEL_GIF, NULL, 0);
    dma_channel_fast_waits(DMA_CHANNEL_GIF);

    init_graphics(&frame, &z);
    packet = packet_init(128, PACKET_NORMAL);
    if (packet == NULL) {
        graph_shutdown();
        dma_channel_shutdown(DMA_CHANNEL_GIF, 0);
        SleepThread();
        return 1;
    }

    init_draw_environment(packet, &frame, &z);
    init_pad();
    reset_game(&player_x, &player_y, enemies, &lives, &score, &game_over);

    for (;;) {
        u32 buttons = read_pad();

        if (game_over) {
            if (buttons & PAD_START)
                reset_game(&player_x, &player_y, enemies,
                           &lives, &score, &game_over);
        } else {
            if (buttons & PAD_LEFT)  player_x -= 5;
            if (buttons & PAD_RIGHT) player_x += 5;
            if (buttons & PAD_UP)    player_y -= 5;
            if (buttons & PAD_DOWN)  player_y += 5;

            player_x = clamp_int(player_x, 8, SCREEN_W - PLAYER_W - 8);
            player_y = clamp_int(player_y, 38, SCREEN_H - PLAYER_H - 8);

            for (i = 0; i < ENEMY_COUNT; ++i) {
                enemies[i].y += enemies[i].speed + score / 12;

                if (enemies[i].y > SCREEN_H) {
                    enemies[i].y = -enemies[i].h;
                    enemies[i].x = random_x();
                    ++score;
                }

                if (overlaps(player_x, player_y, PLAYER_W, PLAYER_H,
                             enemies[i].x, enemies[i].y,
                             enemies[i].w, enemies[i].h)) {
                    --lives;
                    enemies[i].y = -enemies[i].h - 30;
                    enemies[i].x = random_x();
                    if (lives <= 0) game_over = 1;
                }
            }
        }

        render(packet, &frame, player_x, player_y, enemies,
               lives, score, game_over);
    }

    return 0;
}
