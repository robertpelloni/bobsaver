#version 420

// original https://www.shadertoy.com/view/4lsSW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define it 24
float t;

float sphere(vec3 p, vec3 rd, float r){
    float b = dot( -p, rd );
    float inner = b * b - dot( p, p ) + r * r;
    if( inner < 0.0 ) return -1.0;
    float s=sqrt(inner);
    return b - s;
}

mat2 rot(float a) {
    float c=cos(a), s=sin(a);
    return mat2(c,s,-s,c);
}

vec3 kset(in vec3 p) {
    p+=sin(p*100.+time*8.)*.0005;
    p*=.74;
    p=abs(1.-mod(p,2.));
    vec3 cp=vec3(0.);
    float c=1000.;
    for (int i=0; i<it; i++) {
        float dd=dot(p,p);
        vec3 p2=p;
        p=abs(p);
        p=p/dd-1.;
        cp+=exp(-50.*abs(p-p2*.5));
        c=min(c,dd);
    }
    c=pow(max(0.,.2-c)/.2,5.);
    return cp*.03+c*.3;
}

void main(void)
{
    t=time*.04;
    //float mono=1.-texture2D(iChannel0,vec2(32./256.,.75)).x;
    vec2 uv = gl_FragCoord.xy / resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
//    vec2 mo=mouse.z>.1?mouse.xy/resolution.xy-.5:vec2(0.);
    vec2 mo=vec2(0.0,0.0);
    vec3 ro=vec3(-mo,-1.5-sin(t*3.7562)*.3);
    vec3 rd=normalize(vec3(uv,1.));
    vec3 v=vec3(0.);
    float x=mo.x*2.+t; float y=mo.y*3.+t*2.;
    mat2 rot1=rot(x);
    mat2 rot2=rot(y);
    float f=1.;
    rd.xy*=rot(.3);
    ro.xy*=rot(.3);
    ro.xz*=rot1;
    rd.xz*=rot1;
    ro.yz*=rot2;
    rd.yz*=rot2;
    float c=0.;
    for (float i=0.; i<55.; i++) {
        float tt=sphere(ro, rd, 1.0-i*.002);
        vec3 p=ro+rd*tt;
        vec3 n=normalize(rd-ro);
        vec3 k=kset(p)*step(0.,tt)*f;
        v+=k*pow(max(0.,dot(rd,n)),8.);
        f*=max(0.5,1.-length(k)*3.5);
        
    }
    glFragColor = vec4(mix(vec3(length(v))*vec3(1.2,1.1,.8),v,.6),1.);
}

