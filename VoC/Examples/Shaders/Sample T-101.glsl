#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tKyzV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'T-101' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/3tKyzV
//
// I wanted to create a metal material, and found a
// cool resource describing the physical properties
// of metal:
//   https://www.chaosgroup.com/blog/understanding-metalness
//
// What better scene to try it than the T-101 arm
// from Terminator 2? :)
//
// Tricks to get the performance:
//   - The map() function checks if the point is within
//     the glass.  If not in the glass, we don't bother
//     calculating the SDF of the arm.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!

#define Z0 min(time, 0.)

float open;

// #define AA    // Enable this line if your GPU can take it!

void minH(inout vec2 a, vec2 b) {
    if (b.x < a.x) a = b;
}

float remap(float f, float in1, float in2, float out1, float out2) {
    return mix(out1, out2, clamp((f - in1) / (in2 - in1), 0., 1.));
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float sdCyl(vec3 p, vec2 hr) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - hr;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float sdCapsule(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0., h);
    return length(p) - r;
}

float sdRod(vec3 p, vec3 a, vec3 b, float r) {
  vec3 pa = p - a, ba = b - a;
  return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0., 1.)) - r;
}

vec3 getRayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

float sdPinkyPin(vec3 p) {
    p.x += .18;
    return sdCapsule(p.yxz, .34, .12);
}

float sdPinky(vec3 p) {
    p.y -= .7;

    float d = sdCyl(p, vec2(.16));
    p.y += .24;
    d = min(d, sdCyl(p, vec2(.2, .14))) - .04;
    p.y += .5;
    d = min(d, sdPinkyPin(p));
    p.x += .12;
    return min(d, max(sdCapsule(p, .3, .2), abs(p.x) - .1));
}

float sqHinge(vec3 p, float thk) {
    p.y += .2;

    vec3 tp = p;
    tp.x -= .12;
    tp.y += .1;
    float d = max(sdCapsule(tp, .38, .2), abs(tp.x) - .1);
    p.y += .1 + .04 * thk;
    return max(min(d, sdBox(p, vec3(.2, .04 * thk, .19))), -p.y - .04);
}

float fingerBone(vec3 p, float l) {
    float d = min(
                sqHinge(p, 1.),
                sqHinge(p * vec3(-1, -1, 1) - vec3(0, l, 0), 1.));

    p.y += l * .5;
    return min(d, sdCyl(p, vec2(.16, 1. - .8 / l)));
}

vec3 pToPinkyAttach(vec3 p, float r) {
    p.z += abs(r) * 5. - .7;
    mat2 t = rot(-r);
    p.xz *= t;
    p.xy *= t;
    p.yz *= rot(open * -.5);

    p.y -= .35;
    p.z += .25;
    return p;
}

float sdFinger(vec3 p, float l1, float l2, float r, float r2) {
    p.z += abs(r) * 5. - .7;
    mat2 t = rot(-r);
    p.xz *= t;
    p.xy *= t;

    // Base hinge.
    float d = min(sqHinge(p, 4.), sdCyl(p + vec3(0, 2, 0), vec2(.14, 1.5)));
    d = min(d, sdBox(p + vec3(0, .65, 0), vec3(.2, .12, .2 + step(abs(p.x), .08) * .03)));

    p.yz *= rot(open * -.5 + r2);
    vec3 fp, s, o = vec3(0, l1, 0);

    // Base bone.
    d = min(d, min(sdPinkyPin(p), sdPinkyPin(p - o)));
    // todo - Bail ealy here?
    d = min(d, fingerBone(p - o, l1));

    // Middle bone.
    s = o;
    s.yz += vec2(l2, 0) * rot(open);
    fp = p - s;
    fp.yz *= rot(-open);
    d = min(d, fingerBone(fp, l2));

    // Pinky
    fp = p - s;
    fp.yz *= rot(open * -2.);
    return min(d, sdPinky(fp));
}

float sdFingers(vec3 p) {
    p.x += .7 * 1.5;
    float d = sdFinger(p, .9, .85, -.1, 0.);
    p.x -= .7; d = min(d, sdFinger(p, 1.2, 1., -.03, 0.));
    p.x -= .7; d = min(d, sdFinger(p, 1.3, 1.1, .03, 0.));
    p.x -= .7;
    return min(d, sdFinger(p, 1.2, 1.05, .1, 0.));
}

float pinkyPiston(vec3 p, vec3 basep, float r) {
    p = pToPinkyAttach(p, r);

    float d = step(length(vec3(0, -.2, -.2) - basep), 3.2) * .04;
    return min(
        sdRod(p, vec3(0, -.03, .08), vec3(0, -.2, -.2), .05),
        sdRod(p, p - basep, vec3(0, -.2, -.2), .05 + d));
}

float sdPiston(vec3 p, vec3 p1, vec3 p2, float b) {
    p1.y -= .1;
    float l = p.y - p1.y;
    float r = .14
              + .04 * step(-1.3, l) * sign(sin(p.y * 6. - 4.))
              + .15 * b * smoothstep(-5., -5.1, l),
              d = sdRod(p, p1, p2, r);

    p -= mix(p1, p2, .79);
    p.y = abs(abs(p.y) - .7) - .1;
    return min(d, sdCyl(p, vec2(.16 + .15 * b, .05)));
}

float sdArm(vec3 p) {
    // Thumb.
    vec3 fp = p;
    fp.xz *= rot(-1.4);
    float d = min(sdFingers(p),
                  max(
                     sdFinger(fp + vec3(-.5, 2.7, .05), 1.5, 1.4, .03, 1.),
                     -fp.y - 3.5));

    // Wrist plate.
    fp = p;
    p.y += 3.5;
    d = min(d, sdCyl(p, vec2(1, .1)));

    // Finger hydraulics.
    fp.x += .7 * 1.5; d = min(d, pinkyPiston(fp, p + vec3(.5, 0, .4), -.1));
    fp.x -= .7; d = min(d, pinkyPiston(fp, p + vec3(.2, 0, .6), -.03));
    fp.x -= .7; d = min(d, pinkyPiston(fp, p + vec3(-.1, 0, .5), .03));
    fp.x -= .7; d = min(d, pinkyPiston(fp, p + vec3(-.6, 0, .1), .1));

    // Main arm bone.
    fp = p;
    fp.y += 4.;
    d = min(d, sdCyl(fp, vec2(.35 + step(3., fp.y) * (.1 - .02 * sign(abs(sin(fp.y * 24. + 1.6)) - .8) * step(fp.y, 3.5)), 4)));

    // Arm base.
    d = min(min(d, length(p + vec3(0, 7.1, 1.25)) - .05),
            max(abs(sdCyl(p + vec3(0, 7, .1),
                          vec2(1.1 - .01 *
                                 (
                                     step(abs(p.y + 7.7), .04) *
                                     step(.04, abs(p.x) - .3) -
                                     step(.04, abs(abs(p.x) - .3))
                                 ),
                               1
                              )
                         )) - .06,
                p.y - .3 * p.z + 6.6));

    // Arm pistons.
    d = min(d, sdPiston(p, vec3(0, 0, -.8), vec3(0, -7.5, -.7), 1.5));
    p.x = abs(p.x) - .7;
    return min(d, sdPiston(p, vec3(0), vec3(-.1, -7.5, 0), 1.));
}

float sdGlass(vec3 p) {
    return sdCapsule(p + vec3(0,11,0), 13.5, 3.2);
}

// Map the scene using SDF functions.
vec2 map(vec3 p) {
    vec2 h = vec2(min(abs(p.y + 11.7), abs(p.z - 6.)), 1);

    if (sdGlass(p) < 0.)
        minH(h, vec2(sdArm(p - vec3(0,1.4,0)) * .8, 2));

    p.y += 10.9;
    minH(h, vec2(sdCyl(p, vec2(3.1, .5)) - .2, 2));

    return h;
}

vec3 calcN(vec3 p, float t) {
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .0017319 * (2. * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * t).x;
    }

    return normalize(n);
}

vec3 glassN(vec3 p) {
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .0017319 * (2. * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.);
        n += e * sdGlass(p + e);
    }

    return normalize(n);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) { return map(p + h * n).x / h; }

/**********************************************************************************/

vec3 vignette(vec3 c, vec2 fc) {
    vec2 q = fc.xy / resolution.xy;
    c *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
    return c;
}

vec3 lights(vec3 p, vec3 rd, float d, vec2 h) {
    vec3 ld = normalize(vec3(12, 5, -10) - p),
         n = calcN(p, d), c;
    float f, alb;

    if (h.y == 1.) {
        // Walls.
        alb = max(0., .1 + .9 * dot(ld, n));
        c = vec3(.5, .7, 1);
        f = .3;
    } else {
        // Metal.
        c = vec3(.6);
        alb = 1.;
        f = 10.;
    }

    float ao = ao(p, n, .3),

    // Primary light.
    l1 = alb * (.3 + .7 * ao), // ...and _some_ AO.

    // Secondary(/bounce) light.
    l2 = max(0., .1 + .9 * dot(ld * vec3(-1, 0, -1), n)) * .3,

    // Specular.
    spe = smoothstep(0., 1., pow(max(0., dot(rd, reflect(ld, n))), 3. * f)) * f,

    // Fresnel
    fre = 1. - smoothstep(.4, 1., 1. + dot(rd, n));

    if (h.y == 3.) // Glass
        return vec3(spe);

    // Combine into final color.
    float lig = (l2 + spe) * ao + l1;
    return fre * lig * c * vec3(2, 1.8, 1.7);
}

float glassCol(vec3 p, vec3 rd) {
    vec3 ld = normalize(vec3(12, 5, -10) - p),
         n = glassN(p);
    return .01 + pow(max(0., dot(rd, reflect(ld, n))), 30.) * 3. + smoothstep(.4, 1., 1. + dot(rd, n)) * .3;
}

vec3 march(vec3 ro, vec3 rd) {
    // Raymarch.
    vec3 p = ro, col = vec3(0);

    float d = .01;
    vec2 h;
    bool inGlass = false, doneGlass = false;
    for (float i = Z0; i < 120.; i++) {
        h = map(p);

        float g = abs(sdGlass(p));
        if (!doneGlass && g < .005) {
            float c = glassCol(p, rd);
            if (!inGlass) {
                inGlass = true;

                // Add slight glass refraction.
                p += .5 * refract(rd, glassN(p), 1.0/3.);
            } else {
                c *= .1;
                doneGlass = true;
            }

            col += c;
            g += .1;
        }

        if (abs(h.x) < .005)
            break;

        d += min(g, h.x); // No hit, so keep marching.
        p += rd * min(g, h.x);
    }

    col += lights(p, rd, d, h) * exp(d * d * -.001);

    if (h.y == 1.)
        return col; // Hit wall - No reflection needed.

    // We hit metal, so march along a reflection ray.
    rd = reflect(rd, calcN(p, d)); ro = p; d = .01;
    for (float i = Z0; i < 40.; i++) {
        p = ro + rd * d;
        h = map(p);

        if (abs(h.x) < .005)
            break;

        d += h.x;
    }

    return abs(h.x) < .005 ?
        mix(col, .6 * lights(p, rd, d, h), .9) :
        mix(col, vec3(1), .5);
}

void main(void)
{
    open = .4;

    float T = mod(time * 2.5, 36.),
          dim = 1. - pow(abs(cos(clamp(min(T, abs(T - 12.)), -1., 1.) * 1.57)), 10.);

    vec3 ro, lookAt;
    if (T < 12.) {
        float p = remap(T, 0., 12., 0., 1.);
        ro = mix(vec3(-6, -6, -23), vec3(6, 2, -15), p);
        lookAt = mix(vec3(0, -5, 0), vec3(0, -2, 0), p);
    } else if (T < 24.) {
        float p = remap(T, 12., 24., 0., 1.);
        ro = mix(vec3(2, -10, -9), vec3(-2, -4, -9), p);
        lookAt = mix(vec3(0, -10, 0), vec3(0), p);
    } else if (T < 36.) {
        float p = remap(T, 24., 36., 0., 1.);
        ro = mix(vec3(3, 0, -12), vec3(-3, 0, -15), p);
        lookAt = vec3(0, -1, 0);
        open = .35 * sin(p * 11.) + .7462;
    }

#ifdef AA
    vec3 col = vec3(0);
    for (float dx = Z0; dx <= 1.; dx++) {
        for (float dy = Z0; dy <= 1.; dy++) {
            vec2 uv = (fc + vec2(dx, dy) * .5 - .5 * resolution.xy) / resolution.y;
            col += march(ro, getRayDir(ro, lookAt, uv));
        }
    }
    col /= 4.;
#else
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 col = march(ro, getRayDir(ro, lookAt, uv));
#endif

    // Output to screen.
    glFragColor = vec4(vignette(pow(col * dim, vec3(.45)), gl_FragCoord.xy), 0);
}
