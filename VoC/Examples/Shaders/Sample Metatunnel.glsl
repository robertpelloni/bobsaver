#version 420

// original https://www.shadertoy.com/view/MdfSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by anatole duprat - XT95/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// http://www.pouet.net/prod.php?which=52777

float time2;

const float s=0.4; //Density threshold
 

//The scene define by density
float obj(vec3 p)
{
    float d = 1.0;
    d *= distance(p, vec3(cos(time2)+sin(time2*0.2),0.3,2.0+cos(time2*0.5)*0.5) );
    d  = distance(p,vec3(-cos(time2*0.7),0.3,2.0+sin(time2*0.5)));
    d *= distance(p,vec3(-sin(time2*0.2)*0.5,sin(time2),2.0));
    d *=cos(p.y)*cos(p.x)-0.1-cos(p.z*7.+time2*7.)*cos(p.x*3.)*cos(p.y*4.)*0.1;
    return d;
}
 

void main()
{
    time2 = time*.5;
    
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 v = -1.0+2.0*q;
    v.x *= resolution.x/resolution.y*.5+.5;
    
    vec3 o = vec3(v.x,v.y,0.0);
    vec3 d = normalize(vec3(v.x+cos(time2)*.3,v.y,1.0))/64.0;
    
    vec3 color = vec3(0.0);
    float t = 0.0;
    bool hit = false;
    
    for(int i=0; i<100; i++)
    {
        if(!hit)
        {
            if(obj(o+d*t) < s)
            {
                t-=5.0;
                for(int j=0; j<5; j++)
                    if(obj(o+d*t) > s)
                    t+=1.0;
                    
                vec3 e=vec3(0.01,.0,.0);
                vec3 n=vec3(0.0);
                n.x=obj(o+d*t)-obj(vec3(o+d*t+e.xyy));
                n.y=obj(o+d*t)-obj(vec3(o+d*t+e.yxy));
                n.z=obj(o+d*t)-obj(vec3(o+d*t+e.yyx));
                n = normalize(n);
                
                color = vec3(1.) * max(dot(vec3(0.0,0.0,-0.5),n),0.0)+max(dot(vec3(0.0,-0.5,0.5),n),0.0)*0.5;
                hit=true;
            }
            
            t+=5.0;
        }
    }
    glFragColor= vec4(color,1.)+vec4(0.1,0.2,0.5,1.0)*(t*0.025);
}
