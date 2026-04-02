#version 420

// original https://www.shadertoy.com/view/wsXGWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of https://shadertoy.com/view/3sfGD7

#define h 2. // spike height

void main(void) //WARNING - variables void ( out vec4 O, vec2 U ) need changing to glFragColor and gl_FragCoord
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    float t = time, v;
    mat2  R = mat2( sin(t+vec4(0,33,11,0)) );
    vec3  q = vec3(resolution.xy,1),
          D = normalize(vec3(.3*(U+U-q.xy)/q.y, -1)),// ray direction
          p = 30./q;                             // marching point along ray 
    O-=O;
    for ( O++; O.x > 0. && t > .01 ; O-=.005 ) {
        q = p,
        q.xz *= R, q.yz *= R,                    // rotation
        t = length(q)-6.;
        q /= length(q);
        v = 1.-q.y*q.y;
        if (t < h) {
            q.x = atan(q.x,q.z); // q.x = asin(q.x/sqrt(v));
            q.y = asin(q.y);
            v = q.y/1.57; v = 8.*sqrt(1.-v*v);  // small circle perimeter, for adaptive hill amount
#if 0       // some hills are truncated at equator
            q.x *= v; 
#else       // avoid truncated hills         
            v = ceil(4.*abs(q.y)/1.57)/4.; v = 8.*sqrt(1.-v*v); // avoid disconts towards poles
            q.x *= floor(v+.1); // try +.0 or .5 or 1. or floor(.5*v+1.)*2.-1.
#endif
            q.y *= 8.;
            q = sin(q); v = q.x*q.y; v *= abs(v);  // try v *= -v;
            t += v*h; 
        }
        p += t/h/4.*D;                             // step forward = dist to obj
    }
    O *= vec4(v,-v,.5+.15*sin(30.*v),1);           // coloring scheme
    glFragColor = O;
}
