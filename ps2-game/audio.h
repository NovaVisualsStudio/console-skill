#ifndef NOVA_AUDIO_H
#define NOVA_AUDIO_H

/* Procedural PS2 SPU2 sound layer. No external copyrighted samples required. */
enum nova_sfx {
    NOVA_SFX_FIRE = 0,
    NOVA_SFX_EXPLOSION,
    NOVA_SFX_HIT,
    NOVA_SFX_START,
    NOVA_SFX_GAMEOVER
};

int audio_init(int video_region);
void audio_set_engine(int throttle);
void audio_play_sfx(int effect);
void audio_tick(void);
int audio_is_ready(void);

#endif
