#version 420

// original https://www.shadertoy.com/view/wtSBzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float de(vec3 p) {
    float t=-sdTorus(p,vec2(2.3,2.));
    p.y+=1.;
    float d=100.,s=2.;
    p*=.5;
    for (int i=0; i<6; i++) {
        p.xz*=rot(time);
        p.xz=abs(p.xz);
        float inv=1./clamp(dot(p,p),0.,1.);
        p=p*inv-1.;
        s*=inv;
        d=min(d,length(p.xz)+fract(p.y*.05+time*.2)-.1);
    }
    return min(d/s,t);
}

float march(vec3 from, vec3 dir) {
    float td=0., g=0.;
    vec3 p;
    for (int i=0; i<100; i++) {
        p=from+dir*td;
        float d=de(p);
        if (d<.002) break;
        g++;
        td+=d;
    }
    return smoothstep(.3,0.,abs(.5-fract(p.y*15.)))*exp(-.07*td*td)*sin(p.y*10.+time*10.)+g*g*.00008;
}

void main(void)
{
    vec2 uv=gl_FragCoord.xy/resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    float t=time*.5;
    vec3 from=vec3(cos(t),0.,-3.3);
    vec3 dir=normalize(vec3(uv,.7));
    dir.xy*=rot(.5*sin(t));    
    float col=march(from,dir);
    glFragColor=vec4(col);
}
