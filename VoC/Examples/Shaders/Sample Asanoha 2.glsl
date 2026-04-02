#version 420

// original https://www.shadertoy.com/view/tsVyDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//---Asanoha
// by Catzpaw 2020

//UDF
float udSegment(vec2 p,vec2 a,vec2 b){
    p-=a,b-=a;return length(p-b*clamp(dot(p,b)/dot(b,b),0.,1.));
}
float udAsanoha(vec2 p){
    const float SR3=sqrt(3.);
    const vec2 p0=vec2(    0.,.0),
               p1=vec2(    0.,.5),
               p2=vec2(SR3/6.,.5),
               p3=vec2(SR3/2.,.5),
               p4=vec2(SR3/2.,.0),
               p5=vec2(SR3/3.,.0);
    p=abs(mod(p,vec2(SR3,1))-p3);
    return min(udSegment(p,p0,p1),
           min(udSegment(p,p0,p2),
           min(udSegment(p,p2,p3),
           min(udSegment(p,p0,p3),
           min(udSegment(p,p3,p4),
           min(udSegment(p,p3,p5),
               udSegment(p,p5,p0)))))));
}

//TEXTURE
const vec3 C1=vec3(0.4, 0.1, 0.2),
           C2=vec3(1.0, 0.6, 0.7);
vec4 txAsanoha(vec2 uv,float bold){
    return vec4(mix(C1,C2,smoothstep(.005*bold,.03*bold,udAsanoha(uv))),1);
}

//MAIN
mat2 rot(float a){float s=sin(a),c=cos(a);return mat2(c,s,-s,c);}
void main(void) {
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 p=uv*rot(sin(time*.02)*13.);
    float s=7.+sin(time*.17)*4.;
    glFragColor=txAsanoha(p*s,log(s)*.5);
    glFragColor.xyz*=1.-smoothstep(.2,1.3,length(uv));
}
