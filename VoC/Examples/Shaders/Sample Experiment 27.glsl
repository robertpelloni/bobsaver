#version 420

// original https://www.shadertoy.com/view/tdySzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS     150.
#define MAX_DIST    50.
#define MIN_DIST    .001
#define EPSILON        .0001
#define PI             3.14159265

#define time time

mat2 rot(float a) {
    float c=cos(a); float s=sin(a);
    return mat2(c,s,-s,c);    
}

vec2 map_scene( in vec3 p ) {

    float bTime = time*.25;
    float sw =3.75 + 3.75 * sin(bTime);
    float m=1000.0;
    float thick =.25;
    vec2 res = vec2(m, -1.);

    p -= sin(p.xzy);

    for(int i=0;i<1; ++i) {
        p.xz*=rot(1.566);

        p=abs(p);
        m=min(m,min(p.y,min(p.y,p.z)));
    }

    m=abs(m-.5)-thick;
    // outter tube //
    float f=abs(length(p)-8.)-0.5;
    float d=max(f,m);
    if(d<res.x) res = vec2(d,1.);
    // inner tube //
    f=abs(length(p)-5.)-0.2;
    float c =max(f,m);
    if(c<res.x) res = vec2(c,2.);

     return res; 
}

vec2 map( in vec3 pos ) {
    vec3 q = pos - vec3(0.,0.,-23.);
    
    q.y = sin(q.y * .5 + time*2.2);

    vec2 d = map_scene(q);
    return d;
}      

vec2 get_ray( in vec3 ro, in vec3 rd ) {
     float shd = 0.;
    float mate = -1.;
    vec3 p = ro;
    bool hit = false;
    
    for (float i=0.; i<MAX_STEPS; i++)
    {
        vec2 d = map(p);
        if (d.x<MIN_DIST||shd>MAX_DIST)
        {
            hit = true;
            shd = abs(i/75.);
            mate = d.y;
            break;
        }
        p += d.x*rd *.5;
    }
    float col = (hit) ? 1.-shd : 0.;
    return vec2(col,mate);
}
 
vec3 get_material( in float m, in vec3 pos ) {
    vec3 mate = vec3(.1);
    if (m==2.) {
        mate = vec3(.9,.5-pos.y,.0);
    }
    if (m==1.) {
        mate = vec3(.0,.6-pos.y,.9);
    }
    return mate;
}
  
void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro = vec3(0.,0.,-23.);
    vec3 rd = normalize(vec3(uv,.6));

  
    if( mod(time*.5,10.)<5. ){
        rd.xz*=rot(1.58);
    } else {
        rd = normalize(vec3(uv,1.));
        rd.yz*=rot(1.5);
        rd.xz*=rot(1.58);
    }

    vec2 march = get_ray(ro ,rd);
    float shade = march.x;
    vec3 p = ro + shade * rd;
    vec3 mate = get_material(march.y, vec3(uv,1.));
    vec3 color = shade * mate;
    glFragColor = vec4(color,1.0);
}
