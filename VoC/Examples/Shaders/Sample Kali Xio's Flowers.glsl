#version 420

// original https://www.shadertoy.com/view/ttScDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float det=.001;
vec3 objcol;
float pi=3.1416;
vec2 id;
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec3 rnd23(vec2 p)
{
    vec3 p3 = fract(p.xyx * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec2 petalos(vec3 p) {
    p.z*=3.;
    float d=length(p)-.6;
    float cant=5.;
    float a=abs(.5-fract(atan(p.x,p.y)/pi/2.*cant))*2.;
    p=vec3(a, length(p.xy)-1., p.z);
    p.y+=smoothstep(0.,1.,p.x)*.15;
       float c = abs(p.x)*step(0.,p.z)*smoothstep(.7,-1.,p.y);
    p.z-=c;
    d=min(d,length(p)-1.);
    return vec2(d*.3,c);
}

float centro(vec3 p) {
    p.xy*=rot(length(p.xy)*2.);
    p.z-=.2+length(sin(p.xy*15.+id.x))*.05;
    p.z*=2.;
    float d=length(p)-.6;
    return d*.5;
}

float flor(vec3 p, vec3 col) {
    p.z=-p.z;
    p.xy*=rot(time*(.5-mod(id.x,2.)));
    p.xz*=rot(sin(time*.5)*.3);
    vec2 pet=petalos(p);
    float cen=centro(p);
       float d=min(pet.x,cen);
    if (d==pet.x) objcol=col*(.5+pet.y);
    if (d==cen) objcol=vec3(1.,1.,0.);
    return d;
}

float de(vec3 p) {
    id=floor(p.xy/6.);
    p.x+=id.y*3.;
    id=floor(p.xy/6.);
    vec3 col=normalize(rnd23(id*2782.734+3.5));
    p.z+=col.x*8.;
    p.xy=mod(p.xy,6.)-3.;
    float d=flor(p,normalize(col));
    return d*.5;
}

vec3 normal(vec3 p) {
    vec2 d=vec2(0.,det);
    return normalize(vec3(de(p+d.yxx),de(p+d.xyx),de(p+d.xxy))-de(p));
}

vec3 shade(vec3 p, vec3 dir) {
    vec3 col=normalize(.2+objcol);
    vec3 ldir = normalize(vec3(2.,0.,-1.));
    vec3 n = normal(p);
    float amb=.15;
    float diff=max(0.,dot(ldir, n));
    return col*(diff+amb);
}

vec3 march(vec3 from, vec3 dir, vec2 uv) {
    float td=0.,d, g=0.;
    vec3 col=vec3(0.),p;
    for (int i=0; i<80; i++) {
        p=from+td*dir;
        d=de(p);
        if (d<det || td>50.) break;
        td+=d;
        g++;
    }
    if (d<det) {
        col=shade(p, dir);
    } else {
        uv.y*=2.;
        uv.x*=1.+uv.y*.3;
        uv.y*=1.+uv.y*.2;
        uv.y+=time*.5;
        uv.x+=abs(.5-fract(uv.y*5.))*.15*uv.x;
        vec2 id=floor(uv*10.);
        uv=abs(.5-fract(uv*10.));
        col=normalize(rnd23(floor(time)+vec2(id.x,floor(id.y*.5))))*smoothstep(.5,.4,uv.x)*(1.+mod(id.y,2.)*1.5)*.15;
    }
    
    return col-g*g*.00003;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;

    vec3 from=vec3(0.,time*3.,-18.);
    vec3 dir=normalize(vec3(uv,1.));
    vec3 col = march(from, dir, uv);

    glFragColor = vec4(col,1.0);
}
