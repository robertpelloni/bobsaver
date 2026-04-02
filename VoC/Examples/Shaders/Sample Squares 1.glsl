#version 420

// original https://www.shadertoy.com/view/ldscD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Do not redistribute.

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875

//-----------------UTILITY FUNCTIONS--------------

float saw(float x)
{
    float f = mod(floor(abs(x)), 2.0);
    float m = mod(abs(x), 1.0);
    return f*(1.0-m)+(1.0-f)*m;
}
vec2 saw(vec2 x)
{
    return vec2(saw(x.x), saw(x.y));
}

vec3 saw(vec3 x)
{
    return vec3(saw(x.x), saw(x.y), saw(x.z));
}

vec4 saw(vec4 x)
{
    return vec4(saw(x.x), saw(x.y), saw(x.z), saw(x.w));
}

//-----------------UTILITY MACROS-----------------

#define time ((.125-.25*saw(float(__LINE__)*PI*GR*E)/PI/GR/E)*time+1000.0)
#define sphereN(uv) (clamp(1.0-length(uv*2.0-1.0), 0.0, 1.0))
#define clip(x) (smoothstep(0.25, .75, x))
#define TIMES_DETAILED (1.0)
#define angle(uv) (atan(uv.y, uv.x))
#define angle_percent(uv) ((angle(uv)/PI+1.0)/2.0)

#define flux(x) (vec3(cos(x*2.0*PI),cos(4.0*PI/3.0+x*2.0*PI),cos(2.0*PI/3.0+x*2.0*PI))*.5+.5)
#define circle(x) (vec2(cos((x)*2.0*PI),sin(2.0*PI*(x))))

#define rotatePoint(p,n,theta) (p*cos(theta)+cross(n,p)*sin(theta)+n*dot(p,n) *(1.0-cos(theta)))
#define ZIN (vec3(0.0, 0.0, 1.0))

vec2 remap(vec2 uv, vec4 start, float r1, vec4 end, float r2)
{
    
    vec3 c1 = vec3(start.xy, 0.0);
    vec3 d1 = vec3(start.zw, 0.0);
    
    vec3 c2 = vec3(end.xy, 0.0);
    vec3 d2 = vec3(end.zw, 0.0);    

    uv = (rotatePoint(vec3(uv, 0.0)-c1, ZIN, r1).xy*d1.xy);
    uv = (rotatePoint(vec3(uv, 0.0)-c2, ZIN, r2).xy*d2.xy);
    
    
    return uv;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float scale = GR;
    uv = uv*scale-scale/2.0;
    
    float aspect = resolution.x/resolution.y;
    
    uv.x *= aspect;
    
    vec2 uv0 = uv;
    
    const int max_i = 8;
    
    float map = 1.0;
    float detail = 1.0;

    vec4 start = vec4(circle(time)*0.5+1.0,
                     vec2(sin(time*2.0+PI)*0.1+1.0));
    vec4 end = vec4(circle(time)*0.5+1.0,
                    vec2(1.0));
    
    for(int i = 0 ; i < max_i; i++)
    {
        map *= (smoothstep(0.0, 1.0/PI/GR, abs(uv.y-uv.x)));
        float j = float(i)/float(max_i-1);
        
        float theta1 = time;
        float theta2 = time;
        vec2 last = uv;
        uv = (remap(uv, start, theta1, end, theta2));
        uv = saw(uv/2.0)*2.0-1.0;
    }
      map = pow(map, 1.0/float(max_i));
    float b = 1.0-smoothstep(0.0, 1.0/PI, map);
    glFragColor = vec4(saw(uv), 0.0, 1.0);
    glFragColor = vec4(flux(map), 1.0);
}
