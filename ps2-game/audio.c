#include "audio.h"

#include <tamtypes.h>
#include <kernel.h>
#include <sifrpc.h>
#include <loadfile.h>
#include <iopheap.h>
#include <audsrv.h>

#define AUDIO_RATE 22050
#define AUDIO_NTSC_SAMPLES 368
#define AUDIO_PAL_SAMPLES 441
#define AUDIO_MAX_SAMPLES 441
#define AUDIO_VOICES 6
#define AUDIO_ENGINE_MAX 2600

extern unsigned char audsrv_irx[];
extern unsigned int size_audsrv_irx;

typedef struct {
    u32 phase;
    u32 step;
    u32 noise;
    int remaining;
    int duration;
    int volume;
    int kind;
} audio_voice_t;

static s16 mix_buffer[AUDIO_MAX_SAMPLES];
static audio_voice_t voices[AUDIO_VOICES];
static u32 engine_phase;
static u32 engine_harmonic_phase;
static u32 engine_noise = 0x6D2B79F5u;
static u32 music_phase;
static u32 music_step;
static int music_remaining;
static int music_index;
static const int music_notes[8] = {220, 262, 330, 294, 196, 220, 247, 165};
static u32 engine_step;
static int engine_throttle;
static int samples_per_frame = AUDIO_NTSC_SAMPLES;
static int audio_ready;

static int triangle(u32 phase)
{
    int p = (int)(phase >> 16);
    return p < 32768 ? (p * 2 - 32768) : (98303 - p * 2);
}

static u32 phase_step(int hz)
{
    return (u32)(((u64)(u32)hz << 32) / AUDIO_RATE);
}

static int clamp_sample(int value)
{
    if (value > 32767) return 32767;
    if (value < -32768) return -32768;
    return value;
}

int audio_init(int video_region)
{
    int ret, module_result = -1, i;
    struct audsrv_fmt_t format;

    audio_ready = 0;
    samples_per_frame = (video_region == 2) ? AUDIO_PAL_SAMPLES : AUDIO_NTSC_SAMPLES;

    sceSifInitRpc(0);
    ret = SifLoadModule("rom0:LIBSD", 0, NULL);
    if (ret < 0) return -1;

    ret = SifExecModuleBuffer(audsrv_irx, size_audsrv_irx, 0, NULL, &module_result);
    if (ret < 0 || module_result < 0) return -2;

    ret = audsrv_init();
    if (ret != AUDSRV_ERR_NOERROR) return -3;

    format.freq = AUDIO_RATE;
    format.bits = 16;
    format.channels = 1;
    ret = audsrv_set_format(&format);
    if (ret != AUDSRV_ERR_NOERROR) {
        audsrv_quit();
        return -4;
    }
    audsrv_set_volume(MAX_VOLUME);

    for (i = 0; i < AUDIO_VOICES; ++i) voices[i].remaining = 0;
    engine_phase = 0;
    engine_harmonic_phase = 0;
    music_phase = 0;
    music_index = 0;
    music_remaining = 0;
    music_step = phase_step(music_notes[0]);
    engine_step = phase_step(58);
    engine_throttle = 0;
    audio_ready = 1;
    audio_play_sfx(NOVA_SFX_START);
    return 0;
}

void audio_set_engine(int throttle)
{
    int frequency;
    if (throttle < 0) throttle = 0;
    if (throttle > 100) throttle = 100;
    engine_throttle = throttle;
    frequency = 54 + (throttle * 42) / 100;
    engine_step = phase_step(frequency);
}

void audio_play_sfx(int effect)
{
    int i, slot = -1;
    audio_voice_t *v;
    if (!audio_ready) return;

    for (i = 0; i < AUDIO_VOICES; ++i) {
        if (voices[i].remaining <= 0) { slot = i; break; }
    }
    if (slot < 0) {
        slot = 0;
        for (i = 1; i < AUDIO_VOICES; ++i)
            if (voices[i].remaining < voices[slot].remaining) slot = i;
    }

    v = &voices[slot];
    v->phase = 0;
    v->noise = 0xA341316Cu ^ (u32)(effect * 7919 + slot * 104729);
    v->kind = effect;
    if (effect == NOVA_SFX_FIRE) {
        v->duration = v->remaining = 2400;
        v->volume = 5200;
        v->step = phase_step(920);
    } else if (effect == NOVA_SFX_EXPLOSION) {
        v->duration = v->remaining = 7200;
        v->volume = 10500;
        v->step = phase_step(92);
    } else if (effect == NOVA_SFX_HIT) {
        v->duration = v->remaining = 4300;
        v->volume = 9000;
        v->step = phase_step(145);
    } else if (effect == NOVA_SFX_GAMEOVER) {
        v->duration = v->remaining = 11000;
        v->volume = 6500;
        v->step = phase_step(440);
    } else {
        v->duration = v->remaining = 3200;
        v->volume = 4200;
        v->step = phase_step(660);
    }
}

static int voice_sample(audio_voice_t *v)
{
    int env, wave, noise;
    if (v->remaining <= 0) return 0;
    env = (v->volume * v->remaining) / v->duration;
    v->phase += v->step;
    if (v->kind == NOVA_SFX_EXPLOSION || v->kind == NOVA_SFX_HIT) {
        v->noise = (v->noise >> 1) ^ (0xD0000001u & (0u - (v->noise & 1u)));
        noise = (int)(v->noise & 0xffffu) - 32768;
        wave = (noise * env) / 32768;
        wave += (triangle(v->phase) * env) / 65536;
    } else {
        wave = (triangle(v->phase) * env) / 32768;
        if (v->kind == NOVA_SFX_FIRE) v->step -= v->step / 170;
        if (v->kind == NOVA_SFX_GAMEOVER) {
            v->step = phase_step(300 + (v->remaining / 45));
        }
    }
    --v->remaining;
    return wave;
}

void audio_tick(void)
{
    int i, n;
    if (!audio_ready) return;

    for (n = 0; n < samples_per_frame; ++n) {
        int sample, engine, noise, music;
        if (music_remaining <= 0) {
            music_step = phase_step(music_notes[music_index]);
            music_index = (music_index + 1) & 7;
            music_remaining = AUDIO_RATE / 4;
        }
        music_phase += music_step;
        music = (triangle(music_phase) * 520) / 32768;
        music_remaining--;
        engine_phase += engine_step;
        engine_harmonic_phase += engine_step * 3u;
        engine_noise = (engine_noise >> 1) ^ (0xD0000001u & (0u - (engine_noise & 1u)));
        engine = (triangle(engine_phase) * (1800 + engine_throttle * 8)) / 32768;
        engine += (triangle(engine_harmonic_phase) * 360) / 32768;
        noise = ((int)(engine_noise & 0xffffu) - 32768) * (180 + engine_throttle * 2) / 32768;
        sample = engine + noise + music;

        for (i = 0; i < AUDIO_VOICES; ++i) sample += voice_sample(&voices[i]);
        mix_buffer[n] = (s16)clamp_sample(sample);
    }

    /* One region-matched audio block per vertical retrace keeps audio and video paced. */
    audsrv_wait_audio(samples_per_frame * (int)sizeof(s16));
    audsrv_play_audio((const char *)mix_buffer, samples_per_frame * (int)sizeof(s16));
}

int audio_is_ready(void)
{
    return audio_ready;
}
