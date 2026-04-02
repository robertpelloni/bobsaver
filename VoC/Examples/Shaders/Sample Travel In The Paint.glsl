#version 420

// original https://www.shadertoy.com/view/Mc2BRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 30
#define MAX_DIST 10.
#define SURF_DIST .01
#define t time

const float travleSpeed = .25;
const float paintSpeed = .5;
const vec3 paintCol = vec3(0.,1.,1.);
const vec3 backgroundCol = vec3(1., 0., 1.);

float opSmoothUnion( float d1, float d2, float k )
{
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

vec3 hash33(vec3 p)
{ 
    float offset = t * paintSpeed;
    float n = sin(dot(p, vec3(7, 157, 113)));    
    vec3 UV = fract(vec3(2152, 244, 378)*n); 
    return vec3(sin(UV.y*(offset+128.13))*0.5+0.5, cos(UV.x*(offset+578.57))*0.5+0.5, sin(UV.z*(offset+398.12))*0.5+0.5);
}

float voronoi(vec3 p)
{
    float s = length(p);
    s = smoothstep(1., -1., s);

    p.y += cos(t * travleSpeed);
    p.z += t * travleSpeed;
    
    vec3 b, r, g = floor(p);
    p = fract(p);

    float d = 1.; 
  
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            
            b = vec3(i, j, -1);
            r = b - p + hash33(g+b);
           // d = min(d, dot(r,r));
            d = opSmoothUnion( d, dot(r,r), .8);
            
            b.z = 0.0;
            r = b - p + hash33(g+b);
            d = opSmoothUnion( d, dot(r,r), .8);
            
            b.z = 1.;
            r = b - p + hash33(g+b);
            d = opSmoothUnion( d, dot(r,r), .8);
            
            d = max(d,s);            
        }
    }
    
    return d-0.1;
}

float RayMarch(vec3 ro, vec3 rd) 
{
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) 
    {
        vec3 p = ro + rd*dO;
        float dS = voronoi(p);
        dO += dS;
        //if(dO>MAX_DIST || abs(dS)<SURF_DIST) continue;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) 
{
    vec2 e = vec2(.1, 0);
    vec3 n = voronoi(p) - 
        vec3(voronoi(p-e.xyy), voronoi(p-e.yxy),voronoi(p-e.yyx));
    
    return normalize(n);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(0., 0., -0.5);
    vec3 rd = normalize(vec3(uv, 0.) - ro);
    
    float d;
    vec3 col;
    
    d = RayMarch(ro, rd);
    if(d < MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        
        float spec = pow(max(dot(normalize(vec3(.5)), r), 0.0), 128.);  
        float fre = dot(n, -rd)*.5+.5;
        
        d = 1.- pow(d, 2.)*.05;
        
        col = paintCol * (fre + spec*.5);
        //col += textureLod(iChannel0, r, 1.).rgb*.1;
        col = mix(backgroundCol, col, clamp(d, 0., 1.));
    }

    glFragColor = vec4(col, 1.);
}