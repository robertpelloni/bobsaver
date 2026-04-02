#version 420

// original https://www.shadertoy.com/view/wtGGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875

//-----------------UTILITY MACROS-----------------

#define time ((sin(float(__LINE__))*GR/2.0/PI+GR/PI)*time+100.0)
#define saw(x) (acos(cos(x))/PI)
#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)
#define rotatePoint(p,n,theta) (p*cos(theta)+cross(n,p)*sin(theta)+n*dot(p,n) *(1.0-cos(theta)))

//#define time (time*.1)

#define PI 3.14159265359

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy*2.0-1.0;
    uv.x *= resolution.x/resolution.y;
    
    //vec3 eye = vec3(0.0, 0.0, 3.0);
    vec3 eye = vec3(cos(time), sin(time*.5), sin(time))*2.0;
    vec3 look = vec3(0.0, 0.0, 0.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 foward = normalize(look-eye);
    vec3 right = normalize(cross(foward, up));
    up = normalize(cross(right, foward));
    vec3 ray = normalize(foward+uv.x*right+uv.y*up);
    
    glFragColor = vec4(0.0);
    
     const float outerCount = 10.0;
     const float innerCount = 8.0;
        
    float map = 0.0;
    float sum = 0.0;
    
    for(float i = 0.0; i < 10.0; i+=1.0)
    {
        if(i >= outerCount)
            break;
        
        float theta1 = i/outerCount*4.0*PI+time*PI*i/outerCount;
        
        for(float j = 0.0; j < 10.0; j+=1.0)
        {
            if(j >= innerCount)
                break;
            
            float theta2 = theta1+j/innerCount*PI*4.0+time*PI*j/innerCount;

                vec3 p1 = vec3(cos(theta1)*sin(theta2),
                           sin(theta1)*sin(theta2),
                           cos(theta2));
                           
                vec3 p2 = vec3(cos(theta1)*sin(theta2+PI/8.0),
                           sin(theta1)*sin(theta2+PI/8.0),
                           cos(theta2+PI/8.0));
            
            vec3 ray2 = normalize(p2-p1);
            
            float a = dot(ray,ray);
            float b = dot(ray,ray2);
            float c = dot(ray2,ray2);
            float d = dot(ray,eye-p1);
            float e = dot(eye-p1,ray2);
            
            float t1 = (b*e-c*d)/(a*c-b*b);
            float t2 = (a*e-b*d)/(a*c-b*b);
            
            float dist = length((eye+ray*t1)-(p1+ray2*t2));
            
            float lineWidth = 50.0/max(resolution.x, resolution.y);
            
            float lineLength = 1.5+.5*sin(time);
            
            if(t1 > 0.0 && abs(t2) < lineLength && dist < lineWidth)
            {
                float sides = (1.0-smoothstep(0.0, lineWidth, dist));
                float ends = (1.0-smoothstep(0.0, lineLength, abs(t2)));
                float line = sides*ends;
                
                map += line;
                sum += 1.0;
            }
        }
    }
    
    glFragColor = vec4(flux(PI*pow(map/sum, 1.0+.5*sin(-time/GR))+time), 1.0)*clamp(map, 0.0, 1.0);
}
