#version 420

// original https://www.shadertoy.com/view/wty3DG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{   
    float speed = .1;
    float scale = 0.015;
    vec2 p = gl_FragCoord.xy * scale; 
    for(int i=1; i<17; i++){
        p.x+=(cos(time * 0.25)) * 0.75/float(i)*sin(float(i)*2.*p.y+time*speed)+ (time * 69.)/1000.;
        p.y+=cos(time) * 0.15/float(i)*cos(float(i)*5.*p.x+time*speed)+(time * .69)/1000.;
    }
    float r=cos(p.x+p.y+.025)*.9 + 0.33;
    float g=sin(p.x+p.y+1.)*.55+.5;
    float b=(sin(p.x * 1. +p.y)+cos(p.x+(p.y)))*.5+.28;
    vec3 color = vec3(b,g,r);
    color -= 0.002;
    glFragColor = vec4(color,1);
}
