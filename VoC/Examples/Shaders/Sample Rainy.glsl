#version 420

//--- rainy
// by Catzpaw 2017

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float x){return fract(sin(x*133.3)*13.13);}

void main(void){
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y);     
    vec3 c=vec3(.6,.7,.8);

    float a=-.4;
    float si=sin(a),co=cos(a);
    uv*=mat2(co,-si,si,co);
    uv*=length(uv+vec2(0,4.1))*.3+1.;

    float v=1.-sin(hash(floor(uv.x*100.))*2.);
    float b=clamp(abs(sin(20.*time*v+uv.y*(5./(2.+v))))-.95,0.,1.)*20.;
    c*=v*b;

    glFragColor = vec4(c,1);
}
