#version 420

// original https://www.shadertoy.com/view/ws3XWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Tuesday Practice Shader
    October 22th 2019

    Reduce to the basic steps
    Cast/Sample/Shade/Composite 

    *marcher based off Flopine's
    https://www.shadertoy.com/view/WstXRH
*/

#define MAX_STEPS     100.
#define MAX_DIST    50.
#define MIN_DIST    .001
#define EPSILON        .0001

#define PI 3.14159265

// set to 0 to turn off anaglyph 3d rendering
#define A3D 1

mat2 rot(float a) {
    float c=cos(a); float s=sin(a);
    return mat2(c,s,-s,c);    
}

float map_scene( in vec3 p ) {
    float an = 0.5;// + (10.*mouse.x*resolution.xy.x/resolution.x);
    float ay = 0.5;// + (20.*mouse.y*resolution.xy.y/resolution.y);
    //float t3;
    //t3 = pow(smoothstep(-1.0,1.0,fract(t3)),5.0)+floor(t3);
    //t3 += sin(time*.95) + 0.5 * .85;

    float m=1000.0;
    float thick =.075;
    p.xz*=rot(an+time*.2);
    for(int i=0;i<4; ++i) {

        p.xz*=rot(.45);
          p.yz*=rot(ay+ 1. + 1. * sin(time*.1));
        p=abs(p);
        
        m=min(m, min(p.y, min(p.y,p.z)));
    }

    m=abs(m-.5)-thick;

    float f=abs(length(p)-7.)-0.25;
    float d=max(f,m);
    
     return d; 
}

float map( in vec3 pos ) {
    float d1 = 100.;
    vec3 q = pos - vec3(0.,0.,-15.);
    
    q.y = sin(q.y);
    
    float d = map_scene(q);
    return d;
}      

float get_ray( in vec3 ro, in vec3 rd ) {
    #if A3D>0
    float col = 0.5;
    #else
    float col = 0.;
    #endif
     float shad = 0.;
    vec3 p = ro;
    bool hit = false;
    
    for (float i=0.; i<MAX_STEPS; i++)
    {
        float d = map(p);
        if (d<0.001)
        {
            hit = true;
            shad = abs(i/MAX_STEPS);
            break;
        }
        p += d*rd*0.5;
    }
    if (hit) col = 1.-shad;
    return col;
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro = vec3(0.,0.,-24.5);
    vec3 rd = normalize(vec3(uv,1.));
    
    vec3 eyedist =vec3(.15,0.,0.);

    #if A3D>0
        float shade_left = get_ray(ro + eyedist,rd);
        float shade_right= get_ray(ro - eyedist,rd);
        vec3 color = vec3(shade_right, shade_left, shade_left);
    #else    
        float shade = get_ray(ro ,rd);
        vec3 color = shade * vec3(1.)*.85;
        color = pow(color, vec3(0.4545));
    #endif
    
    glFragColor = vec4(color,1.0);
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 fragRayOri, in vec3 fragRayDir ) {
    vec2 uv = (2.*gl_FragCoord-resolution.xy)/resolution.y;
    vec3 ro = vec3(0.,1.,1.);
    vec3 rd = vec3(0.,0.,0.);

    float shade = get_ray(fragRayOri + ro, fragRayDir + rd);
    vec3 color = shade * vec3(1.)*.75;
    color = pow(color, vec3(0.4545));
  
    glFragColor = vec4(color,1.0);
}
