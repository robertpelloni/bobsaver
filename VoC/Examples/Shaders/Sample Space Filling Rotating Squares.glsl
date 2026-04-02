#version 420

// original https://www.shadertoy.com/view/7dfGWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){
float s = sin(a);
float c = cos(a);
return mat2(c,-s,s,c);
}
void main(void)
{    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv*=2.0+mod(floor(time/3.14159265359*2.0)*2.0,8.0);
    float t = time;
    vec2 ID = 1.-2.*mod(floor(uv),2.);
    uv = mod(uv,1.0)-0.5;
    uv*=rot(ID.x*ID.y*t)*(pow((-cos(t*4.0)*0.5+0.5),0.45)*(sqrt(2.0)-1.0)+1.0);
    vec2 S = smoothstep(-.005,.005,.5-abs(uv) );
    uv *= S.x*S.y;
    glFragColor = vec4(.5,.5,1,1)* S.x*S.y;  
}
