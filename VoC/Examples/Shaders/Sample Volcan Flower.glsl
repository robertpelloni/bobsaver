#version 420

// original https://www.shadertoy.com/view/Xl2BRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159235659

float def(in vec2 uv,float f);
void main(void)
{
    
    float time = time;
    vec2 uv = gl_FragCoord.xy / resolution.xy;;
    vec2 p = vec2(0.5)-uv;
    float ra = length(p);
    float a = atan(p.x,p.y);

    float e = sin(uv.x*PI*10.+time+sin(uv.y*PI*10.)+0.03)*sin(a*1.+sin(ra*PI*5.+time*4.)*0.1+time)*sin(ra*PI*5.+time)*sin(sin(a*5.)*sin(ra*PI*5.-time)*0.5);

    float r = def(uv,PI)*3.*(1.-ra*2.)  ;
    float g = def(uv,PI+PI/18.)*0.5 ;
    float b = def(uv,PI-PI/18.)*0.5;

glFragColor = vec4(r,g,b, 1.0);

}
float def(in vec2 uv,float f){
    
float time = time;
vec2 p = vec2(0.5)-uv;
float a = atan(p.x,p.y);
float r =length(p);

float e3 = sin(uv.x*PI*10.+time+sin(a*10.)*3.)*0.03;
float e2 = sin(r+sin(e3*PI+time*0.7)*0.1);
float e = sin(sin(a*5.)*sin(e2*PI*4.+time)+f+PI*1.5+sin(time)+0.01);
e = sin(e*PI);
return e;
}
