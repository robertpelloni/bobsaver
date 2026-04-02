#version 420

// original https://www.shadertoy.com/view/3ssBW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANGLE 2.5
#define DELTA 0.0135
#define XOFF .19

#define time time
mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}

float f(vec2 p, float featureSize)
{
    p.x = cos(p.x*1.6+time*0.2)*log(time+p.x*0.1)*2.;    
    p += sin(p.x*2.5)*2.1;
    return smoothstep(-0.01,featureSize,abs(p.y));
}

void main(void)
{
    float aspect = resolution.x/resolution.y;
    float featureSize = 170./((resolution.x*aspect+resolution.y));

    vec2 p = gl_FragCoord.xy / resolution.xy*2.5-1.25;
    p.x *= aspect;
    p.y = abs(p.y);
    
    vec3 col = vec3(0);
    for(float i=2.;i<36.;i+=.3)
    {
        vec3 col2 = (cos(vec3(4.5,2.5,3.6)-i*0.15)*0.5+0.24)*(1.-f(p,featureSize));
        col = max(col,col2);
        
        p.x -= XOFF;
        p.y -= tanh(time*0.31+1.5)*1.5+1.5;
        p*= mm2(i*DELTA+ANGLE);
        
        vec2 pa = vec2(abs(p.x-0.9),abs(p.y));
        vec2 pb = vec2(p.x,abs(p.y));
        
        p = mix(pa,pb,smoothstep(-.57,.67,cosh(time*2.14)-1.1));
    }
    glFragColor = vec4(col,.0);
}
