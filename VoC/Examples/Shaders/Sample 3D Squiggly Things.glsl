#version 420

// original https://www.shadertoy.com/view/fsfBD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 400
#define MAX_DIST 35.
#define SURF_DIST .001

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+1e-2)

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

float mlength(vec3 uv) {
    return max(max(abs(uv.x), abs(uv.y)), abs(uv.z));
}

// (SdSmoothMin) stolen from here: https://www.shadertoy.com/view/MsfBzB
float smin(float a, float b)
{
    float k = 0.12;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

#define pi 3.14159

float h21 (float a, float b, float zoom) {
    a = mod(a, zoom); b = mod(b, zoom);
    return fract(sin(dot(vec2(a, b), vec2(12.9898, 78.233)))*43758.5453123);
}

// rand value that changes with val (time usually)
float rand(vec2 ipos, float val) {
    float a = 2. * pi * h21(ipos);
    float c = cos(a), s = sin(a);
    
    float f = floor(val);
    
    // current value (using 0.01 so it looks "random" for longer)
    float v = h21(vec2(c * f, s * f) + 0.01 * ipos);
    // next value
    float v2 = h21(vec2(c * (f + 1.), s * (f + 1.)) + 0.01 * ipos);
    
    // smooth lerp between values
    return mix(v, v2, smoothstep(0., 1., fract(val)));
}

float GetDist(vec3 p) {
    // Rotate xz plane with height + time
    vec2 uv = p.xz;
    uv *= Rot(0.28 * p.y - 0.1 * time);
    uv *= 3.;
    
    // Cut into grid
    vec2 ipos = floor(uv) + 0.5;
    vec2 fpos = uv - ipos;
    
    // Rand values
    float h = h21(ipos);
    float h2 = rand(ipos, h + 0.2 * time);
    
    // Each cell rotates with height+time, randomly
    float time = h * 4. * time + p.y * h2 * 9.; // + 2. * pi * h; // dont need offset
    vec2 q = h2 * 0.1 * vec2(cos(time), sin(time));
    
    // Radius of each squiggle (height+time), offset randomly
    float r = 0.1 * (1. + 0.5 * cos(2. * pi * h + 4. * p.y + time));
    float d = length(fpos - q) - r; 
    
    // Cut sphere out of squiggles so we can see - smin looks nice
    float sd = length(p - vec3(0, -3.5, -1.3)) - 0.7;

    // (artifacts appear in furthest tiles if d is larger)
    d = -smin(-0.35 * d, sd); 
    return d;
}

float RayMarch(vec3 ro, vec3 rd, float z) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        if(abs(dS)<SURF_DIST || dO>MAX_DIST) break;
        dO += dS*z; 
    }
    
    return min(dO, MAX_DIST);
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    // (sphere cut-out doesnt follow mouse, but you can still look)
    vec3 ro = vec3(0, -3.5, -1.3);
    //if (mouse*resolution.xy.z > 0.) {
    //    ro.yz *= Rot(-m.y*3.14+1.);
    //    ro.xz *= Rot(-m.x*6.2831);
    //}
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.8);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd, 1.);

    float IOR = 1.05;
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);

        //float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        //col = vec3(dif);
        
        vec3 rdIn = refract(rd, n, 1./IOR);
        
        vec3 pEnter = p - n*SURF_DIST*30.;
        float dIn = RayMarch(pEnter, rdIn, -1.); // inside the object
        
        vec3 pExit = pEnter + rdIn * dIn; // 3d position of exit
        vec3 nExit = -GetNormal(pExit);
        
        float fresnel = pow(1.+dot(rd, n), 3.);
        col = 2.5 * vec3(fresnel);
        
        // No idea what this does, but I need it
        col *= 0.55 + 0.45 * cross(nExit, n); 
        
        //col = clamp(col, 0., 1.); // clamp removes highlighting that I want       
        
        // Cylinder length
        float ln = length(p.xz);
        
        // Stripey patterns etc
        vec3 e = vec3(1.);
        col *= pal(4.*ln + .05*time, e, e, e, 
                   0.5 + 0.5 * thc(3., 20.*p.y + 10.*ln - 8.*time) * vec3(0,1,2)/3.);
        
        // Darken with height
        col *= (0.32 * p.y + .95);
        
        // Fake shadows (I think)
        col *= 0.8 + 1. * n.y; 
        
        // Darken in a cylinder (less aliasy thingies from far away / fake vignette)
        col *= clamp(1. - 0.3 * ln, 0., 1.);
        //float val = 0.5 + 0.5 *  thc(4., -0.2 * p.y + 1. * time);//clamp(5. + 5. * cos(p.y + time), 0., 1.);
        
        // Mix col with fres vertically, fake fog
        fresnel = pow(1.+dot(rd, n), 1.);
        col = mix(col, vec3(fresnel), clamp(-0.3 + 0.15 * p.y, 0., 1.));
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    col += 0.04;
    glFragColor = vec4(col,1.0);
}
