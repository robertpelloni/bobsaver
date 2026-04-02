#version 420

// original https://www.shadertoy.com/view/ss3XR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S smoothstep
#define P 3.14159265
mat2 r(float a){
    return mat2(cos(a),-sin(a),
                sin(a),cos(a));
}
float m (vec2 u, float t) {
    u *= r(t);
    return S(-P,P,sin(atan(u.x, u.y)*.25)*u.y/u.x)  * S(0.25, 1., 1. - length(u));
}
void main(void)
{
    vec2 R = resolution.xy;
    float t = time * .5;
    vec2 u = (gl_FragCoord.xy-.5*R)/R.y;
    float r = .25;
    float c1 = m(u+vec2(r,-r), sin(t)*P+P*-.25);
    float c2 = m(u+vec2(-r,-r), sin(t)*P+P*.25);
    float c3 = m(u+vec2(-r,r), sin(t)*P+P*.75);
    float c4 = m(u+vec2(r,r), sin(t)*P+P*-.75);
    vec3 C = vec3(
        c1*vec3(1,0,0)+ 
        c2*vec3(1,1,0)+
        c3*vec3(0,1,1)+
        c4*vec3(1,0,1)
    );
    
    glFragColor = vec4(C, 1.0);
}
