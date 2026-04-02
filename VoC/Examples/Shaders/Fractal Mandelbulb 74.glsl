#version 420

// original https://www.shadertoy.com/view/DlccRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AMBIENT vec3(.1)

#define LIGHT_POS vec3(3,5,-3)
#define LIGHT_COL vec3(1.0)

// Different maps. Uncommenting these will show different components of the final render.
//#define AO_MAP
//#define SHADOW_MAP
//#define LIGHT_MAP
//#define COLOR_MAP
//#define NORMAL_MAP
//#define POS_MAP

#define PI 3.14159265

// Data structures

struct MarchParams {
    int steps;
    float surf,miss;
};

struct Ray {
    vec3 o,d;
};
vec3 at(Ray r, float t) { return r.o+r.d*t; }

struct Interval {
    float start,end;
};

struct Material {
    vec3 col;
};

// Signed distance functions / ray-marching utils
float sdSphere(in vec3 p, in vec3 c, in float r) {
    return length(p-c)-r;
}
float sdBox( vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
#define MBULB_ITER 15
float sdMandelbulb(vec3 pos, out int iterations) {
    int Iterations = MBULB_ITER;
    float Bailout = 2.0;
    float Power = (time / 2.0) + 2.0;
    iterations = 0;

    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < Iterations ; i++) {
        r = length(z);
        if (r>Bailout) break;

        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;

        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;

        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
        ++iterations;
    }
    return 0.5*log(r)*r/dr;
}

vec3 translate(in vec3 p, in vec3 t) {
    return p-t;
}
vec3 repeatX(in vec3 p, in float size) {
    return vec3(p.x - size*round(p.x/size), p.yz);
}
vec3 repeatY(in vec3 p, in float size) {
    return vec3(p.x, p.y - size*round(p.y/size), p.z);
}
vec3 repeatZ(in vec3 p, in float size) {
    return vec3(p.xy, p.z- size*round(p.z/size));
}
vec3 rotateY(in vec3 p, in float angleRads) {
    float angle = atan(p.z, p.x) + angleRads;
    float dist = sqrt(p.x*p.x+p.z*p.z);
    return vec3(cos(angle)*dist, p.y, sin(angle)*dist);
}

float smin(float a, float b, float k) {
    return 0.5 * ((a + b) - sqrt((a-b)*(a-b)+k));
}

// RNG stuff
float hash( float n ) {
    return fract(sin(n)*43758.5453);
}

float lerp(float a, float b, float k) { return mix(a,b,k); }

float noise( vec3 x ) {
    // The noise function returns a value in the range -1.0f -> 1.0f
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
        lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
        lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
        lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

// Scene SDF
float map(in vec3 p, out Material mat) {
    mat.col = vec3(1.0);
    if (length(p) > 1.7) return length(p)-1.5;
    int iter;
    float fractal = sdMandelbulb(rotateY(p, time/6.0), iter);
    mat.col.x = 1.0-fractal;
    mat.col.y =(0.5-fractal) / length(p) * 2.0;
    mat.col.z = float(iter)/(float(MBULB_ITER)/3.0);
    mat.col *= .5;
    return fractal;
}

// Marching function
float march(in MarchParams p, in Ray r, in Interval i, out Material mat) {
    vec3 pos;
    float t = i.start;
    for (int stp = 0; stp < p.steps; ++stp) {
        pos = at(r,t);
        float scene = map(pos, mat);
        if (scene < p.surf || t > p.miss || t > i.end) return t;
        t += scene;
    }
    
    return t;
}

// Soft shadows
float shadow(in MarchParams p, in Ray r, in Interval i, in float lightSize) {
    float res = 1.0;
    float t = i.start;
    float maxt = i.end; // field selectors don't work in for loops ig
    for( int i=0; i<p.steps && t<maxt; i++ ) {
        Material _col;
        float h = map(at(r,t), _col);
        res = min( res, h/(lightSize*t) );
        t += clamp(h, 0.005, 0.50);
        if(res<-1.0) break;
    }
    res = max(res,-1.0);
    if (res != res) return 1.0;
    float final = 0.25*(1.0+res)*(1.0+res)*(2.0-res);
    return final;
}

// Ambient occlusion
float ambientOcc(vec3 point, vec3 normal, float step_dist, float step_nbr)
{
    float occlusion = 1.0f;
    while(step_nbr > 0.0) {
        Material _mat;
        occlusion -= pow(step_nbr * step_dist - (map( point + normal * step_nbr * step_dist, _mat)),2.0) / step_nbr;
        step_nbr--;
    }

    return occlusion;
}

// Get a normal
vec3 normal(in vec3 pos) {
    float epsilon = 0.005;
    Material _col;
    return normalize(
        vec3(
            map(pos + vec3(epsilon, 0, 0), _col) - map(pos - vec3(epsilon, 0, 0), _col),
            map(pos + vec3(0, epsilon, 0), _col) - map(pos - vec3(0, epsilon, 0), _col),
            map(pos + vec3(0, 0, epsilon), _col) - map(pos - vec3(0, 0, epsilon), _col)
        )
    );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2. - 1.;
    uv.y *= resolution.y / resolution.x;
    
    vec3 rayDir = normalize(vec3(uv, 1.0));
    MarchParams p = MarchParams(256, 0.0001, 1000.0);
    Ray r = Ray(vec3(0.0, 0.0, -3.), rayDir);
    Material mat;
    
    float dist = march(p, r,
        Interval(0.0, 1000.0), mat);
        
    bool hit = dist < p.miss;
    if (!hit) {
        glFragColor = vec4(AMBIENT, 1.0);
        return;
    }
    
    vec3 hitPos = at(r, dist);
    vec3 hitNorm = normal(hitPos);
    
    vec3 col = AMBIENT * mat.col;
    
    vec3 dirToLight = normalize(LIGHT_POS - hitPos);
    
    float lighting = max(dot(hitNorm, dirToLight), 0.0);
    float shadows  = shadow(p, Ray(hitPos, dirToLight), Interval(p.surf, 1000.0), 0.5);
    col += LIGHT_COL * mat.col * lighting * shadows;
    float ao = max(pow(ambientOcc(hitPos, hitNorm, .006, 20.0), 40.0), 0.1);
    col *= ao;

    glFragColor = vec4(col, 1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
    
#ifdef AO_MAP
    glFragColor = vec4(ao);
#endif

#ifdef SHADOW_MAP
    glFragColor = vec4(shadows);
#endif

#ifdef LIGHT_MAP
    glFragColor = vec4(lighting);
#endif

#ifdef COLOR_MAP
    glFragColor = vec4(mat.col, 1.0);
#endif

#ifdef NORMAL_MAP
    glFragColor = vec4(hitNorm, 1.0);
#endif

#ifdef POS_MAP
    glFragColor = vec4(hitPos, 1.0);
#endif
}