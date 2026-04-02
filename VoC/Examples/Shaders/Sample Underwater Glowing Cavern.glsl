#version 420

// original https://www.shadertoy.com/view/wdjGzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SCALE(p, f) (p) *= vec3(1./(f))
#define TRANSLATE(p, v) (p) += vec3(-1. * v)

#define MAX_STEPS 64

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdfFloor(vec3 p)
{
    return p.y;
}

float random(vec2 uv)
{
    return fract(sin(dot(uv ,vec2(122.9898,78.233))) * 43758.5453);
}

float map(vec3 p)
{
    p.z -= time*2.;
    p.y += .7 + sin(time)*.5;
    p.x -= 4.5;
    float floorPlane = sdfFloor(vec3(p.x, sin(p.x)*.4+sin(p.y+1.)+.05+cos(p.z)*.2, 1.));
    
    p.x = mod(p.x+5., 12.)-5.;
    p.z = mod(p.z, -20.);
    float sphere = sdfSphere(p-vec3(0.0, 0.0, -5.0), 1.);
    float smallSphere = sdfSphere(p-vec3(1.0, -.8, -5.0), .2);
    float bigSphere = sdfSphere(p-vec3(2., 2., -7.0), 3.);
    
    vec3 pHoles = p;
    pHoles.x = mod(pHoles.x-.2, -.4)+.2;
    pHoles.y = mod(pHoles.y-.2, -.4)+.2;
    pHoles.z = mod(pHoles.z-.2, -.4)+.2;
    float holes = sdfSphere(pHoles-vec3(0., 0., 0.), .15);
   
    floorPlane = max(floorPlane, holes);
    float spheres = min(min(min(sphere, smallSphere), bigSphere), floorPlane);
    
    return spheres;
}

float rayMarch(vec3 ro, vec3 rd)
{
    float dst = 0.0;
    for(int i=0; i<MAX_STEPS; ++i) {
        float d = map(ro + rd*dst);
        if(d < .001*dst || d > 10000.0) return dst;
        dst += d;
    }
    return dst;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x/resolution.y;
    
       float dst = rayMarch(vec3(0.0), normalize(vec3(uv.x, uv.y, -1.0)));
    
    // TODO 100 is arbitrary
    vec3 col = vec3(dst/100.);
    
    col = pow(col, vec3(.3));
    col = 1.0-col;
    col.r = pow(col.r, pow(dst, 1.));
    col.r += pow(col.r, .2);
    col.g += pow(col.g, sqrt(dst));
    
    glFragColor = vec4(col,1.0);
}
