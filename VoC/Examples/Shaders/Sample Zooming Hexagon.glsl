#version 420

// original https://www.shadertoy.com/view/Wtc3WS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 Rot (float a)
{
 float s = sin(a);
 float c = cos(a);
 return mat2(c,-s,s,c);      
}

float hex (vec2 p)
{
 p = abs(p);
 //p *= (Rot ((((floor(p.y*10.)))*0.5+sin(time))*1.));
 //p *= (Rot ((((floor(p.x*5.)))+cos(time))*.5));
 float c = dot(p,normalize(vec2(1,1.73)));
 c = max(c,p.x);
 return c;
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
 uv *= 10.;   
        
 uv = abs (uv)-0.5;   
    
uv *= (Rot ((sin(time)*+1.5)));
    
    
 float c = tan(hex(uv)*1.+time);   
 vec3 col = vec3(step(c,.01));
 glFragColor = vec4(col,1.0);
}
