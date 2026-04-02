#version 420

// original https://www.shadertoy.com/view/tljfzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan and slerpy for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

   
// HEAVILY inspired by a invitro from Ninjadev <3 <3 <3 <3
// https://www.youtube.com/watch?v=YxLCvjuW9c4

#define ITER 40.
#define PI acos(-1.)

#define time(speed) fract(time*speed)
#define bouncy(speed) (abs(sqrt(sin(time(speed)*PI))))

#define sphere(p,r) (length(p)-r)

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define replimit(p,c,l) p=p-c*clamp(round(p/c),-l,l)

float easeOutExpo (float x) 
{return x >= 1. ? 1. : 1. - pow(2., -10. * x);}

struct obj 
{
    float dist;
    int mat;
};

obj SDF (vec3 p)
{
    float dt = mod(time*1.5, 7.2);
    float animxz,animyz;
    
    animxz = mix(0.,PI/4., easeOutExpo(clamp(dt-1.,0.,1.)));
    animxz = mix(animxz,-PI/5.1,easeOutExpo(clamp(dt-2.,0.,1.))); 
    animxz = mix(animxz,PI/3.,easeOutExpo(clamp(dt-4.,0.,1.)));
    animxz = mix(animxz,0.,easeOutExpo(clamp(dt-6.,0.,1.)));
    
    animyz = mix(0., PI/2., easeOutExpo(dt));
    animyz = mix(animyz, 1./sqrt(1.6),easeOutExpo(clamp(dt-3.,0.,1.)));
    animyz = mix(animyz, 0.,easeOutExpo(clamp(dt-5.,0.,1.)));
    
    p.xz *= rot(animxz);
    p.yz *= rot(animyz);
    
    float per = 3.;
    float nb = 1.;
    vec3 id = floor((p-per*0.5)/per);
    
    replimit(p,per,nb);
    
   return obj(sphere(p,1.2+bouncy(2.)*0.2),int(length(id*1.5))); 
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(uv*6.2,-50.),
        rd = vec3(0.,0.,1.),
        p = ro,
        col = vec3(0.);

    bool hit = false;
    float shad = 0.;
    obj scene;

    for (float i=0.; i<ITER; i++)
    {
        scene = SDF(p);
        if (scene.dist < 0.001)
        {
            hit = true;
            shad = i/ITER;
            break;
        }
        p += scene.dist*rd;
    }

    if (hit)
    {
        if (scene.mat == 0) col = vec3(1.,0.,0.2);
        if (scene.mat == 1) col = vec3(1.,0.3,0.1);
        if (scene.mat == 2) col = vec3(1.,1.,0.);
        if (scene.mat == 3) col = vec3(0.,0.8,0.35);
        if (scene.mat == 4) col = vec3(0.,1.,1.);
        if (scene.mat == 5) col = vec3(0.9,0.4,0.8);
      
        col *= (1.-shad);
    }

    glFragColor = vec4(sqrt(col), 1.0);
}
