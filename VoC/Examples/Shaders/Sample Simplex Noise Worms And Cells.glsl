#version 420

// original https://www.shadertoy.com/view/tlfczS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ss(t, b, g) smoothstep(t-b, t+b, g)
#define screen(a, b) a+b-a*b

vec2 hash( vec2 p ) // modified from iq's too
{
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    p = -1.0 + 2.0*fract(sin(p)*43758.5453123);
    return p;
    //return normalize(p); // more uniform (thanks Fabrice)
}

// slightly modified version of iq's simplex noise shader: https://www.shadertoy.com/view/Msf3WH
vec3 snoise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
    vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return 1e2*n; //return full vector
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float b = resolution.y;
    float t =.25;
    if(mouse*resolution.xy.xy!=vec2(0))
    //t = mouse*resolution.xy.y/b;
    b = 4./b;
    
    vec3 n = snoise( 6.*(p-time/10.+5.) );
    vec3 an = abs(n);
    vec4 s = vec4(
        dot( n, vec3(1.) ),
        dot( an,vec3(1.) ),
        length(n),
        max(max(an.x, an.y), an.z ) );
    
    float x;
    
    if(p.x<-.333)
    // worms
        x = 1.25*( s.y*t-abs(s.x) )/t;
    else if(p.x<.333) {    
    // cells
        x = (1.-t)+(s.y-s.w/t)*t;
        x *= 1.+t;
        //if(texelFetch( iChannel0, ivec2(32,2),0 ).x>.5) // spacebar pressed
        //    x = ss(.6, b, x); // treshold
        x *= x; // looks nicer
    }
    else
    // intestines or brain
        x = .75*s.y;
    
    float border = ss( .002, b/4., abs(abs(p.x)-.333) );
    x = screen( x*border, (1.-border) );

    glFragColor = vec4(x);
}
