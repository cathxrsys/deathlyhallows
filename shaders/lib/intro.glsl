// title text shown when the shader loads: a 3x5 font baked into bit masks
// frameTimeCounter is declared in sky.glsl

const int INTRO_LINE1[] = int[](68, 69, 65, 84, 72, 76, 89, 32, 72, 65, 76, 76, 79, 87, 83, 32, 86, 50, 46, 48, 46, 52); // DEATHLY HALLOWS V2.0.4
const int INTRO_LINE2[] = int[](66, 89, 32, 67, 65, 84, 72, 88, 82, 83, 89, 83); // BY CATHXRSYS

const int   INTRO_WIDTH      = 87; // cells in the first line
const int   INTRO_LINE_SHIFT = 40; // width difference between the lines
const float INTRO_START = 0.4;
const float INTRO_END   = 3.0;

// 15 bits: 5 rows of 3 bits, the top row in the high bits
int introGlyph(int c) {
    switch (c) {
        case 65: return 0x2bed; // A
        case 66: return 0x6bae; // B
        case 67: return 0x3923; // C
        case 68: return 0x6b6e; // D
        case 69: return 0x79a7; // E
        case 72: return 0x5bed; // H
        case 76: return 0x4927; // L
        case 79: return 0x2b6a; // O
        case 82: return 0x6bad; // R
        case 83: return 0x388e; // S
        case 84: return 0x7492; // T
        case 86: return 0x5b6a; // V
        case 87: return 0x5bfd; // W
        case 88: return 0x5aad; // X
        case 89: return 0x5a92; // Y
        case 48: return 0x7b6f; // 0
        case 49: return 0x2c97; // 1
        case 50: return 0x62a7; // 2
        case 51: return 0x628e; // 3
        case 52: return 0x5bc9; // 4
        case 53: return 0x798e; // 5
        case 54: return 0x39ef; // 6
        case 55: return 0x7252; // 7
        case 56: return 0x7bef; // 8
        case 57: return 0x7bce; // 9
        case 46: return 0x0002; // .
    }
    return 0;
}

// cp: coordinates in font cells from the top-left corner of the text
float introMask(ivec2 cp) {
    if (cp.y < 0) return 0.0;

    int line = cp.y / 7;
    int gy   = cp.y % 7;
    // the second line is shorter, push it to the right edge
    int x    = cp.x - (line == 1 ? INTRO_LINE_SHIFT : 0);
    if (x < 0) return 0.0;
    int idx  = x / 4;
    int gx   = x % 4;
    if (line > 1 || gy > 4 || gx > 2) return 0.0;

    int c;
    if (line == 0) {
        if (idx >= INTRO_LINE1.length()) return 0.0;
        c = INTRO_LINE1[idx];
    } else {
        if (idx >= INTRO_LINE2.length()) return 0.0;
        c = INTRO_LINE2[idx];
    }
    return float((introGlyph(c) >> ((4 - gy) * 3 + (2 - gx))) & 1);
}

vec3 introTitle(vec3 c, vec2 uv, vec2 res) {
    float t = frameTimeCounter;
    if (t > INTRO_END) return c;

    float a = smoothstep(INTRO_START, INTRO_START + 0.4, t) * (1.0 - smoothstep(INTRO_END - 0.7, INTRO_END, t));
    if (a <= 0.0) return c;

    float scale  = max(1.0, floor(res.y / 540.0));
    float w      = (float(INTRO_WIDTH) + 4.0) * scale;
    float h      = 12.0 * scale; // two lines: 5 + 2 + 5 cells
    float margin = 4.0 * scale;
    // 0 - top right, 1 - top left, 2 - bottom right, 3 - bottom left
    vec2  origin = vec2((INTRO_POSITION == 1 || INTRO_POSITION == 3) ? margin : res.x - w,
                        INTRO_POSITION >= 2 ? res.y - h - margin : margin);
    vec2  p      = vec2(uv.x * res.x, (1.0 - uv.y) * res.y) - origin;
    ivec2 cp     = ivec2(floor(p / scale));

    float m  = introMask(cp);
    float sh = introMask(cp - ivec2(1, 1));
    c = mix(c, vec3(0.0), sh * 0.7 * a);
    return mix(c, vec3(0.92, 0.94, 1.0), m * a);
}
