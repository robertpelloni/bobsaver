#version 420

// original https://www.shadertoy.com/view/wtBGzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

Live streamed on twitch: https://www.twitch.tv/nusan_fx
Made originally with Kodelife

*/

//float time=0.0;
float bpm=0.0;

float knobtime(int x) {return time*4.0;}
float key(float x) {return clamp((sin(x*3.0 - time)-0.97)*100.0,0.0,1.0);}

//////////// GEOMETRY ////////////

float pi=acos(-1.0);

float sph(vec3 p, float s) {return length(p)-s;}
float cyl(vec2 p, float s) {return length(p)-s;}
float boxgrid(vec3 p, vec3 s, vec3 r) {p=abs(p)-s; p=abs(max(p,p.yzx))-r; return max(p.x,max(p.y,p.z));}
float boxgrid(vec3 p, float s, float r) {return boxgrid(p, vec3(s), vec3(r));}
float octa(vec3 p, float s) { p=abs(p); return dot(p,normalize(vec3(0.7)))-s;}

//////////// MORPH ////////////

float rnd(float t) { return fract(sin(t*758.655)*352.741); }
float curve(float t, float d) { t/=d; return mix(rnd(floor(t)), rnd(floor(t)+1.0), pow(smoothstep(0.0,1.0,fract(t)), 10.0)); }

mat2 rot(float a) {
    float ca=cos(a);
    float sa=sin(a);
    return mat2(ca,sa,-sa,ca);
}

mat3 rotaxis(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

float noise(vec3 p) {
    vec3 ip=floor(p);
    p=fract(p);
    p=smoothstep(0.0,1.0,p);
    vec3 st=vec3(7,137,233);
    vec4 val=dot(ip,st) + vec4(0,st.y,st.z,st.y+st.z);
    vec4 v=mix(fract(sin(val)*9853.241), fract(sin(val+st.x)*9853.241), p.x);
    vec2 v2=mix(v.xz,v.yw,p.y);
    return mix(v2.x,v2.y,p.z);
}

#define repeat(VALUE,DISTANCE) (fract((VALUE)/DISTANCE+0.5)-0.5)*DISTANCE
#define repid(VALUE,DISTANCE) (floor((VALUE)/DISTANCE+0.5)-0.5)

//////////// PALETTES ////////////

float pulse(float t, float s) {
    float v=smoothstep(0.0,1.0,fract(t));
    return mix(v,1.0-v,pow(v,s));
}
float pulse(float t) { return pulse(t,8.0); }

float ipulse(float t, float s) {
    return 1.0-pulse(t,s);
}

float ipulse(float t) { return ipulse(t,8.0); }

vec3 tweakcolor(vec3 col) {
    col *= rotaxis(vec3(1), time*0.2);
    //col = mix(vec3(dot(col, vec3(0.7))), col, 1.0);
    col *= 0.4;
    col *= pow(col, vec3(1.3));

    return col;
}

//////////// SHADING ////////////
float map(vec3 p);

vec3 getnorm(vec3 p) {
    vec2 off=vec2(0.1,0);
    return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

float getao(vec3 p, vec3 n, float d) {
    return clamp(map(p+n*d)/d,0.0,1.0);
}

float getsss(vec3 p, vec3 r, float d) {
    return clamp(map(p+r*d),0.0,1.0);
}

//////////// TUNNEL ////////////

vec3 tunnel(vec3 p) {
    float t=knobtime(0)*0.1;
    vec3 off=vec3(0);
    off.x += sin(p.z*0.01 + t + 12.3)*60.0;
    off.y += sin(p.z*0.012 + t)*50.0;
    return off;
}

//////////// MAP ////////////

vec2 fractal(inout vec3 p) {

    float s=10.0;
    float mm=10000.0;
    float id=0.0;
    for(int i=0; i<4; ++i) {
        float t=knobtime(3)*0.2 + float(i);//curve(time, 0.3+i*0.3);;
        p.xy *= rot(t);
        p.yz *= rot(t*0.7);    
        id += dot(sign(p), vec3(1,1.7,2.3));
        p=abs(p);
        mm=min(mm, min(p.x,min(p.y,p.z)));
        p-=s;
        s*=0.5;
    }

    return vec2(mm, id);
}

// KODELIFE

float oo = 0.0;
vec3 trp=vec3(0);
float tra=0.0;
float map(vec3 p) {

    float tt = knobtime(0);
    
    vec3 bp=p;
    
    p.xz*=rot(time*0.1);
    p.xy*=rot(time*0.12);
        
    vec2 mm = fractal(p);
    
    float d = abs(mm.x)-0.3;
    float dist = rnd(mm.y);

    float t1 = max(d,sph(bp, 60.0));
    float t2 = sph(bp, 40.0 + sin(tt*0.1+dist*32.0 + pow(fract(bpm),5.0))*20.0);
    t2 = abs(t2)-0.3;
    t2 = max(t2, -d+0.3);
    
    d=min(t1, t2);
    
    p=bp;
    
    p+=tunnel(p);
    
    vec3 bp2 = p;
    
    p.xy *= rot(sin(p.z*0.01 + tt*0.1));
    p.yz *= rot(sin(p.z*0.01 + tt*0.1)*0.3);
    p+=noise(p*0.02)*30.0;
    p=repeat(p, 40.0);
    float t3 = boxgrid(p, 7.0, 0.2);
    t3 = min(t3, cyl(p.xy, 1.0));
    t3 = min(t3, cyl(p.yz, 1.0));
    t3 = min(t3, max(abs(cyl(bp.xy, 100.0 + sin(tt*0.3 + bp.z*0.05)*20.0))-3.0, abs(p.z)-0.4)*0.7);
    t3=max(t3, -cyl(bp.xy, 80.0)); 
    
    d=min(d, t3);
    
    float t5=abs(octa(bp2, 120.0))-1.0;
    t5 = max(t5, mm.x-0.2);
    oo+=0.2/(0.2+t5);
    d=min(d, t5);
    
    
    tra=(t1<=d)?1.0:0.0;
        
    return d;
}

vec3 sky(vec3 r) {
    vec3 col=vec3(0);
    vec3 rr = abs(repeat(r,0.1))*13.0;
    col += max(rr.z,rr.y);
    col *= pow(abs(r.x),10.0);
    return col;
}

vec3 raymarch(vec2 uv) {
    vec3 col = vec3(0);
    
    vec3 s=vec3((curve(time, 0.7)-.5)*5.0,0,-150.0);
    vec3 t=vec3(0,0,0);
    
    s -= tunnel(s);
    t -= tunnel(t);
    
    vec3 cz=normalize(t-s);
    vec3 cx=normalize(cross(cz, vec3(sin(time*0.1)*0.1,1,0)));
    vec3 cy=normalize(cross(cz, cx));
    
    float fov = 0.3 + pulse(bpm*0.5,20.0)*0.2;
    vec3 r=normalize(uv.x*cx + uv.y*cy + fov*cz);
    
    float maxdist=300.0;
        
    vec3 p=s;
    float at=0.0;
    float dd=0.0;
    for(int i=0; i<200; ++i) {
        float d=map(p);
        if(d<0.001) {
            if(tra>0.5) {
                //vec3 n=getnorm(p);
                float didi = 1.0-length(p)/60.0;
                col += vec3(0.0002*float(i)*didi,0,0);
                d=0.2;
            } else {
                break;
            }
        }
        if(dd>maxdist) break;
        p+=r*d;
        dd+=d;
        at += (1.0-tra)*1.0/(1.0+d);
    }

    float fog = 1.0-clamp(dd/maxdist,0.0,1.0);
    
    vec3 n=getnorm(p);
    vec3 l=normalize(vec3(1,3,-2));
    vec3 h=normalize(l-r);
    float spec=max(0.0,dot(h,n));
    float fres=pow(1.0-abs(dot(r,n)), 3.0);
    
    vec3 col1 = vec3(0.7,0.8,0.6);
    vec3 col2 = vec3(0.8,0.8,0.5)*3.0;
    float iter = pow(abs(r.z), 7.0);
    vec3 atmocol = mix(col1, col2, iter);
    
    float ao=1.0;//getao(p,n,3.0) * getao(p,n,1.5) * 3.0;
    float sss=getsss(p,r,2.0) + getsss(p,r,10.0);
    
    float fade = fog * ao;
    col += (max(0.0,dot(n,l)) * .5+.5) * 0.7 * fade * atmocol * 0.2;
    col += max(0.0,dot(n,l)) * (0.3 + 0.6*pow(spec,4.0) + 0.9*pow(spec,30.0)) * fade * atmocol*0.7;
    col += pow(1.0-fog,5.0) * vec3(0.7,0.5,0.2);
    col += pow(oo*0.15,0.7)*vec3(0.5,0.7,0.3);
    
    col += pow(at*0.035,0.4) * atmocol;

    col += key(fract(length(p)*0.02)) * vec3(0.2,1.0,fract(trp.x*0.1)) * 10.0 * fog;
    col *= 1.8,

    col = tweakcolor(col);
    
    col *= 1.2-length(uv);
    
    return col;
}

void main(void)
{
    //time=time;
    bpm=time*90.0/60.0;
    vec2 uv = -0.5 + 1. * gl_FragCoord.xy/resolution.xy;
    uv.y=-uv.y;
    uv.x *= resolution.x/float(resolution.y);

    vec2 buv=uv;
    
    vec3 col=vec3(0);
    col += raymarch(uv);
 
    col *= 1.2-length(buv);
  
    glFragColor = vec4(col,1.0);
}
