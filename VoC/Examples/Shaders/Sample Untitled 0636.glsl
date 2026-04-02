#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(){
    
    vec2 r = resolution;
    float t = time;
    vec2 p=(.5-fract(mat2(cos(-t*.4+vec4(1,33,11,1)))*(gl_FragCoord.xy*2.-r)/min(r.y,r.x)))*2.4;
    float q=length(p),a=atan(p.y,p.x)*2.5+t*2.;
    glFragColor=vec4(mix(q*.9*step(q,min(abs(sin(a))+.4,abs(cos(a))+1.1)*.7),.7,step(q,.15)));
}
