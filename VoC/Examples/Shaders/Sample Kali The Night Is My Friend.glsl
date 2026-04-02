#version 420

// original https://www.shadertoy.com/view/wdcGWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float det=.002;
const float maxdist=9.;
vec3 fcol;
// remove to use global time
//#define time iChannelTime[0] 

mat2 rot2D(float a) {
    float s=sin(a);
    float c=cos(a);
    return mat2(c,s,-s,c);
}

float de(vec3 p) {
    vec3 pos=p*2.;
    float sc=1.;
    for (int i=0; i<4; i++) {
        float x=fract(atan(p.y,p.x)/3.1416*5.)-.5;
        float y=length(p.xy)-2.5-step(118.,time)*2.;
        p=vec3(x,y,p.z)*1.5;
        p.yz*=rot2D(time*.2+time*smoothstep(35.,36.5,time));
        sc*=1.5;
    }
    fcol=abs(normalize(p.grb+pos))+sqrt(abs(p.y))*.5;
    fcol*=1.+sin(length(p)+time*10.);
    p/=sc;
    return min(length(p.xz)-.05,length(pos.xy)-1.5+pos.z*.1)*.5;
}

vec3 march(vec3 from, vec3 dir) {
    if (time>100. && time<118.) det+=.07;
    if (time>218. && time<236.) det+=.05;
    vec3 p, col=vec3(0.);
    float totdist=0., d;
    for (int i=0; i<200; i++) {
        p=from+totdist*dir;
        d=de(p);
        if (totdist>maxdist) break;
        totdist+=max(det,abs(d));   
        col+=fcol*pow(1.-totdist/maxdist,2.);
    }
    col*=.01;
    p=dir*maxdist;
    p*=.3;
    p+=.5;
    for (int i=0; i<9; i++) p=abs(p)/dot(p,p)-.8;
    col+=p*p*.005*abs(p.x)*step(det,.05);
    return col;
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 dir=normalize(vec3(uv,.7-fract(time*.88)*.6*step(154.,time)));
    vec3 from=vec3(sin(time),sin(time*.4)*2.,-4.);
    float a=fract(time*.22)*2.;
    from.yz*=rot2D(a);
    dir.yz*=rot2D(a);
    from.xy*=rot2D(time);
    dir.xy*=rot2D(time);
    vec3 col=march(from, dir)*mod(gl_FragCoord.y,3.)*.5;
    col+=smoothstep(1.8,2.,a);
    col*=smoothstep(0.,8.,time);
    if (time>36. && time<54.5) col=1.-col;
      col-=step(272.,time);
    col*=step(time,274.);
    glFragColor = vec4(col,1.0);
}
