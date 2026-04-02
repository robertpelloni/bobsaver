#version 420

// original https://www.shadertoy.com/view/WsGXWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FDIST 0.7
#define PI 3.1415926

#define GROUNDSPACING 0.5
#define GROUNDGRID 0.05
#define BOXDIMS vec3(1., 1., 1.)

#define ABSORPTION_RATE vec3(0.5, 0.6, 0.7)
#define IOR 1.33
#define SCATTER_FACTOR 0.02
#define REFLECTIONS 3
#define RAYMARCH_STEPS 15
#define RAYMARCH_TOL 0.005

#define TIME_T 4.
#define TIME_H 0.1
#define TIME_L 10.

/**
 * Assorted utilities
 */

// 2D rotation matrix
mat2 rot2(float ang) {
    float c = cos(ang);
    float s = sin(ang);
    return mat2(c, -s, s, c);
}

// Cubic interpolation
float cubemix(float a, float b, float t) {
    float c = t*t*(3.-2.*t);
    return mix(a, b, c);
}

// Schlick approximation for the Fresnel factor
float schlick_fresnel(float R0, float cos_ang) {
    return R0 + (1.-R0) * pow(1.-cos_ang, 5.);
}

// oscillate between 0 and 1 with specified timing
float oscillate(float t_low, float t_high, float t_transition, float t_offset) {
    float t_osc = 0.5*(t_high+t_low)+t_transition;
    float h_l = 0.5*t_low/t_osc;
    float h_h = (0.5*t_low+t_transition)/t_osc;
    return smoothstep(0., 1., (clamp(abs(mod(time + t_offset, t_osc*2.)/t_osc-1.), h_l, h_h) - h_l) / (h_h - h_l));
}

/* * * * */

/**
 * random functions and fractal noise
 */
vec2 rand2d(in vec2 uv) {
    return fract(mat2(-199.258, 457.1819, -1111.1895, 2244.185)*sin(mat2(111.415, -184, -2051, 505)*uv));
}

float rand(vec2 uv) {
    return fract(814.*sin(uv.x*15829.+uv.y*874.));
}

float valuenoise(vec2 uv) {
    vec2 iuv = floor(uv);
    vec2 offset = vec2(0.,1.);
    float v00 = rand(iuv);
    float v01 = rand(iuv+offset.xy);
    float v10 = rand(iuv+offset.yx);
    float v11 = rand(iuv+offset.yy);
    vec2 disp = fract(uv);
    float v0 = cubemix(v00, v01, disp.y);
    float v1 = cubemix(v10, v11, disp.y);
    return cubemix(v0, v1, disp.x) - 0.5;
}

float fractalnoise(vec2 uv, float mag) {
    float d = valuenoise(uv);
    int i;
    float fac = 1.;
    vec2 disp = vec2(0., 1.);
    for (i=0; i<3; i++) {
        uv += mag * time * disp * fac;
        disp = mat2(.866, 0.5, -0.5, .866) * disp; //rotate each moving layer
        fac *= 0.5;
        d += valuenoise(uv/fac)*fac;
    }
    return d;
}

/* * * * */

/**
 * Ray tracing & marching primitives
 */

// Raytrace box
float box(in vec3 ro, in vec3 rd, in vec3 r, out vec3 nn, bool entering) {
    vec3 dr = 1.0/rd;
    vec3 n = ro * dr;
    vec3 k = r * abs(dr);
    
    vec3 pin = - k - n;
    vec3 pout =  k - n;
    float tin = max(pin.x, max(pin.y, pin.z));
    float tout = min(pout.x, min(pout.y, pout.z));
    if (tin > tout) return -1.;
    if (entering) {
        nn = -sign(rd) * step(pin.zxy, pin.xyz) * step(pin.yzx, pin.xyz);
    } else {
        nn = sign(rd) * step(pout.xyz, pout.zxy) * step(pout.xyz, pout.yzx);
    }
    return entering ? tin : tout;
}

// Perturbed box SDF
float boxsdf(in vec3 ro, in vec3 r) {
    vec3 mo = abs(ro);
    vec3 b = mo - r;
    float d = max(b.x, max(b.y, b.z));
    // triplanar projection of animated noise for water effect
    vec3 mask = step(mo.zxy, mo.xyz) * step(mo.yzx, mo.xyz);
    ro *= 2.;
    float disp = mask.x * fractalnoise(ro.yz + vec2(0., time), 0.25) + mask.y * fractalnoise(ro.zx + vec2(time, 0.), 0.25) + mask.z * fractalnoise(ro.xy, 0.5);
    d += 0.015 * disp;
    return d;
}

// SDF normals
vec3 boxgrad(in vec3 ro, in vec3 r) {
    vec2 diff = vec2(RAYMARCH_TOL, 0.);
    float dx = boxsdf(ro + diff.xyy, r) - boxsdf(ro - diff.xyy, r);
    float dy = boxsdf(ro + diff.yxy, r) - boxsdf(ro - diff.yxy, r);
    float dz = boxsdf(ro + diff.yyx, r) - boxsdf(ro - diff.yyx, r);
    return normalize(vec3(dx, dy, dz));
}

// Hybrid raytracing/raymarching of box
float hybridbox(in vec3 ro, in vec3 rd, in vec3 r, out vec3 n, in bool entering) {
    // first check for intersection with the basic primitive
    float t = box(ro, rd, r, n, entering);
    if (t > 0.) {
        // refine the distance to the perturbed surface through raymarching
        for (int i=0; i<RAYMARCH_STEPS; i++) {
            float dist = boxsdf(ro + t*rd, r);
            t += (entering ? dist : -dist);
            if (dist < RAYMARCH_TOL) {
                n = boxgrad(ro + t*rd, r);
                return t;
            }
        }
    }
    return -1.;
}

// Raytrace sphere
vec2 sphere(in vec3 ro, in vec3 rd, in float r, out vec3 ni) {
    float pd = dot(ro, rd);
    float disc = pd*pd + r*r - dot(ro, ro);
    if (disc < 0.) return vec2(-1.);
    float tdiff = sqrt(disc);
    float tin = -pd - tdiff;
    float tout = -pd + tdiff;
    ni = normalize(ro + tin * rd);
    
    return vec2(tin, tout);
}

// Sky color
vec3 bgcol(in vec3 rd) {
    return mix(vec3(0., 0., 1.), vec3(0.6, 0.8, 1.), 1.-pow(abs(rd.z), 2.));
}

// Raytrace the exterior surroundings
vec3 background(in vec3 ro, in vec3 rd) {
    float t = (-1. - ro.z)/rd.z;
    if (t < 0.) return bgcol(rd);
    vec2 uv = ro.xy+t*rd.xy;
    if (max(abs(uv.x), abs(uv.y)) > 8.) return bgcol(rd);
    vec2 checkers = smoothstep(vec2(GROUNDGRID*0.75), vec2(GROUNDGRID), abs(mod(uv, vec2(GROUNDSPACING))*2.-GROUNDSPACING));
    float aofac = smoothstep(-0.5, 1., length(abs(uv)-min(abs(uv), vec2(0.75))));
    return mix(vec3(0.2), vec3(1.), min(checkers.x,checkers.y)) * aofac;
}

// Raytrace the interior
vec3 insides(in vec3 ro, in vec3 rd, in float INNERRAD, in mat2 rot, out float tout) {
    vec3 ni;
    vec2 t = sphere(ro, rd, INNERRAD, ni);
    vec3 ro2 = ro + t.x * rd;
    // shading/texture
    vec2 checkers = step(mod(rot * ro2.xy, vec2(0.25)), vec2(0.01));
    vec3 tex = mix(vec3(1.), vec3(0., 0.7, 0.), abs(checkers.x-checkers.y));
    float fac = -ni.z;
    
    //inner background
    vec3 n;
    float tb = box(ro, rd, vec3(INNERRAD), n, false);
    vec3 rob = ro + tb * rd;
    vec3 checkersb = abs(mod(rob.xyz, vec3(0.5))-0.25)*4.;
    vec3 texb = mix(vec3(0., 0., 1.), vec3(0.), step(0.25, abs(abs(checkersb.x-checkersb.y)-checkersb.z)));
    tout = mix(tb, t.x, step(0., t.x));
    return mix(mix(vec3(0.5), texb, step(0., tb)) * 0.5, tex * fac, step(0., t.x));
}

/* * * * */

void main(void)
{
    // Camera setup
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.x;
    float mouseY = 0.5;
    float mouseX = time*0.25;
    vec3 eye = 4.*vec3(cos(mouseX) * cos(mouseY), sin(mouseX) * cos(mouseY), sin(mouseY));
    vec3 w = normalize(-eye);
    vec3 up = vec3(0., 0., 1.);
    vec3 u = normalize(cross(w, up));
    vec3 v = cross(u, w);
    vec3 rd = normalize(w * FDIST + uv.x * u + uv.y * v);
    
    // Initial intersection check
    vec3 n;
    float t = hybridbox(eye, rd, BOXDIMS, n, true);
    
    if (t > 0.) {
        vec3 ro = eye + t * rd;
        
        // External reflection
        vec3 rdr = reflect(rd, n);
        vec3 reflcol = background(ro, rdr);
        float R0 = (IOR-1.)/(IOR+1.);
        R0*=R0;
        float fresnel = schlick_fresnel(R0, dot(-rd, n));
        
        // Compute parameters
        float osc = oscillate(TIME_L, TIME_H, TIME_T, 0.);
        float INNERRAD = mix(0.5, 1.5, osc);
        float ang = -time * 0.33;
        mat2 rot = rot2(ang);
        vec2 coords = ro.xy * n.z + ro.yz * n.x + ro.zx * n.y;
        
        // Compute internal reflections and light leaked with each bounce
        vec3 rd2 = refract(rd, n, 1./IOR);
        vec3 insidecol = vec3(0.);
        float accum = 1.;
        vec3 transmission = vec3(1.);
        
        for (int j=0; j<REFLECTIONS; j++) {
            // Transform ray into interior space and check for intersection with interior geometry
            float tb;
            vec2 coords2 = ro.xy * n.z + ro.yz * n.x + ro.zx * n.y;
            vec3 eye2 = vec3(coords2, -max(INNERRAD, 1.));
            vec3 rd2trans = rd2.yzx * n.x + rd2.zxy * n.y + rd2.xyz * n.z;
            rd2trans.z = -rd2trans.z;
            vec3 internalcol = insides(eye2, rd2trans, INNERRAD, rot, tb);
            if (tb > 0.) {
                // Terminate at interior geometry
                insidecol += accum * internalcol * transmission * pow(ABSORPTION_RATE, vec3(tb));
                break;
            } else {
                // Compute contribution of the light leaked from the environment through this bounce
                float tout = hybridbox(ro, rd2, BOXDIMS, n, false);
                vec3 rout = ro + tout * rd2;
                vec3 rdout = refract(rd2, -n, IOR);
                float fresnel2 = schlick_fresnel(R0, dot(rdout, n));
                rd2 = reflect(rd2, -n);

                ro = rout;
                // slight correction to get rid of artifacts where transparent interior touches the floor
                ro.z = max(ro.z, -0.999);

                // Accumulate leaked light
                transmission *= pow(ABSORPTION_RATE, vec3(tout));
                insidecol += accum * (1.-fresnel2) * background(ro, rdout) * transmission;
                if (fresnel2 < 0.1) break;
                accum *= fresnel2;
            }
        }
        vec3 col = mix(insidecol, reflcol, fresnel);

        glFragColor = vec4(col, 1.);
    } else {
        glFragColor = vec4(background(eye, rd), 1.);
    }
}
