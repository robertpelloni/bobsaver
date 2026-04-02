#version 420

// original https://www.shadertoy.com/view/ltfGD4

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(){
    float t=time, a=sin(t), b=cos(t);
    mat3  R=mat3(a,b*b,b*a,0,a,-b,-b,a*b,a*a);
    vec3  o=vec3(0,0,-7)*R, d=normalize(vec3(gl_FragCoord.xy/resolution.y,1.8)-.5)*R;
    for(int i=0;i<9;i++) o+=d*(a=length(max(abs(o)-1.+b*b,0.))-1.3*b*b);
    glFragColor.rgb = a<1.?cos(o):d*d;
}
