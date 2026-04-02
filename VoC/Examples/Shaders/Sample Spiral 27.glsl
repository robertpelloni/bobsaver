#version 420

// original https://neort.io/art/bp80s043p9fd1psql2qg

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float tau = 2.*acos(-1.);

mat2 rot(float r){
    float c = cos(r), s = sin(r);
    return mat2(c,s,-s,c);
}

vec2 pmod(vec2 p, float r){
    float a = atan(p.x,p.y) + tau/r/2.;
    float n = tau/r;
    a = floor(a/n)*n;
    return p*rot(-a);
}

float sdCube(vec3 p,float r){
    vec3 q = abs(p)-r;
    return length(max(q,0.));
}

float map(vec3 p){
    vec3 q = p;
    q.z+=time;
    q.xy*=rot(q.z*.1-time*.2);
    q.xy = pmod(q.xy,5.);
    q.xz = fract(q.xz+.5)-.5;
    vec2 i = floor(q.xz+.5);
    q.y -= 5.+1.*sin(q.z*.5+time);
    return sdCube(q,.4);
}

float glow(vec3 ro, vec3 rd, float ma){
    float t,ac,d;
    ac = .0;
    t = .0;
    vec3 rp = ro;
    for(int i=0;i<24;i++){
        if(t>ma)break;
        d = map(rp);
        ac += exp(-d*1000.);
        rp += rd*d;
        t += d;
    }
    return ac;
}

void main(void){
    vec2 p = (2.*gl_FragCoord.xy - resolution.xy)/min(resolution.x,resolution.y);
    vec3 color = vec3(0.);
    
    float kt = time*.1;
    
    vec3 ro = vec3(0.,0.,-5.);
    vec3 ta = vec3(0.);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww,vec3(0.,1.,0.)));
    vec3 vv = normalize(cross(uu,ww));
    float sd = 1.;
    vec3 rd = normalize(uu*p.x+vv*p.y+ww*sd);
    vec3 rp = ro;
    //rp += rd;
    float d,t=0.;
    
    for(int i=0;i<64;i++){
        d = map(rp);
        rp += rd*d;
        t+=d;
    }
    color = vec3(glow(ro,rd,t))*.2*vec3(.25*sin(t+time*10.)+.25,.25*sin(t+time*2.)+.25,.25*sin(t+time*3.)+.25);
    
    glFragColor = vec4(color,1.);
}
