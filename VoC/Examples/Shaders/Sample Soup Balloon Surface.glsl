#version 420

// original https://www.shadertoy.com/view/Wt2XDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float n(vec2 u){
    vec4 d=vec4(.106,5.574,7.728,3.994),q=u.xyxy+time*.1,p=floor(q);
    ++p.zw;
    q-=p;
    p=fract(p*d.xyxy);
    d=p+d.wzwz;
    d=p.xxzz*d.ywyw+p.ywyw*d.xxzz;
    p=fract((p.xxzz+d)*(p.ywyw+d));
    p=cos(p*=time+6.)*q.xxzz+sin(p)*q.ywyw;
    q*=q*(3.-2.*q);
    p=mix(p,p.zwzw,q.x);
    return mix(p.x,p.y,q.y);
}
void main(void) {
    vec2 p = gl_FragCoord.xy;
    float s;
    vec2 u=p/resolution.y;
    vec3 a=vec3(s=n(u*2.),n(u*6.+8.),n(u*3.+4.))*.6+.6,
    m=vec3(cos(s*=26.),s=sin(s)*.5774,-s);
    glFragColor=vec4(a*mat3(m+=(1.-m.x)/3.,m.zxy,m.yzx),1.0);    
}
