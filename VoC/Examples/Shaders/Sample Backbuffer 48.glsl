#version 420

//--- kamaitachi
// by Catzpaw 2017

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 hsv2rgb(vec3 hsv){return ((clamp(abs(fract(hsv.x+vec3(0.,2.,1.)/3.)*6.-3.)-1.,0.,1.)-1.)*hsv.y+1.)*hsv.z;}
mat2 rot(float a){float si=sin(a),co=cos(a);return mat2(co,-si,si,co);}
float hash(vec2 p){return fract(sin(p.x*312.1+p.y*13.7)*4137.13);}

float f(vec2 p,float a){
    p*=rot(a*6.10);p.x+=.25;
    p*=rot(a*-1.17);p.x+=.1;
    p*=rot(a*2.61);p.x+=.15;
    return clamp(1.-length(p)*14.-hash(p+a+1e4)*.2,0.,1.);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy/resolution.xy)-.5;
    vec4 back=texture2D(backbuffer,uv+.5);
    uv.x *= resolution.x/resolution.y;

    float v = 0.;
    v+=f(uv,time);
    v+=f(uv,time+2.094);
    v+=f(uv,time+4.188);
    v=clamp(v,0.,1.);

    back.b*=.99;
    if(back.b<.04)back.r*=.94;
    if(back.r<.8)back.g*=.99;

    vec3 c=hsv2rgb(vec3(time*3.,.6,v))+back.rgb-.005;
    glFragColor = vec4(c,1);
}
