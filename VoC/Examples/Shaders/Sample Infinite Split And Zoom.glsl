#version 420

// original https://www.shadertoy.com/view/3d2BRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ayquo 2020
// RayMarching starting point by https://www.shadertoy.com/view/WtGXDD

#define MAX_STEPS 100
#define MAX_DIST 400.
#define SURF_DIST .001
#define ZOOM_LAYERS 4.
#define BASE_COLOR vec3(.2, .1, .5)
#define CUBE_OFFSET_COUNT 26

mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s*.5;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

// Create multiple copies of an object - http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec3 opRepLim( in vec3 p, in float s, in vec3 lima, in vec3 limb )
{
    return p-s*clamp(round(p/s),lima,limb);
}

float getDistCubes(vec3 p, float layer, float scale, float tx) {
    vec3 dim = vec3(scale);
    float f = (1.+tx+layer)*scale;
    vec3 pr = opRepLim(p, f, vec3(-1,-1, -1), vec3(1,1,1));    
      float r = sdBox(pr, dim);
    if (layer>0.)
    {
        r = max(r, -sdBox(p, dim*1.1));
    }
    return r;    
}

float getDist(vec3 p, float tx) {
    float r = MAX_DIST;
    for (float layer=0.; layer<ZOOM_LAYERS; layer+=1.)
    {    
        r = min(r, getDistCubes(p, layer, mix(1., 3., tx)*pow(3., layer), tx));
    }    
    return r;
}

float rayMarch(vec3 ro, vec3 rd, float tx) {
    float dO=0.;    
    vec3 p;
    float dS;
    for(int i=0; i<MAX_STEPS; i++) 
    {
        p = ro + rd*dO;
        dS = getDist(p, tx);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }    
    return dO;
}

vec3 getNormal(vec3 p, float tx) {
    float d = getDist(p, tx);
    vec2 e = vec2(.001, 0);    
    vec3 n = d - vec3(
        getDist(p-e.xyy, tx),
        getDist(p-e.yxy, tx),
        getDist(p-e.yyx, tx)
    );    
    return normalize(n);
}

vec3 getRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
    r = normalize(cross(vec3(0,1,0), f)),
    u = cross(f,r),
    c = p+f*z,
    i = c + uv.x*r + uv.y*u,
    d = normalize(i-p);
    return d;
}

void main(void)
{
    float t = time*.25;
    float tm = mod(t, 1.);
    float tx = (tm*tm*2.+tm*3.)/5.;    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;   
    vec3 cp = vec3(3., 2, -1) * 3.;
    cp.xy *= rot(t/2.);
    vec3 ro = cp;    
    vec3 rd = getRayDir(uv, ro, vec3(0), 1.);
    float d = rayMarch(ro, rd, tx);    
    vec3 col = BASE_COLOR;    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p, tx);        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col += dif;  
    }

    // Fog
    col *= clamp(exp( -0.0008 * d * d * d ), 0.02, 1.); // Near
    col *= clamp(exp( -0.00008 * d * d), 0.02, 1.); // Far
    
    // Gamma correction
    col = pow(col, vec3(.4545));    
   
    glFragColor = vec4(col,1.0);
}
