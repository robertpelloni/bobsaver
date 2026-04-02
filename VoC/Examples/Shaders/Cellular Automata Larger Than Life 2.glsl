#version 420

//Larger than Life Cellular Automata
//Bugs 

//http://psoup.math.wisc.edu/mcell/rullex_lgtl.html

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float r = 5.0; //neighborhood radius

float m = 1.; //check if the middle cell is alive or dead (1 / 0)

float s1 = 34.; //lowest neighbor count to survive
float s2 = 58.; //highest neighbor count to survive

float b1 = 34.; //lowest neighbor count to be born
float b2 = 45.; //highest neighbor count to be born

//Wrap edges
#define LOOP 

vec4 get(vec2 p)
{
    #ifdef LOOP
    return texture2D(backbuffer,mod(p/resolution,1.));    
    #else
    return texture2D(backbuffer,p/resolution);
    #endif
}

const float kw = (2.*r)+1.;
float kernel(vec2 p) //Moore neighborhood (kw x kw)
{
    float w = 0.0;
    vec2 off;
    for(float y = 0.;y < kw;y++)
    {
        for(float x = 0.;x < kw;x++)
        {
            off = vec2(x - floor(kw/2.),y - floor(kw/2.));
            w += get(p+off).w;
        }
    }
    return w;
}

float rand(vec2 co){
    return step(fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) , 0.5);
}

float eps = 0.1;

void main( void ) {

    vec2 p = ( gl_FragCoord.xy );

    float c = get(p).w;
    float k = kernel(p);
        
    c = step(-k,-s1+eps)*step(k,s2+eps)*floor(c);
    
    c += step(-k,-b1+eps)*step(k,b2+eps);

    c += step(length(mouse*resolution-p) ,16.)*rand(p+time);
    
    glFragColor = vec4( vec3( c , k/(r*2.*r*2.), 0), c );
}
