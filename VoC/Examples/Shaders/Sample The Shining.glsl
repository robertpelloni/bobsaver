#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3stBDf

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The Shining
//
// Attempting to combine a couple of different scenes from 'The Shining'
// movie (or Ready Player One, if you prefer...)
// Main goals were to keep the frame rate up (even when anti-aliased),
// and the code small (but readable!).
// Oh - And to have fun, obv.  :)
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!

#define MIN_DIST         .0015
#define MAX_STEPS        120.

float g, time2,
      opn; // Door OPenness

#define AA  // Comment-out to improve frame rate.

struct Hit {
    float d;
    int id;
};
    
#define ax(p) vec3(abs(p.x), p.yz)

// Thanks Shane - https://www.shadertoy.com/view/lstGRB
float n31(vec3 p) {
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);
    
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float n21(vec2 p) { return n31(vec3(p, 0)); }

float h21(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float n11(float n) {
    float flr = floor(n);
    n = fract(n);
    vec2 r = fract(sin(vec2(flr, flr + 1.) * 12.3456) * 43758.5453);
    return mix(r.x, r.y, n * n * (3. - 2. * n));
}

float smin(float a, float b, float k) {
    float h = clamp(.5 + .5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

Hit minH(Hit a, Hit b) {
    if (a.d < b.d) return a;
    return b;
}

float max2(vec2 v) { return max(v.x, v.y); }

float remap(float f, float in1, float in2, float out1, float out2) {
    return mix(out1, out2, clamp((f - in1) / (in2 - in1), 0., 1.));
}

float sdHex(vec2 p, float r)
{
    p = abs(p);
    return -step(max(dot(p, normalize(vec2(1, 1.73))), p.x), r);
}

float sdSph(vec3 p, float r) { return length(p) - r; }

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max2(q.yz)), 0.);
}

float sdCyl(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max2(d), 0.) + length(max(d, 0.));
}

float sdCoving(vec3 p) {
    p.y -= .02;
    return max(sdBox(p, vec3(.04, .04, 15.)), .07 - length(p.xy + .042));
}

float sdBin(vec3 p) {
    p -= vec3(.82, -.8, 5.2);
    return max(abs(sdCyl(p, .06, .25)) - .002, .05 - length(p.xy + vec2(.07, -.15)));
}

vec3 getRayDir(vec3 ro, vec2 uv) {
    vec3 f = normalize(vec3(0., -.25, 66.) - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

void splat(vec2 p, out float i, out float o) {
    i = max(0., -sign(sdHex(p, 1.)));
    o = max(0., sign(sdHex(p, 2.)) - sign(sdHex(p, 3.)));
}

// Carpet texture.
vec3 carpet(vec2 p) {
    p.x = mod(p.x, 7.) - 3.5;
    p.y = mod(p.y, 10.) - 10.0;
    
    float i, o, i2, o2,
    c = (1. - step(.5, abs(p.x))) * (1. - step(2., abs(p.y)));
    
    p.x = abs(p.x) - 3.5;
    
    c += (1. - step(.5, abs(p.x))) * (1. - step(2., abs(p.y + 2.)));
    
    vec2 op = p;
    
    p.y = abs(p.y + 5.) - 5.0;
    splat(p, i2, o2);

    op.x = mod(p.x, 7.) - 3.5;
    op.y += 3.8;
    splat(op, i, o);
    
    i = sign(i + i2);
    o = sign(o + o2) * (1. - c);

    return vec3(1, .01, .01) * i +
           vec3(1, .1, .01) * o +
           vec3(.05, .01, .01) * (1. - i - o);
}

vec3 wood(vec3 p) {
    return mix(vec3(.17, .1, .05), vec3(.08, .05, .03), vec3(n11(n31(p * vec3(1, 2, 50.)) * 30.)));
}

Hit sdBlood(vec3 p) {
    if (opn < .01)
        return Hit(1e7, 1); // Door not open => No blood required.
    
    p.y += 5.4;
    p.z -= 12.8 - opn * 7.;
    
    float a = atan(p.y, p.z) * 40.,
          bmp = (n21(2.02 * vec2(a - time2 * 4., p.x * 5.)) + n21(vec2(a - time2 * 8., p.x))) / 20.;

    return Hit(
        min(
        sdSph(p, 5.) + sin(time2 * 2.0 + p.z) * .07 - // Main blood pile (Sphere)
        smoothstep(0., 1., max(0., cos((p.x + .5) * 4.) * .3 * (1. + p.z * .18))) // Bulge out of the door gap.
        - bmp, // Surface bumps.
        max(length(p.xz) - mix(2.9, 10., opn), p.y - 4.4 - bmp * .6)), // Blood disc near floor.
        9); // Blood ID.
}

// Map the scene using SDF functions, minus blood.
Hit mapq(vec3 p) {
    Hit h = Hit(-sdBox(p, vec3(.9, 1., 9.6)), 1); // Corridor.

    float nb, dr, el, wd, bn = sdBin(p), shf, dkwd;
    
    vec3 op = p;
    const vec3 ws = vec3(.1, .7, .4); // Door size.
    p.x = abs(p.x) - .9;
    p.y += .96;
    p.z = mod(p.z - 3.5, 4.) - 2.0;
    wd = sdBox(p, vec3(.01, .04, 66.6)); // Skirting.
    h.d = min(h.d, min(bn, sdBox(p, vec3(.05, 66.6, .08)))); // Pillars.
    p.y -= 1.9;
    h.d = min(h.d, sdBox(p, vec3(1., .1, .08))); // Arches.

    // Coving.
    p.x += .04;
    p.z += .12;
    h.d = min(h.d, min(sdCoving(p), sdCoving(p.zyx)));
    
    // Room doors.
    p = op;
    p.y += .3;
    p.z = mod(clamp(p.z, 0., 9.) + .5, 2.) - 1.0;
    h.d = max(min(h.d, wd), -sdBox(p, vec3(66.6, .7, .4))); // Doorway.
    p.x = abs(p.x) - 1.07;
    dr = sdBox(p, ws); // Door.
    nb = sdSph(p + vec3(.12, .04, -.28), .03); // Knob.
    
    // Elevator.
    p = op;
    p.y += .3;
    p.z -= 9.68;
    shf = sdBox(p - vec3(0, 0, .3), vec3(.5, .7, .5)) - .001; // Shaft.
    dkwd = min(sdBox(p - vec3(0, .8, 0), vec3(.7, .1, .1)),
               sdBox(ax(p) - vec3(.6, 0, 0), vec3(.1, .7, .1))); // Mantle
    vec2 sl = vec2(opn - .09, 0);
    el = sdBox(p - vec3(sl, .1), ws.zyx) + n21((p.xy - sl) * 100.) * .001; // Sliding door.
    p.x -= .5;
    p.z -= .05;
    el = min(el, sdBox(p, ws.zyx) + n21(p.xy * 100.) * .001); // Fixed door.
    h.d = min(max(h.d, -shf), dkwd);
    shf = max(abs(shf), -p.z);
    
    // Assign materials.
    h.d = min(h.d, min(min(min(dr, el), nb), shf));
    if (abs(op.y + 1.) < .002) h.id = 2; // Carpet.
    else if (h.d == min(wd, dr)) h.id = 3; // Wood.
    else if (h.d == nb) h.id = 4; // Gold.
    else if (h.d == bn) h.id = 5; // Bin.
    else if (h.d == el) h.id = 6; // Elevator.
    else if (h.d == shf) h.id = 7; // Elevator shaft.
    else if (h.d == dkwd) h.id = 8; // Dark wood - Elevator top.
        
    return h;
}

// Map the scene using SDF functions, with blood.
Hit map(vec3 p) {
    return minH(mapq(p), sdBlood(p));
}

// Get normal for scene, excluding blood.
vec3 calcN(vec3 p) {
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.);
        n += e * mapq(p + e * .25).d;
    }
    
    return normalize(n);
}

// Get normal for blood.
vec3 calcNb(vec3 p) {
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.);
        n += e * sdBlood(p + e * .25).d;
    }
    
    return normalize(n);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) {
    return map(p + h * n).d / h;
}

/**********************************************************************************/

vec3 vignette(vec3 c, vec2 fc) {
    vec2 q = fc.xy / resolution.xy;
    c *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.5);
    return c;
}

vec3 applyLighting(vec3 p, vec3 rd, Hit h) {
    vec3 n, col = vec3(1.), sunDir;
    float sp = .4; // Specular.
    
    // Apply material properties.
    if (h.id == 9) {
        col = vec3(.25, .003, .003) * .4;
        n = calcNb(p);
        sp = 1.0;
        
        col += pow(max(0., normalize(reflect(rd, n)).y), 100.) * .2;
        col *= .2 + .8 * sdBlood(p + normalize(vec3(0, .5, 8.) - p) * .08).d / .08;
    } else n = calcN(p);

    if (h.id == 1)
        n += (n21(p.yz * vec2(8., 18.)) - .5) * .015; // Walls (with bump)
    else if (h.id == 2) {
        // Carpet.
        col = carpet(p.xz * 10.);
        n += .5 * n21(mod(p.xz * 256.78, 200.)) - .25;
    } else if (h.id == 3)
        // Wood.
        col = wood(p);
    else if (h.id == 4)
        // Gold
        col = vec3(.45, .35, .1), sp = .8;
    else if (h.id == 5) {
        // Bin
        col = vec3(.06, .03, .03);
        n += n21(p.xz * vec2(90, 180));
    } else if (h.id == 6)
        // Elevator.
        col = vec3(.15, .001, .001);
    else if (h.id == 7)
        // Elevator shaft.
        col = vec3(.01);
    else if (h.id == 8)
        // Dark wood.
        col = wood(p * vec3(1, 20, 1)) * .05;
    
    float ao = .4 + (ao(p, n, .035) + ao(p, n, .5)) * .6, l = 0., spe = 0.;

    for (float i = .0; i < 3.0; i++) {
        l += max(0., dot(sunDir = normalize(vec3(0, .5, i * 4.) - p), n)) / 3.0;
        spe += smoothstep(0., 1., pow(max(0., dot(rd, reflect(sunDir, n))), 90.)) * sp;
    }
    
    return col * (l * ao + spe) * vec3(2, 1.8, 1.7);
}

vec3 march(vec3 ro, vec3 rd) {
    // Raymarch.
    vec3 p;
    
    float d = .01;
    Hit h;
    for (float i = .0; i < MAX_STEPS; i++) {
        p = ro + rd * d;
        h = map(p);
        
        // Ceiling lights.
        for (float i = .0; i < 3.0; i++) {
            float l = sdSph(p - vec3(0, 1., i * 4.), .1);
            g += .1 / (.002 + l * l);
        }
        
        if (h.d < MIN_DIST)
            break;
        
        d += h.d;
    }

    // Lighting.
    return applyLighting(p, rd, h) *
        exp(-d * .14) + // Fog.
        g * .005; // Glow around lights.
}

void main(void)
{
    time2 = mod(time, 30.);
    
    // Camera.
    vec3 ro = vec3(0, -.5, .35);
    float t = min(min(min(time2, abs(time2 - 3.)), abs(time2 - 6.)), abs(time2 - 30.)),
          dim = 1. - pow(abs(cos(clamp(t, -1., 1.) * 1.57)), 10.);
    
    if (time2 < 3.) ro.z = time2 * .3;
    else if (time2 < 6.) ro.z = 2. + time2 * .3;
    else ro.z = mix(7., 7.8, smoothstep(-1., 3., time2 - 6.));
    if (time2 > 13.) ro.z -= smoothstep(13., 17., time2) * 3.;
    
    opn = smoothstep(0., 1., (time2 - 8.8) * 0.2) * .45;
    
    vec3 col = vec3(0);
#ifdef AA
    for (float dx = .0; dx <= 1.0; dx++) {
        for (float dy = .0; dy <= 1.0; dy++) {
            vec2 uv = (gl_FragCoord.xy + vec2(dx, dy) * .5 - .5 * resolution.xy) / resolution.y;
#else
            vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
#endif
            
            col += march(ro, getRayDir(ro, uv));
#ifdef AA
        }
    }
    col /= 4.0;
#endif
    
    // Output to screen.
    glFragColor = vec4(vignette(pow(col * dim, vec3(.45)), gl_FragCoord.xy), 0.0);
}
