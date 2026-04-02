#version 420

// original https://www.shadertoy.com/view/tlSSWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define det .003
#define t time
#define dd vec3(0.,det,0.) 
#define N(de,p) normalize(vec3(de(p+dd.yxx),de(p+dd.xyx),de(p+dd.xxy))-de(p))

mat2 rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c,s,-s,c);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

mat3 lookat(vec3 to, vec3 up) {
    to=normalize(to); vec3 r=normalize(cross(to,up));
    return mat3(r, cross(to,r), to);
}

vec3 tile(vec3 p, vec3 t) {
    return abs(t - mod(p,t*2.));
}

float de1(vec3 p) {
    p=tile(p,vec3(1.));
    float d=length(p.xz)-.05;
    d=min(d,length(p.yz)-.05);
    return smin(d,length(p)-.25,.1);
}

float de2(vec3 p) {
    p=tile(p,vec3(3.5));
    float d=length(max(vec3(0.),abs(p)-vec3(10.,.25,.25)));
    d=min(d,length(max(vec3(0.),abs(p)-vec3(.25,10.,.25))));
    return min(d,length(max(vec3(0.),abs(p)-1.5)));
}

float de3(vec3 p) {
    p=tile(p,vec3(3.5));
    float poles=min(length(p.yz),length(p.xz))-.3;
    return smin(poles,length(p)-3.,.5);
}

vec3 march1(vec3 from, vec3 dir) {
    vec3 p, col=vec3(0.);
    float totdist=0.,d=0.;
    for (int i=0; i<80; i++) {
        p=from+dir*totdist;
        d=de1(p);
        if (d<det || totdist>30.) break;
        totdist+=d;
    } 
    if (d<.1) {
        vec3 n=N(de1,p);
        float dif=max(0.,dot(dir, -n));
        col=vec3(3.,.5,.5)*dif;
    } else totdist=30.;
    return mix(col,vec3(4.,3.,2.),totdist/30.);
}

vec3 march2(vec3 from, vec3 dir) {
    vec3 p, col=vec3(0.);
    float totdist=0.,d=0.;
    for (int i=0; i<80; i++) {
        p=from+dir*totdist;
        d=de2(p);
        if (d<det || totdist>50.) break;
        totdist+=d;
    }
    if (d<.1) {
        vec3 n=N(de2,p);
        float dif=.2+max(0.,dot(dir, -n));
        col=vec3(0.,0.5,1.5)*dif;
        vec3 dir2=lookat(-n,vec3(1.,1.,0.))*dir;
        vec3 from2=vec3(0.,t,0.);
        col=mix(col,march1(from2,dir2),.5)*dif;
    } else totdist=50.;
    return mix(col,vec3(2.),totdist/50.);
}

vec3 march3(vec3 from, vec3 dir) {
    float maxdist=min(50.,t*10.);
    vec3 p, col=vec3(0.);
    float totdist=0.,d=0.;
    for (int i=0; i<150; i++) {
        p=from+dir*totdist;
        d=de3(p);
        if (d<det || totdist>maxdist) break;
        totdist+=d;
    }
    if (d<.1) {
        vec3 n=N(de3,p);
        float dif=.2+max(0.,dot(dir, -n))*.8;
        col=vec3(1.,0.3,0.)*dif;
        vec3 dir2=lookat(-n,vec3(0,1.,0.))*dir;
        vec3 from2=vec3(t,3.,1.);
        col=mix(col,march2(from2,dir2),.5)*dif;
    } else totdist=maxdist;
    return mix(col.rgb,vec3(2.,1.,.8),totdist/maxdist);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    float tt=t*.07;
    vec3 from=vec3(tt,tt,.1)*10.*smoothstep(5.,10.,t);
    vec3 dir=normalize(vec3(uv,1.));
        
    vec3 col = march3(from, dir);
    col=mix(vec3(length(col)*.5),col,.6);
    col*=vec3(1.,.9,.8);    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
