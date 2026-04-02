#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 64
#define MIN_DIST 0.002
#define MAX_DIST 32.0
#define NORM_OFFS 0.01

#define ORIENT_CAMERA

float tau = atan(1.0)*4.0;

mat2 Rotate(float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

//Hills
float Height(vec2 uv)
{
    float h = sin(uv.y*tau*0.08) * 1.6;
    h += sin(uv.y*tau*0.22 + 0.3) * 0.4;
    return h;
}

float Terrain(vec3 p)
{
    return p.z - Height(p.xy);
}

vec3 Normal(vec3 p)
{
    vec2 off = vec2(NORM_OFFS,0);
    return normalize(vec3(
        Terrain(p + off.xyy) - Terrain(p - off.xyy),
        Terrain(p + off.yxy) - Terrain(p - off.yxy),
        Terrain(p + off.yyx) - Terrain(p - off.yyx)
    ));
}

float March(vec3 orig, vec3 dir)
{
    float d = 0.0;
    float mul = 1.0;
     
    for(int i = 0;i < MAX_STEPS;i++)
    {
        float td = Terrain(orig + dir * d);
        
        td = min(td, -(length(dir * d) - MAX_DIST));
        
        d += td * mul;
        
        if(td < 0.0)
        {
            mul = 0.8;    
        }
        
        if(abs(td) < MIN_DIST)
        {
            break;    
        }
    }
    
    return d;
}

//Curves in the road.
float Road(float x)
{
    float t = sin(tau*x*0.05)*0.8;
    t += sin(tau*x*0.15 + 0.2) * 0.5;
    return t;
}

void main( void ) 
{
    vec2 aspect = resolution.xy / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.y - aspect/2.0;
    
    vec3 orig = vec3(0,0,0);
    orig.y = time * 2.2;
    orig.x = Road(orig.y);
    orig.z = Height(orig.xy)+0.1;
    
    vec3 dir = vec3(uv.x, 0.6, uv.y);
    
    #ifdef ORIENT_CAMERA
    vec3 slope = Normal(orig);
    float turn = (Road(orig.y) - Road(orig.y+0.5)) / 0.5;
    
    dir.yz *= Rotate(-atan(slope.z,slope.y)+3.14159/2.);
    dir.xy *= Rotate(-atan(turn));
    #endif
    
    vec3 p = orig + dir * March(orig, dir);
    vec3 n = Normal(p);
    vec3 c = vec3(0);
    
    float stripe = step(0.5,fract(p.y*4.0));
    float rd = abs(p.x - Road(p.y));
    
    //Grass
    vec3 c1 = vec3(0,1,0), 
         c2 = vec3(0,0.75,0);
    
    if(rd < 0.4)
    {
        //Curb
        c1 = vec3(0.9,0,0);
        c2 = vec3(0.9);
    }
    if(rd < 0.35)
    {
        //Pavement
        c1 = vec3(0.6);
        c2 = vec3(0.5);
    }
    if(rd < 0.01)
    {
        //Center line
        c1 = vec3(0.6);
        c2 = vec3(0.9);    
    }
    
    c = mix(c1, c2, stripe);
    
    c *= dot(n, normalize(vec3(0.4,0.4,1)));
    
    //Sky/Fog
    vec3 sky = mix(vec3(0.8,0.8,1), vec3(0.2,0.5,1), uv.y*2.0);
    
    c = mix(c, sky, length(p-orig)/MAX_DIST);

    glFragColor = vec4( vec3( c ), 1.0 );

}
