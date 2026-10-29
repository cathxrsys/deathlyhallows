// ---------- Lighting & time of day ----------
#define NIGHT_BRIGHTNESS 0.5 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define DAY_GLOOM 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define CAVE_LIGHT 0.7 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define TWILIGHT_STRENGTH 0.6 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define TWILIGHT_LENGTH 4.0 // [0.5 1.0 1.5 2.0 2.5 3.0 4.0]

// ---------- Sky & clouds ----------
#define CLOUDS
#define CLOUD_DARKNESS 0.3 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.6 0.7]
#define CLOUD_VARIATION 0.25 // [0.0 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6]
#define CLOUD_HORIZON 12 // [0 5 8 10 12 15 20 25 30]
#define SKY_COOL 0.0 // [0.0 0.25 0.5 0.75 1.0]

// ---------- Dynamic light ----------
#define TORCH_FLICKER
#define FLICKER_STRENGTH 0.1 // [0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5]
#define FLICKER_SPEED 0.75 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#define HELD_LIGHT
#define BLOCK_LIGHT_STRENGTH 1.3 // [0.5 0.75 1.0 1.15 1.3 1.5 1.75 2.0 2.5 3.0]
#define HELD_LIGHT_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#define HELD_LIGHT_RADIUS 0.8 // [0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2]
#define PORTAL_LIGHT
#define PORTAL_LIGHT_STRENGTH 2.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#define PORTAL_LIGHT_RADIUS 10 // [4 6 8 10 12 16]
#define PORTAL_FRAME_TINT
//#define ORE_LIGHT
#define ORE_LIGHT_STRENGTH 0.25 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#define ORE_LIGHT_RADIUS 4 // [3 4 5 6 7 8 10]
#define ORE_LIGHT_DIST 12 // [1 2 3 4 5 6 8 10 12]

// ---------- Glowing blocks & mobs ----------
#define ORE_GLOW 2.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define ORE_DAY_GLOW 0.25 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define ORE_FADE_DIST 96 // [8 16 24 32 48 64 96 128]
#define ORE_FAR_GLOW 0.1 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.75 1.0]
#define REDSTONE_GLOW 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define PORTAL_GLOW 2.5 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define MOB_EYES
#define MOB_EYES_GLOW 1.0 // [0.1 0.2 0.3 0.4 0.5 0.75 1.0 1.5 2.0]
#define MOB_EYES_FADE_DIST 24 // [8 16 24 32 48 64 96 128]
#define MOB_EYES_FAR_GLOW 0.3 // [0.0 0.1 0.2 0.3 0.4 0.5 0.75 1.0]

// ---------- Weather & snow ----------
#define RAIN_FOG 2.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 4.0]
#define RAIN_SKY_DARKNESS 0.25 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.5]
#define RAIN_OPACITY 0.4 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.5 2.0 3.0]
#define RAIN_THINNESS 0.8 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8]
#define RAIN_BRIGHTNESS 0.5 // [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define FOG_GLOW
#define FOG_GLOW_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define LIGHTNING_BOLT
#define LIGHTNING_STRENGTH 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
//#define SNOWIFY
#define SNOW_AMOUNT 1.0 // [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SNOW_BRIGHTNESS 1.0 // [0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

// ---------- Water & ice ----------
#define WATER_OPACITY 0.55 // [0.3 0.4 0.5 0.55 0.6 0.7 0.8 0.9 1.0]
#define WATER_BRIGHTNESS 1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define WATER_PATTERN 0.6 // [0.0 0.2 0.4 0.6 0.8 1.0]
#define UNDERWATER_DENSITY 0.22 // [0.04 0.08 0.1 0.15 0.2 0.22 0.25 0.3 0.4 0.5]
#define ICE_OPACITY 0.3 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// ---------- Foliage ----------
#define SWAY
#define SWAY_STRENGTH 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define SWAY_SPEED 1.4 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0]
#define STORM_SWAY 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// ---------- Nether & End ----------
#define NETHER_BRIGHTNESS 0.6 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.25 1.5 2.0 2.5 3.0]
#define NETHER_HAZE
#define NETHER_HAZE_STRENGTH 0.75 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define NETHER_HAZE_DIST 8 // [8 16 24 32 48 64 96]
#define NETHER_HAZE_SPEED_MIN 0.5 // [0.5 0.75 1.0 1.5 2.0 2.5 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define NETHER_HAZE_SPEED_MAX 2.5 // [0.5 0.75 1.0 1.5 2.0 2.5 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define END_BRIGHTNESS 0.2 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.25 1.5 2.0 2.5 3.0]

// ---------- Color ----------
#define DESATURATION 0.2 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define NIGHT_DESATURATION 0.8 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define HIGHLIGHT_BOOST 0.9 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

// ---------- Camera effects ----------
//#define GLOW
#define GLOW_STRENGTH 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define CHROMA
#define CHROMA_STRENGTH 0.4 // [0.2 0.4 0.6 0.8 1.0 1.2 1.5 2.0 2.5 3.0]
#define CHROMA_OPACITY 0.8 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define FILM_GRAIN
#define GRAIN_OPACITY 0.15 // [0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GRAIN_CONTRAST 0.5 // [0.5 0.75 1.0 1.5 2.0 3.0 4.0]
#define GRAIN_SIZE 1.0 // [1.0 1.5 2.0 2.5 3.0 4.0]
#define GRAIN_COLOR 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]
#define GRAIN_DENSITY 1.0 // [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VIGNETTE

// ---------- Anti-aliasing & sharpness ----------
//#define FXAA
#define FXAA_STRENGTH 0.6 // [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
//#define SHARPEN
#define SHARPEN_STRENGTH 0.3 // [0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

// ---------- Status & interface ----------
#define LOW_HEALTH
#define LOW_HEALTH_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define LOW_AIR
#define LOW_AIR_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define INTRO_TITLE
#define INTRO_POSITION 3 // [0 1 2 3]
