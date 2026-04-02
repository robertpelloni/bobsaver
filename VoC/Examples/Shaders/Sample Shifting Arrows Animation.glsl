#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XdtBD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159, 
            size = .2,
            period = 1.5;
vec2 R;

#define rot(a)             mat2( cos(a), -sin(a), sin(a), cos(a) )
float easeInOut(float t) { return t < .5 ? 2.*t*t : -1.+ (4.-2.*t)*t; }
float angle( float t )   { return ( floor(t) + easeInOut(fract(t)) ) * PI/2.; }

float arrow( vec2 coords )
{
    float x = abs(coords.x - .5), y=coords.y, p = 1./R.y/size;
    return  smoothstep(-p, p, y < .5 || x<.25 ? y : y-.5)  // bases
          * smoothstep( p,-p, y < .5 ? x-.25 : x-1.+y);    // sides
}

float drawArrow( vec2 coords, vec2 offset, float a )
{
    coords -= offset;
    vec2 origin = vec2(.5, .25);
    coords = (coords-origin) * rot(a) + origin; 
    return arrow(coords);
}

float cell( vec2 U, float a )
{
    float v = 0.;
    for (int i=0; i<6; i++) 
        v += drawArrow(U, vec2(i%3-1, i/3), a);
    return v;
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    R = resolution.xy;
    U = ( U - .5*vec2(R.x,0) ) / R.y;
    
    float t = time/period, a = angle(t);
    int i = int(t) % 4;
    U = fract( U/size + (i>1 ? .5 : 0.) ); 
    if (i%2==1) U.y +=.5, a+=PI;
    O = vec4( cell(U, a) );
    if (i%2==1) O= 1.-O;
    glFragColor = O;
}
