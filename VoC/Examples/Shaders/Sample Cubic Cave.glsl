#version 420

// original https://www.shadertoy.com/view/ssySDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define U (10.)
#define Y (2.)
#define dd(a) (floor(clamp((a),-1.+Y*(1./U),1.-Y*(1./U))*U)*(1./U))
#define r(a) (mat2(cos(a),sin(a),-sin(a),cos(a)))
void main(void) {
	vec4 e;
    vec3 d=vec3((gl_FragCoord.xy-resolution.xy*.5)/resolution.y,.3),p;
    d.yz*=r(time*.2); d.xz*=r(time*.2);
    for(float o,i=0.;i<53.;i++){
        o=1.2-length(dd(cos(p.xy))+dd(sin(p.yz-vec2(-1.,time*5.))));
        p+=(o-.01)*d;
        e.xyz+=vec3(.3,.3,.3)*(.0009/clamp(abs(o),.01,9.));
    }
	glFragColor=e;
}
