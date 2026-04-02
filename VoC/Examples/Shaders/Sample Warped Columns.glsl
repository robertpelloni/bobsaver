#version 420

// original https://www.shadertoy.com/view/ddV3R1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 400
#define MAX_DIST 12.
#define SURF_DIST .001

#define tau 6.2831853071
#define pi 3.1415926535
#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define Dir(a) vec2(cos(a),sin(a))
#define pal(a,b) .5+.5*cos(2.*pi*(a+b))
#define sabs(x) sqrt(x*x+1e-2)
//#define sabs(x, k) sqrt(x*x+k)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

#define FK(k) floatBitsToInt(k*k/7.)^floatBitsToInt(k)
float hash(float a, float b) {
    int x = FK(a), y = FK(b);
    return float((x*x+y)*(y*y-x)-x)/2.14e9;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax, p)*ax, p, cos(ro)) + cross(ax,p)*sin(ro);
}

float cc(float a, float b) {
    float f = thc(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float cs(float a, float b) {
    float f = ths(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float h21(vec2 a) { return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123); }
float mlength(vec2 uv) { return max(abs(uv.x), abs(uv.y)); }
float mlength(vec3 uv) { return max(max(abs(uv.x), abs(uv.y)), abs(uv.z)); }

// Maybe remove this
float sfloor(float a, float b) { return floor(b-.5)+.5+.5*tanh(a*(fract(b-.5)-.5))/tanh(.5*a); }

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

float smax(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) + k * h * (1. - h); 
}

vec3 ori() {
    return 4.5 * vec3(-1, sin(0.2 * time), 1);
}

vec2 map(vec3 p) {
    float cd = length(p - ori()) - 3.2;

    // Rescale coords, as in this shader:
    // https://www.shadertoy.com/view/XddBzX
    float l = abs(1. - 0.5 * dot(p, p));
    p *= 2.25 / l;
    
    // Translation acts differently
    p.xz -= 0.25 * time;
   
    // Grid of warped columns / "torii"
    vec3 p2 = fract(p) - 0.5;
    
    // Braid columns, rotate differently using checkerboard pattern
    float m = mod(floor(p.x) + floor(p.z), 2.);
    p2.xz *= rot(0.5*(m+1.)*pi * p.y + (2.*m-1.) * time);
    p2.xz = abs(p2.xz) - 0.4 / l;
    
    // Dividing radius by l gives columns constant thickness
    float d = length(p2.xz) - 0.4 / l;
    
    // Remove sphere around camera
    d = -smin(-d, cd, 0.12);
    
    return vec2(0.8 * d, p.y);
}

vec3 march(vec3 ro, vec3 rd, float z) {    
    float d = 0.;
    float s = sign(z);
    int steps = 0;
    float mat = 0.;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        vec2 m = map(p);
        //m.x *= 0.8 + 0.2 * hash(hash(p.x,p.z), p.y); // for glow
        if (s != sign(m.x)) { z *= 0.5; s = sign(m.x); }
        if (abs(m.x) < SURF_DIST || d > MAX_DIST) {
            steps = i + 1;
            mat = m.y;
            break;
        }
        d += m.x * z; 
    }   
    return vec3(min(d, MAX_DIST), steps, mat);
}

vec3 norm(vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x);
    
    return normalize(n);
}

vec3 dir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

float shadow(in vec3 ro, in vec3 rd) {
    float res = 1.;
    float t = SURF_DIST;
    for (int i=0; i<24; i++)
    {
        float h = map(ro + rd * t).x;
        float s = clamp(32. * h / t, 0., 1.);
        res = min(res, s);
        t += clamp(h, 0.01, 0.2);
        if(res<SURF_DIST || t>MAX_DIST ) break;
    }
    res = clamp(res, 0.0, 1.0);
    return smoothstep(0., 1., res);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 ro = ori();
    
    vec3 rd = dir(uv, ro, vec3(0), 0.9);
    vec3 col = vec3(0);
   
    vec3 m = march(ro, rd, 1.);  
    float d = m.x;    
    vec3 p = ro + rd * d;
    
    if (d<MAX_DIST) {        
        vec3 n = norm(p);
        vec3 r = reflect(rd, n);        

        vec3 ld = normalize(vec3(1,2,3));
        float dif  = dot(abs(r),  ld)*.4+.6;
        float spec = pow(dif, 64.);
        
        col = vec3(dif);
        col *= vec3(1, 0.9 - 0.2 * abs(m.z),1);

        // Reflections
        //vec3 tx = texture(iChannel0, r).rgb;
        //col = max(tx, col);
        //col = max(col, spec);
        
        // Shadow
        col *= .8 + .2 * shadow(p + 6. * SURF_DIST * n, ld);
    }
     
    // Darken inner part
    float mx = 1./cosh(0.001*pow(dot(p,p), 4.));
    col = mix(col, 0.1 * vec3(1,0.8,0.9), mx);
    
    // Blend outer part with background
    float mx2 = 1./cosh(-0.00005*pow(dot(p,p), 3.));
    vec3 bgCol = 1.5 * sabs(rd);
    //bgCol *= texture(iChannel0, rd).rgb;
    bgCol = pow(bgCol, vec3(1./2.2));
    col = mix(bgCol, col, mx2);
    
    // Gamma correction (I prefer doing background only)
    col = pow(col, vec3(1./1.2));
    
    glFragColor = vec4(col,1.0);
}
