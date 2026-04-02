#version 420

// original https://www.shadertoy.com/view/flXSDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Constants
#define TAU 6.28318530718
#define PI 3.14159265359
#define RHO 1.57079632679

// Utilities
#define fillDraw(dist, col) color = mix(color, col, smoothstep(unit, 0.0, dist))
#define glowDraw(dist, col, glow) color += col / exp((glow) * (dist))
#define remap01(x, a, b) ((x) - (a)) / ((b) - (a))

// SDFs
float sdDisk(in vec2 p, in float r) {
    return length(p) - r;
}

float sdLine(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

float sdBox(in vec2 p, in vec2 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(0.0, max(p.x, p.y));
}

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdStar5(in vec2 p, in float r, in float rf) {
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x,k1.y);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

// Simple trajectory with an initial position, linear velocity and gravity
vec2 posInTrajectory(in vec2 p0, in vec2 v0, in float g, in float t) {
    vec2 p = p0 + v0 * t;
    p.y -= 0.5 * g * t * t;
    return p;
}

vec2 velInTrajectory(in vec2 p0, in vec2 v0, in float g, in float t) {
    v0.y -= g * t;
    return v0;
}

// I would try optimizing with a bbox check but unfortunately
// the glow just doesn't work well with that :(
vec2 sdTrajectory(in vec2 p, in vec2 p0, in vec2 v0, in float g, in float tStart, in float tEnd) {
    vec2 q = p0 - p;
    float t3 = 0.5 * g * g;
    float t2 = -1.5 * g * v0.y;
    float t1 = dot(v0, v0) - q.y * g;
    float t0 = dot(q, v0);

    t2 /= t3, t1 /= t3, t0 /= t3;
    float t22 = t2 * t2;
    vec2 pq = vec2(t1 - t22 / 3.0, t22 * t2 / 13.5 - t2 * t1 / 3.0 + t0);
    float ppp = pq.x * pq.x * pq.x, qq = pq.y * pq.y;

    float p2 = abs(pq.x);
    float r1 = 1.5 / pq.x * pq.y;

    if (qq * 0.25 + ppp / 27.0 > 0.0) {
        float r2 = r1 * sqrt(3.0 / p2), root;
        if (pq.x < 0.0) root = sign(pq.y) * cosh(acosh(r2 * -sign(pq.y)) / 3.0);
        else root = sinh(asinh(r2) / 3.0);
        root = -2.0 * sqrt(p2 / 3.0) * root - t2 / 3.0;
        return vec2(length(p - posInTrajectory(p0, v0, g, clamp(root, tStart, tEnd))), root);
    }

    else {
        float ac = acos(r1 * sqrt(-3.0 / pq.x)) / 3.0;
        vec2 roots = 2.0 * sqrt(-pq.x / 3.0) * cos(vec2(ac, ac - 4.18879020479)) - t2 / 3.0;
        vec2 p1 = p - posInTrajectory(p0, v0, g, clamp(roots.x, tStart, tEnd));
        vec2 p2 = p - posInTrajectory(p0, v0, g, clamp(roots.y, tStart, tEnd));
        float d1 = dot(p1, p1), d2 = dot(p2, p2);
        return  d1 < d2 ? vec2(sqrt(d1), roots.x) : vec2(sqrt(d2), roots.y);
    }
}

// Modified hash from https://www.shadertoy.com/view/4djSRW
float gSeed = 167.23;
float random() {
    float x = fract(gSeed++ * 0.1031);
    x *= x + 33.33;
    x *= x + x;
    return fract(x);
}

void doFirework(inout vec3 color, in vec2 uv, in float time, in float seed) {
    float timeFrame = floor(time / 3.0) * 3.0;
    float fireTime = time - timeFrame;

    // Generate random traits
    gSeed = timeFrame + seed;
    float angle = mix(0.4, 0.6, random()) * PI;
    float speed = mix(2.0, 2.5, random());
    vec3 sparkColor = normalize(vec3(random(), random(), random())) * 1.25;

    // Compute start position, velocity, and gravity
    vec2 p0 = vec2(0.0, 0.6);
    vec2 v0 = vec2(cos(angle), sin(angle)) * speed;
    float g = 1.0;

    // Tracking
    float tApogee = v0.y / g;
    float t = tApogee * fireTime;
    vec2 pos = posInTrajectory(p0, v0, g, t);

    // Projectile and trail
    vec3 fadeColor = sparkColor * (1.0 - fireTime / 3.0);
    vec2 arc = sdTrajectory(uv, p0, v0, g, max(0.0, t - 2.0), t);
    glowDraw(arc.x - 0.01, fadeColor * clamp(remap01(arc.y, t - 2.0, t), 0.0, 1.0), 15.0);
    glowDraw(sdDisk(uv - pos, 0.02), fadeColor, 25.0);

    // Cast a circle of sparks from the apogee (highest point in the trajectory)
    if (t > tApogee) {
        fireTime -= 1.0;
        vec2 vApogee = velInTrajectory(p0, v0, g, tApogee);
        p0 = posInTrajectory(p0, v0, g, tApogee);
        for (float an=0.0; an < TAU; an += TAU / 25.0) {
            // Tracking
            v0 = vec2(cos(an), sin(an)) * (0.5 + random()) + vApogee;
            t = tApogee * fireTime;
            pos = posInTrajectory(p0, v0, g, t);

            // Projectile with trail
            vec3 fadeColor = sparkColor * (1.0 - 0.5 * fireTime);
            vec2 arc = sdTrajectory(uv, p0, v0, g, 0.0, t);
            glowDraw(arc.x - 0.01, fadeColor * clamp(remap01(arc.y, t - 1.0, t), 0.0, 1.0), 15.0);
            glowDraw(sdDisk(uv - pos, 0.02), fadeColor, 25.0);
        }
    }
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - vec2(0.5 * resolution.x, 0.0)) / resolution.y * 4.0;
    vec3 color = mix(vec3(1.0, 0.8, 0.0), vec3(0.5, 0.0, 0.0), 0.25 * (length(uv) - 0.25));
    float unit = 8.0 / resolution.y;

    // Flagpole
    fillDraw(sdBox(vec2(uv.x, uv.y - 1.75), vec2(0.035, 1.75)), vec3(0.0));

    // Flag
    vec2 flagUv = uv - vec2(0.845, 2.85);

    // Wave and shear to make it look like its more in perspective
    float x = uv.x - 0.035;
    flagUv.x = 1.1 * flagUv.x + 0.08;
    flagUv.y += 0.1 * x * sin(3.0 * (flagUv.x - time)) + 0.3 * x;

    // Shadows to highlight the ripples
    float shadow = 0.4 * sin(3.0 * (flagUv.x - time));
    shadow *= shadow;

    fillDraw(sdBox(flagUv, vec2(0.8, 0.64)), vec3(1.0) - shadow);

    // Red and white stripes (one for each of the original 13 colonies)
    vec2 stripesUv = flagUv;
    stripesUv.y -= clamp(round(stripesUv.y * 5.0) * 0.2, -0.6, 0.6);
    fillDraw(sdBox(stripesUv, vec2(0.8, 0.6 / 13.0)), vec3(0.78, 0.06, 0.18) - shadow);

    // Blue background and stars (one star for each of the 50 current states)
    // The stars are in staggered rows, 6 stars, 5 stars, repeat for 9 rows total
    vec2 starsUv = flagUv - vec2(-0.38, 0.3);
    fillDraw(sdBox(starsUv, vec2(0.425, 0.35)), vec3(0.0, 0.13, 0.41) - shadow);

    vec2 repSize = vec2(0.85, 0.7) / vec2(6.0, 9.0);
    float cy = floor(starsUv.y / repSize.y + 0.5) * repSize.y; // Cell y coordinate

    float stagger = mod(floor(cy / repSize.y), 2.0) * 0.5;
    float bx = 0.375 - stagger * repSize.x; // Repetition x bound (varied to create staggered rows)
    float cx = (floor(starsUv.x / repSize.x + stagger) + abs(stagger - 0.5)) * repSize.x; // Cell x coordinate

    starsUv -= clamp(vec2(cx, cy), -vec2(bx, 0.3), vec2(bx, 0.3));
    fillDraw(sdStar5(starsUv, 0.02, 0.4), vec3(1.0) - shadow);

    // Fireworks
    vec2 fireUv = uv;
    fireUv.x = abs(fireUv.x) - 2.0;

    // Spouts
    fillDraw(sdBox(vec2(fireUv.x, fireUv.y - 0.04), vec2(0.15, 0.04)), vec3(0.0));
    fillDraw(sdBox(vec2(fireUv.x, fireUv.y - 0.3), vec2(0.06, 0.3)), vec3(0.0));

    // Sparks
    doFirework(color, vec2(uv.x - 2.0, uv.y), time, 394.438);
    doFirework(color, vec2(uv.x + 2.0, uv.y), time + 1.0, 593.458);

    glFragColor = vec4(color, 1.0);
}
