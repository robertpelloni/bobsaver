#version 420

// original https://www.shadertoy.com/view/3dGXD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FDIST 0.7
#define PI 3.1415926

#define GROUNDSPACING 0.5
#define GROUNDGRID 0.05

#define SPHERESPACING 0.25
#define SPHEREGRID 0.01

#define RADIUS 1.

#define ABSORPTION_RATE vec3(0.9, 0.8, 0.8)
#define IOR 1.33
#define LOW_SCATTER 0.001
#define HIGH_SCATTER 0.03
#define SAMPLES 25
#define REFLECTIONS 3
#define RAYMARCH_STEPS 15
#define RAYMARCH_TOL 0.005

#define TIME_T 6.
#define TIME_H 6.
#define TIME_L 6.

float oscillate(float t_low, float t_high, float t_transition, float t_offset) {
    float t_osc = 0.5*(t_high+t_low)+t_transition;
    float h_l = 0.5*t_low/t_osc;
    float h_h = (0.5*t_low+t_transition)/t_osc;
    return smoothstep(0., 1., (clamp(abs(mod(time + t_offset, t_osc*2.)/t_osc-1.), h_l, h_h) - h_l) / (h_h - h_l));
}

vec2 rand2d(in vec2 uv) {
    return fract(mat2(-199.258, 457.1819, -1111.1895, 2244.185)*sin(mat2(111.415, -184, -2051, 505)*uv));
}

vec2 box(in vec3 ro, in vec3 rd, in vec3 r, out vec3 ni, out vec3 no) {
    vec3 dr = 1.0/rd;
    vec3 n = ro * dr;
    vec3 k = r * abs(dr);
    
    vec3 pin = - k - n;
    vec3 pout =  k - n;
    float tin = max(pin.x, max(pin.y, pin.z));
    float tout = min(pout.x, min(pout.y, pout.z));
    if (tin > tout) return vec2(-1.);
    ni = -sign(rd) * step(pin.zxy, pin.xyz) * step(pin.yzx, pin.xyz);
    no = sign(rd) * step(pout.xyz, pout.zxy) * step(pout.xyz, pout.yzx);
    return vec2(tin, tout);
}

float sphere(in vec3 ro, in vec3 rd, in float r, in bool entering, out vec3 n) {
    float pd = dot(ro, rd);
    float disc = pd*pd + r*r - dot(ro, ro);
    if (disc < 0.) return -1.;
    float tdiff = sqrt(disc);
    float t = -pd + (entering ? -tdiff : tdiff);
    n = normalize(ro + t * rd);
    
    return t;
}

float spheresdf(in vec3 ro, in float r) {
    float mag = 0.02 * oscillate(TIME_L*.5, TIME_H*.5, TIME_T*0.5, -2.);
    return length(ro) - r + mag*(sin(ro.y*20. + time*1.32)+1.);
}

vec3 spheregrad(in vec3 ro, in float r) {
    vec2 diff = vec2(RAYMARCH_TOL, 0.);
    float dx = spheresdf(ro + diff.xyy, r) - spheresdf(ro - diff.xyy, r);
    float dy = spheresdf(ro + diff.yxy, r) - spheresdf(ro - diff.yxy, r);
    float dz = spheresdf(ro + diff.yyx, r) - spheresdf(ro - diff.yyx, r);
    return normalize(vec3(dx, dy, dz));
}

float hybridsphere(in vec3 ro, in vec3 rd, in float r, in bool entering, out vec3 n) {
    float t = sphere(ro, rd, r, entering, n);
    for (int i=0; i<RAYMARCH_STEPS; i++) {
        float dist = spheresdf(ro + t*rd, r);
        t += (entering ? dist : -dist);
        if (dist < RAYMARCH_TOL) {
            n = spheregrad(ro + t*rd, r);
            return t;
        }
    }
    return -1.;
}

vec3 bgcol(in vec3 rd) {
    return mix(vec3(0., 0., 1.), vec3(0.6, 0.8, 1.), 1.-pow(abs(rd.z), 2.));
}

vec3 z_to_vec(in vec3 d, in vec3 z) {
    vec3 u = normalize(cross(vec3(0., 0., 1.), d));
    vec3 v = cross(d, u);
    return u * z.x + v * z.y + d * z.z;
}

//raytrace the exterior surroundings
vec4 background(in vec3 ro, in vec3 rd) {
    float t = (-1. - ro.z)/rd.z;
    vec3 col1;
    if (t < 0.) {
        t = 1000.;
        col1 = bgcol(rd);
    } else {
        vec2 uv = ro.xy+t*rd.xy;
        if (max(abs(uv.x), abs(uv.y)) > 8.) col1 = bgcol(rd);
        else {
            vec2 checkers = smoothstep(vec2(GROUNDGRID*0.75), vec2(GROUNDGRID), abs(mod(uv, vec2(GROUNDSPACING))*2.-GROUNDSPACING));
            float aofac = smoothstep(0., 1.25, length(uv));
            col1 = mix(vec3(0.2), vec3(0.8), min(checkers.x,checkers.y)) * (1.-0.5*(1.-aofac));
        }
    }
    
    vec3 ni;
    float voffset = abs(0.8*sin(1.4*time));
    float t2 = sphere(ro - vec3(0.6 + RADIUS, 0., -0.4 + voffset), rd, 0.6, true, ni);
    vec3 spherero = t2 * rd + ro - vec3(0., 0., voffset);
    vec3 spherech = smoothstep(vec3(SPHEREGRID*0.75), vec3(SPHEREGRID), abs(mod(spherero, vec3(SPHERESPACING))*2.-SPHERESPACING));
    float tea = mix(t, t2, step(0., t2));
    return vec4(mix(col1, mix(vec3(1., 0., 0.), mix(vec3(1.), vec3(0.5, 0.6, 0.8), spherero.z+1.), min(spherech.x, min(spherech.y, spherech.z))), step(0., t2)), tea);
}

vec3 randnorm(vec2 seed, float SCATTER_FACTOR) {
    vec2 theta = rand2d(seed);
    theta *= vec2(2.*PI, SCATTER_FACTOR*PI);
    return vec3(cos(theta.x)*sin(theta.y), sin(theta.x)*sin(theta.y), cos(theta.y));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.x;
    float mouseY = 0.5;
    float mouseX = time*0.25;
    vec3 eye = 4.*vec3(cos(mouseX) * cos(mouseY), sin(mouseX) * cos(mouseY), sin(mouseY));
    vec3 w = normalize(-eye);
    vec3 up = vec3(0., 0., 1.);
    vec3 u = normalize(cross(w, up));
    vec3 v = cross(u, w);
    
    vec3 rd = normalize(w * FDIST + uv.x * u + uv.y * v);
    
    vec3 ni;
    float t = hybridsphere(eye, rd, RADIUS, true, ni);
    vec3 ro = eye + t * rd;
    vec2 coords = ro.xy * ni.z + ro.yz * ni.x + ro.zx * ni.y;
    
    vec4 bgg = background(eye, rd);
    
    if (t > 0. && t < bgg.w) {
        
        float osc = oscillate(TIME_L, TIME_H, TIME_T, 0.);
        float SCATTER_FACTOR = mix(LOW_SCATTER, HIGH_SCATTER, osc);
        vec3 col = vec3(0.);
        float R0 = (IOR-1.)/(IOR+1.);
        R0*=R0;
        for (int i=0; i<SAMPLES; i++) {
            
            vec3 n = randnorm(coords + float(i) * vec2(1., 0.) * vec2(104., -30.6), SCATTER_FACTOR);
            // reflection
            vec3 nr = z_to_vec(ni, n);
            float fresnel = R0 + (1.-R0) * pow(1.-dot(-rd, nr), 5.);
            vec3 rdr = reflect(rd, nr);
            vec3 reflcol = background(ro, rdr).xyz;
            
            // refraction, absorption and internal reflection
            vec3 rd_refr = refract(rd, nr, 1./IOR);
            
            vec3 insidecol = vec3(0.);
            float accum = 1.;
            vec3 transmission = vec3(1.);
            vec3 ro_refr = ro;
            
            for (int j=0; j<REFLECTIONS; j++) {
                
                vec3 ni2, no2;
                float tout = hybridsphere(ro_refr, rd_refr, RADIUS, false, no2);
                no2 = z_to_vec(no2, n);
                ro_refr = ro_refr + tout * rd_refr;
                vec3 rd_refr_out = refract(rd_refr, -no2, IOR);

                float fresnel2 = R0 + (1.-R0) * pow(1.-dot(rd_refr_out, no2), 5.);
                           
                rd_refr = reflect(rd_refr, -no2);
                transmission *= pow(ABSORPTION_RATE, vec3(tout));
                insidecol += accum * (1.-fresnel2) * background(ro_refr, rd_refr_out).xyz * transmission;
                accum *= fresnel2;
            }    
            
            
            col += mix(insidecol, reflcol, fresnel);
        }
        col /= float(SAMPLES);

        glFragColor = vec4(col, 1.);
    } else {
        glFragColor = vec4(bgg.xyz, 1.);
    }
}
