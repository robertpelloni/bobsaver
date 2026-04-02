#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define PI 3.141592653589793238462643383
float chessDist(vec2 uv){return max(abs(uv.x),abs(uv.y));}
float heart(vec2 uv){uv*=vec2(1.05,1.21);return length(uv-vec2(0.,(pow(abs(uv.x),.8)/2.55)-(length(uv)/5.6)));}
float rand(vec2 uv){return fract(sin(dot(uv+.52,uv-.51)*3226.62)*2423.52);}
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

vec3 d(vec2 uv,float time){
    vec3 c=vec3(.1);
    vec2 p=vec2(cos(time*6.)*1.5,sin(time)/2.)*.1;
    vec2 up=(uv-p)/(1.5+(sin(time*.5)*.3));
    up*=rot(sin(time*6.)*.1);
    float px=100.;
    c=mix(c,vec3(1.),(chessDist(up)<.175)?1.:0.);
    c=mix(c,vec3(.2,.5,.0),((length((floor(up*px)+.5)/px)<.1)||(rand(floor(up*px))>=.5&&(chessDist(up)<.15)))?1.:0.);
    c=mix(c,vec3(.85,.17,.1),(heart(up/.35)<.15)?1.:0.);
    return c;
}

void main(void){
    vec2 uv=(gl_FragCoord.xy/resolution.xy)-.5;uv.x*=resolution.x/resolution.y;
    vec3 c=vec3(0.);
    #define ITER 16
    for(int i=0;i<ITER;i++){
        c+=d(uv+(vec2(cos((float(i)/float(ITER)*PI*2.)),sin((float(i)/float(ITER))*PI*2.))*.001*rand(uv)),time+((rand(uv+float(i))-.5)*.02));
    }
    c/=float(ITER);
    glFragColor=vec4(c,1.);
}
