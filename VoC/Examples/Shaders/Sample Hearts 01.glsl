#version 420

//--- hearts
// by Catzpaw 2016

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float heart(float x,float y){return (1e-10>pow(x*x+y*y-1.,3.)-x*x*y*y*y)?1.:0.;}

vec2 rot(vec2 p,float a){return p*mat2(cos(a),-sin(a),sin(a),cos(a));}

void main(void){
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y)*10.;
    uv=rot(uv,-time*.2);
    uv=mod(uv,3.)-1.5;
    uv=rot(uv,time*.2);
    float s=clamp(sin(time*6.)*1.2,1.,2.),c=heart(uv.x*s,uv.y*s);
    glFragColor = vec4(vec3(1,.1,.5)*c,1);
}
