// Procedural lightning with branches, drawn on the sky. The vanilla lightning model is hidden
// in simple_frag.glsl (entityId 1000, see entity.properties).

uniform vec4 lightningBoltPosition; // xyz - position relative to the camera

// Main optimization: the channel and branches are single-valued functions of height (x of y), so a pixel
// only needs the segments near its height, not the whole path. The cost does not depend on the number
// of segments, so there can be as many as needed. Points are computed on the fly from hashes.
const int BOLT_SEGS = 220;
const int BOLT_BRANCHES = 18;
const int BRANCH_SEGS = 55;
const float BOLT_HEIGHT = 110.0; // blocks from the ground to the clouds

float segDist(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-9), 0.0, 1.0);
    return length(p - a - ab * t);
}

// smooth value noise in the range -0.5..0.5; g - position in lattice nodes
float vnoise(float g, float s) {
    float k = floor(g);
    return mix(hash11(s + k * 1.31), hash11(s + (k + 1.0) * 1.31), smoothstep(0.0, 1.0, fract(g))) - 0.5;
}

// Sideways offset at path fraction t (0..1) in units of H: 3 octaves + small jitter per segment.
// i - point index
float boltOffset(float t, int i, float s) {
    return vnoise(t * 7.0, s) * 0.11
         + vnoise(t * 20.0, s + 11.0) * 0.04
         + vnoise(t * 45.0, s + 23.0) * 0.012
         + (hash11(s * 5.1 + float(i) * 2.17) - 0.5) * 0.003;
}

// point i of the main channel in local coordinates (rad): x - sideways, y - up
vec2 boltMainPt(int i, float seed, float H, float lean) {
    float t = float(i) / float(BOLT_SEGS);
    // near the ground (t -> 0) the channel straightens, bends grow towards the clouds
    float x = boltOffset(t, i, seed * 3.7) * smoothstep(0.0, 0.4, t) * H + lean * H * t;
    return vec2(x, H * t);
}

// Bolt parameters shared by all pixels: computed in the sky vertex shader.
// A = (azimuth, base elevation, angular channel height H, width w)
// B = (cos tilt, sin tilt, lean, branch count)
void getBoltParams(out vec4 A, out vec4 B) {
    vec3 b = lightningBoltPosition.xyz;
    float horiz = max(length(b.xz), 4.0);
    float az0 = atan(b.x, b.z);
    float el0 = atan(b.y, horiz);
    float H = atan(b.y + BOLT_HEIGHT, horiz) - el0;
    float w = max(0.10 / horiz, 0.0005);

    // channel tilt: unique per bolt, usually moderate, sometimes strongly sideways (up to ~65 degrees)
    float seed = floor(frameTimeCounter / 4.0) * 7.31;
    float tr = hash11(seed + 5.0) * 2.0 - 1.0;
    float tilt = sign(tr) * pow(abs(tr), 1.4) * 1.15;

    float lean = (hash11(seed + 9.0) - 0.5) * 0.10;

    // branch count is unique per bolt: usually 2-5, sometimes up to 18
    int nb = 2 + int(pow(hash11(seed + 6.0), 2.2) * float(BOLT_BRANCHES - 1));

    A = vec4(az0, el0, H, w);
    B = vec4(cos(tilt), sin(tilt), lean, float(nb));
}

// x - core brightness, y - glow brightness; A, B from getBoltParams
vec2 getBolt(vec3 dir, vec4 A, vec4 B) {
    float az0 = A.x;
    float el0 = A.y;
    float H = A.z;
    float w = A.w;

    float el = asin(clamp(dir.y, -1.0, 1.0));
    float da = atan(dir.x, dir.z) - az0;
    da = da - 6.28318 * floor((da + 3.14159) / 6.28318);
    vec2 p = vec2(da * cos(el), el - el0); // pixel cos(el), otherwise the channel stretches sideways at height

    float seed = floor(frameTimeCounter / 4.0) * 7.31;
    p = vec2(p.x * B.x - p.y * B.y, p.x * B.y + p.y * B.x);

    // coarse bounding-box rejection
    if (p.y < -w * 20.0 || p.y > H + w * 20.0 || abs(p.x) > H * 0.45 + w * 20.0) return vec2(0.0);

    float lean = B.z;

    float dMain = 1e9;
    float dBranch = 1e9;

    // main channel: only the segments near the pixel height
    int i0 = int(clamp(p.y / H, 0.0, 1.0) * float(BOLT_SEGS));
    int iA = max(i0 - 2, 0);
    int iB = min(i0 + 3, BOLT_SEGS);
    vec2 prev = boltMainPt(iA, seed, H, lean);
    for (int i = iA + 1; i <= iB; i++) {
        vec2 cur = boltMainPt(i, seed, H, lean);
        dMain = min(dMain, segDist(p, prev, cur));
        prev = cur;
    }

    // branches go down and sideways from the upper part of the channel
    // the branch count comes from getBoltParams
    int nb = int(B.w + 0.5);
    for (int k = 0; k < BOLT_BRANCHES; k++) {
        if (k >= nb) break;
        float fk = float(k);
        float r0 = hash11(seed + 20.0 + fk * 2.3);
        float r1 = hash11(seed + 40.0 + fk * 3.1);
        float r2 = hash11(seed + 60.0 + fk * 1.7);
        int start = int(float(BOLT_SEGS) * (0.45 + 0.45 * r0));
        float ay = H * float(start) / float(BOLT_SEGS);
        float ly = H * (0.14 + 0.16 * r1);
        float margin = w * 20.0;
        if (p.y > ay + margin || p.y < ay - ly - margin) continue; // pixel is outside the branch height

        float side = r1 < 0.5 ? -1.0 : 1.0;
        float lx = H * (0.04 + 0.08 * r2);
        vec2 a = boltMainPt(start, seed, H, lean);
        float bs = seed + fk * 17.0;

        int m0 = int(clamp((a.y - p.y) / ly, 0.0, 1.0) * float(BRANCH_SEGS));
        int mA = max(m0 - 2, 0);
        int mB = min(m0 + 3, BRANCH_SEGS);
        vec2 q = vec2(0.0);
        for (int m = mA; m <= mB; m++) {
            float u = float(m) / float(BRANCH_SEGS);
            float wig = vnoise(u * 6.0, bs) * 0.05 + vnoise(u * 18.0, bs + 7.0) * 0.015
                      + (hash11(bs + float(m) * 5.3) - 0.5) * 0.003;
            vec2 n = a + vec2(side * lx * u + wig * H * min(u * 6.0, 1.0), -ly * u);
            if (m > mA) dBranch = min(dBranch, segDist(p, q, n));
            q = n;
        }
    }

    float core = exp(-(dMain / w) * (dMain / w)) + 0.5 * exp(-(dBranch / (w * 0.7)) * (dBranch / (w * 0.7)));
    float glow = w * 10.0 / (dMain + w * 10.0) * 0.25 + w * 8.0 / (dBranch + w * 8.0) * 0.10;
    glow *= glow * 2.0;
    return vec2(core, glow);
}
