#version 420

// original https://www.shadertoy.com/view/MdfBDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct M{float d;vec3 c;};
float C,S;
#define rot(a) mat2(C=cos(a),S=sin(a),-S,C)
#define t time

M mmin(M a,M b,float k){
    float h=clamp((b.d-a.d)/k*.5+.5,0.,1.);
    M m;
    m.d=mix(b.d,a.d,h)-k*h*(1.-h);
    m.c=mix(b.c,a.c,h);
    return m;
}

M map(vec3 p){   
    p.y-=.1*sin(t*5.)-.2;
    p.xz*=rot(t);
    float a=atan(p.z,p.x);
    float d=dot(normalize(vec2(.9,-.2)),vec2(length(p.xz),p.y+2.));
    d=max(d,p.y-1.);
    M m;
    m.d=d;
    vec2 st=fract(vec2(a/6.2831*10.+p.y*1., a/6.2831*2.-p.y*4.));
    st*=(1.-st);
    m.c=mix(vec3(.8,.4,.0),vec3(.9,.8,.0),pow(st.x*st.y*15.,.5));
    d=length(p.xz)-(.8+.1*sin(a*8.+p.y*15.-.5))*(smoothstep(.5,1.,p.y)-smoothstep(1.5,3.,p.y));
    M m2;
    m2.d=d;
    m2.c=mix(vec3(.9),vec3(.9,.1,.1),step(.5,fract(a/6.2831*4.+p.y/6.2831*7.5)));
    m=mmin(m,m2,.1);
    return m;
}

vec3 hsv(float h,float s,float v){
    vec3 k=vec3(3.,2.,1.)/3.,
        p=abs(fract(h+k.xyz)*6.-3.);
    return v*mix(k.xxx,clamp(p-1.,0.,1.),s);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy,v=uv*(1.-uv);
    uv-=.5;
    uv.x*=resolution.x/resolution.y;
    
    vec3 ro=vec3(uv,-5.),rd=normalize(vec3(uv,1.)),mp=ro;
    M m;
    float f;for(f=0.;f<30.;++f){
        m=map(mp);
        if(abs(m.d)<.001)break;
        mp+=rd*m.d;
    }
    float mbg=min(1.,length(mp-ro)*.01);
    float a=atan(uv.y+.8,uv.x)/6.2831*40.+time;
    vec3 bg=mix(vec3(.0,.4,.8),vec3(.1,.5,.9),step(.5,fract(a)))*2.;
    vec3 c=mix(m.c*vec3(1.-f/30.)*1.2,bg,mbg);
    for(f=0.;f<40.;++f){
        vec4 h=fract(sin(f+vec4(0.,3.,5.,8.))*1e4);
        h.y=fract(h.y-t*.1);
        vec3 p=(h.xyz-.5)*8.;
        p.xz*=rot(t*.7);
        float l=length(cross(p-ro,rd));
        c+=.01/l/l*hsv(h.w,1.,1.);
    }
    c=sqrt(c)*pow(v.x*v.y*20.,.6);
    glFragColor = vec4(c,1.0);
}
