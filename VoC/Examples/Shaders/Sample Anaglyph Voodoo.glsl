#version 420

// original https://www.shadertoy.com/view/tddXR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
@lsdlive
CC-BY-NC-SA

Voodoo.

Volumetric raymarching for Cookie fanzine #003 with theme "anaglyph".
Use your red/blue glass to see this in 3D!

More about volumetric raymarching: https://www.shadertoy.com/view/wd3GWM

Some notation:
p: position (usually in world space)
rd: ray direction (eye or view vector)
*/

// Enable/disable animation & anaglyph (3D effect)
#define ANIMATE
#define ANAGLYPH

#define PI 3.14159
#define TAU 6.28318

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

// iq's noise
float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3. - 2. * f);
    vec2 uv = (p.xy + vec2(37., 17.) * p.z) + f.xy;
    vec2 rg = vec2(0.0);//textureLod(iChannel0, (uv + .5) / 256., 0.).yx;
    return -1. + 2.4 * mix(rg.x, rg.y, f.z);
}

// Fbm
float fbm(vec3 p) {
    return noise(p * .06125) * .5 + noise(p * .125) * .25 + noise(p * .25) * .125;
}

// Dodecahedron folding
// checkout: https://www.shadertoy.com/view/wtsGzl
vec3 fold(vec3 p) {
    vec3 nc = vec3(-.5, -.809017, .309017);
    for (int i = 0; i < 5; i++) {
        p.xy = abs(p.xy);
        p -= 2. * min(0., dot(p, nc))*nc;
    }
    return p - vec3(0, 0, 1.275);
}

float sdf_crystal(vec3 p, float scale) {
    vec3 fp = fold(p * scale);
    float cryst = dot(fp, normalize(sign(fp))) - .1 - sin(fp.y*.2)*2. - sin(fp.y*.7)*1.;
    cryst += min(fp.x*1., sin(fp.y*.3));

    fp = fold(fp) - vec3(.2, .57, -.2);
    fp = fold(fp) - vec3(-.14, .99, -2.4);
    fp = fold(fp) - vec3(-.03, 1., -.3);
    fp = fold(fp) - vec3(0, .26, 0);
    cryst += sin(fp.y*.18)*5.;
    cryst *= .6;

    return cryst / scale;
}

float sdf_mask(vec3 p) {
    p.x = abs(p.x) - .28;

    p.xz *= r2d(.56);
    p.xy *= r2d(-.01);

    return sdf_crystal(p, 3.);
}

float de(vec3 p) {

#ifdef ANIMATE
    p.xy *= r2d(sin(time)*.3);
    p.xz *= r2d(sin(time*2.)*.12);
    p.xy *= r2d(sin(sin(time * 2.) * 2.) * .2);
    p.x += sin(time*2.)*.9;
#endif

    return sdf_mask(p * .1) / .1 + fbm(p * 35.) * .1;
}

vec3 camera(vec3 ro, vec3 ta, vec2 uv) {
    vec3 fwd = normalize(ta - ro);
    vec3 left = normalize(cross(vec3(0, 1, 0), fwd));
    vec3 up = normalize(cross(fwd, left));
    return normalize(fwd + uv.x * left + up * uv.y);
}

float raymarch(vec3 ray_ori, vec2 uv) {
    vec3 target = vec3(0);
    vec3 ray_dir = camera(ray_ori, target, uv);
    vec3 pos = ray_ori;

    // local density/distance
    float ldensity = 0.;

    // accumulation color & density
    vec4 sum = vec4(0.);

    float tmax = 25.;
    float tdist = 0., dist = 0.;

    for (float i = 0.; (i < 1.); i += 1. / 64.) {

        if (dist < tdist * .001 || tdist > tmax || sum.a > .95)
            break;

        // evaluate distance function
        dist = de(pos) * .59;

        // check whether we are close enough (step)
        // compute local density and weighting factor 
        const float h = .05;
        ldensity = (h - dist) * step(dist, h);

        vec4 col = vec4(1);
        col.a = ldensity;

        // pre-multiply alpha
        // checkout: https://www.shadertoy.com/view/XdfGz8
        // http://developer.download.nvidia.com/assets/gamedev/files/gdc12/GDC2012_Mastering_DirectX11_with_Unity.pdf
        col.rgb *= col.a;
        sum += (1. - sum.a) * col;

        // from duke/las
        sum.a += .004;

        // enforce minimum stepsize
        dist = max(dist, .03);

        // step forward
        pos += dist * ray_dir; // sphere-tracing
        tdist += dist;
    }

    // from duke/las
    // simple scattering approximation
    sum *= 1. / exp(ldensity * 3.) * 1.25;

    sum.r = pow(sum.r, 2.15);
    //sum.r -= texture(iChannel0, uv * 6.).r * .18;

    return sum.r;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    float rotation_delta = 1.57;
    float z_dst = -23.5;

#ifdef ANAGLYPH
    rotation_delta -= .02;
#endif

    vec3 ro1 = vec3(z_dst * cos(rotation_delta), 0, z_dst * sin(rotation_delta));

#ifdef ANAGLYPH
    rotation_delta += .04;
#endif

    vec3 ro2 = vec3(z_dst * cos(rotation_delta), 0, z_dst * sin(rotation_delta));

    float red = raymarch(ro1, uv);
    float cyan = raymarch(ro2, uv);

    glFragColor = vec4(vec3(red, vec2(cyan)), 1.);
}
