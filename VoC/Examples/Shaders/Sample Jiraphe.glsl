#version 420

// original https://www.shadertoy.com/view/7lsyRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define o(v2,deg) mod((v2)*rot(radians(deg)),60.0)-30.0;
#define hex() o1=o(p,0.);o2=o(p,60.);o3=o(p,120.);rgba-=clamp(vec4(abs(o1.y)+abs(o2.y)+abs(o3.y)-54.),0.,1.);
void main(void) {
	vec2 p=gl_FragCoord.xy;
    float itime;vec2 o1,o2,o3;
    vec2 R=resolution.xy;
    vec4 rgba=vec4(1,0.8,0.2,1);
    p-=R.xy/2.;p/=min(R.x,R.y)/360.0;
    p/=cos(length(p)/27.)/3.+2./3.;
    itime=time*16.;
    p+=itime; hex();
    p.y+=40.; hex();
    p.y+=40.; hex();
	glFragColor=rgba;
}
