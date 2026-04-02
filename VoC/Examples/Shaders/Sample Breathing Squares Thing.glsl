#version 420

// original https://www.shadertoy.com/view/43VGWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (3.14159265)
#define TAU (PI*2.)

// #define FWIDTH   // uncomment this for experiment

/*
#define SINC(X) sin(X)/(X)
vec2 XmainSound( int samp, float time ) // removed sound for now
{
  return vec2( 
    clamp( 
       sin(TAU*time*
         (220.+SINC(time*.3+PI/2.)*150.)
       )
       +sin(TAU*time*25.),
     -1.,1.)
  );
}
*/

float spread = 0.;
float depth = 0.;

vec3 Dist(vec3 beg,vec3 dir) { // return location in side of object
    float zz = 1. - fract(beg.z); // distance to next plane of objects
#ifdef FWIDTH
    vec3 hit = vec3(0.,0.,1000.);
#endif            
    while ( beg.z < 50. )
    {
        beg += dir * (zz - fract(dir.z)); // position in next plane
        float x = fract(beg.x), y = fract(beg.y);
#ifdef FWIDTH
        float ff = max(x,y) < .5 ? 1. : 0.;
        if ( fwidth(ff) > .5) if ( hit.z >= 1000. ) { hit.z = beg.z; hit.x = depth; }
#else
        if ( max(x,y) < .5 && ! ( x > .1 && x < .4 && y > .1 && y < .4 ) && beg.z > 3. )
            break; // hit something
#endif            
        zz = beg.z > 3. ? spread : 1.;
        if ( beg.z > 3. ) ++depth;
    }
#ifdef FWIDTH
    if ( hit.z < 1000. ) depth = hit.x; // messy kludge code for experiment
    return hit;
#else    
    return beg;
#endif            
}

vec2 rot2d(vec2 inp,float ang) {
    float s = sin(ang);
    float c = cos(ang);
    return vec2( inp.x * c + inp.y * s, inp.y * c - inp.x * s ); 
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.) / min(resolution.x,resolution.y);
    uv = rot2d( uv, time/17.);

    spread = .8+sin(time*.7)*.75;

    vec3 cam = vec3(0.+sin(time*.13)*.5+time,0.+sin(time/12.)+time/2.,2.+cos(time*.2)*1.9);
    vec3 camdir = vec3( uv.x, uv.y, 1. );

    vec3 hit = Dist(cam,camdir);
  
    vec3 col = 5.*sin( vec3(0.,PI/3.,PI*2./3.) + depth*.6)/hit.z;
    col = mix( col, vec3(4./hit.z), .85);

    glFragColor = vec4( col, 1. );

}

