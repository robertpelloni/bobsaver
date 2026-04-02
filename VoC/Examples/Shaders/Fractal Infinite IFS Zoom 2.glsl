#version 420

// original https://www.shadertoy.com/view/ldfSDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// @acaudwell
// 2014

#define MAX_RAY_STEPS 48
#define KIFS_ITERATIONS 16

// uncomment to see how it works ...
//#define DEBUG

// enable ray sphere intersection test
#define INTERSECTION_TEST

#define COLOUR vec3(0.75, 1.0, 1.75)

#ifdef DEBUG
vec3 col1 = vec3(1.0, 0.0, 0.0);
vec3 col2 = vec3(0.0, 1.0, 0.0);
vec3 col3 = vec3(0.0, 0.0, 1.0);
vec3 col4 = vec3(1.0, 0.0, 1.0);
vec3 col5 = vec3(0.0, 1.0, 1.0);
#else
vec3 col  = COLOUR;
vec3 col1 = COLOUR;
vec3 col2 = COLOUR;
vec3 col3 = COLOUR;
vec3 col4 = COLOUR;
vec3 col5 = COLOUR;
#endif

mat4 calc_transform(vec3 offset, vec3 axis, float angle, float scale) {

    angle *= radians(1.0);

    float c = cos(angle);
    float s = sin(angle);

    vec3 t = (1.0-c) * axis;

    return mat4(
        vec4(c + t.x * axis.x, t.y * axis.x - s * axis.z, t.z * axis.x + s * axis.y, 0.0) * scale,
        vec4(t.x * axis.y + s * axis.z, (c + t.y * axis.y), t.z * axis.y - s * axis.x, 0.0) * scale,
        vec4(t.x * axis.z - s * axis.y, t.y * axis.z + s * axis.x, c + t.z * axis.z, 0.0) * scale,
        vec4(offset, 1.0)
    );
}

mat4 M = calc_transform(vec3(-0.4,-0.4,-0.4),normalize(vec3(1.0, 1.0, 1.0)), 40.0, 1.5);

float KIFS(vec3 p, float s) {
    
    p /= s;
    
    for(int i=0;i<KIFS_ITERATIONS;i++) {
        
        p = abs(p);
        
        // apply transform
        p = (M * vec4(p, 1.0)).xyz;
    }
    
    // divide by scale preserve correct distance
    return ((length(p)-1.0) * (pow(1.5, -float(KIFS_ITERATIONS))))*s;
}

vec3 dir;

bool intersect(vec3 p, float r) {

    float b = 2.0 * dot(dir, p);
    float c = dot(p, p) - r*r;

    float sq = sqrt(b*b - 4.0*c);

    float t1 = (-b + sq) * 0.5;
    float t2 = (-b - sq) * 0.5;

    float near = min(t1, t2);
    float far  = max(t1, t2);

    return near < far && far > 0.0;
}

void combineKIFS(vec3 p, float s, vec3 c, inout vec4 o) {

#ifdef INTERSECTION_TEST
    if(intersect(p, s*1.75)) {
#endif
                float d = KIFS(p,s);
                if(d<o.x) o = vec4(d,c);
#ifdef INTERSECTION_TEST
        }
#endif
}

#define SF 0.2

vec3 sp = normalize(vec3(-0.5,0.55,-0.5));

vec4 scene(vec3 p) {

        vec3 p1 = p - (sp + sp*SF);
        vec3 p2 = p - (sp + sp*SF*2.0 + sp*SF*SF);
        vec3 p3 = p - (sp + sp*SF*2.0 + sp*SF*SF*2.0 + sp*SF*SF*SF);
        vec3 p4 = p - (sp + sp*SF*2.0 + sp*SF*SF*2.0 + sp*SF*SF*SF*2.0 + sp*SF*SF*SF*SF);
        vec3 p5 = p - (sp + sp*SF*2.0 + sp*SF*SF*2.0 + sp*SF*SF*SF*2.0 + sp*SF*SF*SF*SF*2.0 + sp*SF*SF*SF*SF*SF);

        vec4 o = vec4(10000.0,vec3(0.0));

        combineKIFS(p1,SF,             col1, o);
        combineKIFS(p2,SF*SF,          col2, o);
        combineKIFS(p3,SF*SF*SF,       col3, o);
        combineKIFS(p4,SF*SF*SF*SF,    col4, o);
        combineKIFS(p5,SF*SF*SF*SF*SF, col5, o);
    
        return o;
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x = -uv.x;
    
    dir = normalize(vec3(uv.x, uv.y * (resolution.y/resolution.x), 0.8));
    
    
    float t = log(1.0 + 4.0*fract(time/2.0)) / log(5.0);
    
    float ratio = resolution.y/resolution.x;
    
    vec3 start = vec3(-0.01,0.175*ratio,-SF*1.5);
    start.y += sin(fract(time/2.0)*radians(360.0)) * SF * 0.01;
    start.x -= cos(fract(time/2.0)*radians(360.0)) * SF* 0.01;
    
    
    vec3 t1 = sp + sp*SF + start;
    vec3 t2 = sp + sp*SF*2.0 + sp*SF*SF + start * SF;
    
    vec3 cam = t1 + (t2-t1) * t;
    
    float d = 1.0;
    float ray_length = 0.0;
    
    int steps = 0;
    
    vec3 bg = vec3(0.0,2.0,2.0);
    
    vec3 c = bg * pow(length(vec2(uv.x,uv.y)*0.45),3.0);
    
    vec4 s = vec4(0.0);
    
    float lod = 0.56 /max(resolution.x,resolution.y);
    
    for(int i=0; i<MAX_RAY_STEPS; i++) {
        if(d<ray_length*lod) continue;
        s = scene(cam);
        d = s.x;
        cam += d * dir;
        ray_length += d;
        steps++;
    }
    
    if(ray_length<1.0) {
        c = s.yzw;
        
        float cost = float(steps)/float(MAX_RAY_STEPS);
        
        // cost based shading
        
        c *= pow(1.0 - cost,3.0);
        
        c /= 1.0- pow(1.0 - cost,27.0);
        
        c = clamp(c,0.0,1.0);
        
        c *= c;
        
        c += cost*0.05 * bg;
    }
    
    c *= 1.0+min(0.0,uv.y);
    
    glFragColor = vec4(c,1.0);
}
