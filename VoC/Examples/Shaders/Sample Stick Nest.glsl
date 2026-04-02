#version 420

// original https://www.shadertoy.com/view/MscyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RAY_STEPS 150

#define detail .001
#define t (time+2.)
#define tt (t/10.)

float det=0.0;

// 2D rotation
mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

// Distance function
float de(vec3 pos) {
    vec4 p = vec4(pos,1.);
    p *= 3.;
    p.xyz = -abs(p.xyz)+3.+sin(t/6.);
    p.xyz = -abs(p.xyz)+2.+sin(t/6.2)/3.;
    float fr = length(max(p.xyz,-0.78))-0.8;
    return fr/p.w/1.4;
}

// Normals
vec3 normal(vec3 p) {
    vec3 e = vec3(0.0,det*5.,0.0);
    float d1=de(p-e.yxx),d2=de(p+e.yxx);
    float d3=de(p-e.xyx),d4=de(p+e.xyx);
    float d5=de(p-e.xxy),d6=de(p+e.xxy);
    return normalize(vec3(d1-d2,d3-d4,d5-d6));
}

// Raymarch
vec3 raymarch(in vec3 from, in vec3 dir, in vec3 ldir)
{
//    from.z-=2.*scale; // centre
    vec3 p;
    float d=100.;
    float totdist=0.,todistlimit=50./*was 25*/;
    for (int i=0; i<RAY_STEPS; i++) {
        if (d>det && totdist<todistlimit) {
            p=from+totdist*dir;
            d=de(p);
            det=detail*exp(.13*totdist);
            totdist+=d;
        }
    }
    p-=(det-d)*dir;
    vec3 col = min(abs(p.xyz),6.);
    vec3 norm=normal(p);

    ldir = (ldir-p);
    float incid = max(0.0,dot(-norm, normalize(ldir)));
    col *= .2
        + pow(incid,6.)*.2;
    col += pow(incid,200.)*.5
    ;
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy*2.-1.;
    uv.y*=resolution.y/resolution.x;
    vec4 mouse=vec4(0.0);//(mouse*resolution.xy.xyzw/resolution.xyxy-.5)*3.;

    float fov=.8;
    vec3 origin=vec3(0,0,-6.);
    vec3 dir=normalize(vec3(uv*fov,1.));

    vec3 from=origin;
    from.xz*=rot(mouse.x);dir.xz*=rot(mouse.x);
    from.yz*=rot(mouse.y);dir.yz*=rot(mouse.y); // Turn object
    float a = 1.*6.*tt*4.,a2=a*2.*1.;
    from.xz*=rot(radians(a2));    dir.xz*=rot(radians(a2));
    from.yz*=rot(radians(a));    dir.yz*=rot(radians(a));
    vec3 ldir = (vec3(15,15,-20)); // lamp pos
    ldir.xz*=rot(mouse.x);
    ldir.yz*=rot(mouse.y);
    ldir.xz*=rot(radians(a2));
    ldir.yz*=rot(radians(a));
    vec3 col=raymarch(from,dir,ldir);
    glFragColor = vec4(col,1.);
}

////////////////////

