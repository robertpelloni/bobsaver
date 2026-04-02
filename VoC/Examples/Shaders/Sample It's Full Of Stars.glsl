#version 420

// original https://www.shadertoy.com/view/4ddyR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// It's full of stars...
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.shadertoy.com/view/4ddyR8
// By David Hoskins.

//#define SEEIN2D 

vec3 get2Dplanes(vec2 uv, vec2 p)
{
    uv *= .5;
    float f  = 1., g =f;    
    for( int i = 0; i < 20; i++) 
    {
        float d = dot(uv,uv);
        uv = (vec2( uv.x, -uv.y ) / d) + p; 
        uv.x =  abs(uv.x);
        f = max( f, (dot(uv-p,uv*.5 -p) ));
        g = min( g, sin(dot(uv+p,uv+p))+1.0);
    }
    f = abs(-log(f) / 4.3);
    g = abs(-log(g) / 5.4);
    g *= g;
    vec3 col = vec3(min(vec3(g, g*f, f), 1.0));

    return vec3(col);
    
}

// Design function...
vec2 choose(float i)
{
    float g = i*2.7;
    vec2 p;
    
    p.x = -.6+sin(g * .3)*sin(g * .17) * 2. + sin(g * .3);
    p.y = (1.0-cos(g * .632))*sin(g * .131)*1.2-cos(g * .3);

    return p;    
}

vec3 starPlane(vec2 uv)
{
   
    //uv.y += time;

    vec3 col, col2;

    float i = floor(uv.y);
    uv.y     = fract(uv.y);
    vec2 p = choose(i);
    col = get2Dplanes(uv, p);
    p = choose(i-1.);
       col2 = get2Dplanes(uv+vec2(0,1), p);
    col = mix (col2, col, uv.y);
    return col;
}    

void main(void)
{
    vec3 col = vec3(0);
#ifdef SEEIN2D
    vec2 uv = ((-resolution.x+2.0 * gl_FragCoord.xy) / resolution.y);
    col = starPlane(uv+vec2(0.0,time));

#else
    vec2 uv = ((-resolution.xy+2.0 * gl_FragCoord.xy) / resolution.y);
    
    vec3 dir = normalize(vec3(uv, 1.5-dot(uv,uv)*.5));
    // Mirror the horizon, shifted a little bit to remove some aliasing in the distance...
    float f = abs(dir.y)+.02;
    float d = .25/f;
    uv = vec2(0, time*2.) + dir.xz* d;

    // Two distinct images for upper and lower...
    if (dir.y < 0.)
        col = starPlane(uv-1.3);
    else
        col = starPlane(uv+3.3);
    
    if (uv.y < -time+4.) col = vec3(0);

    col *= smoothstep(0.0,2., time);
    col *= smoothstep(0.02,.05,f);
    
#endif

    
    glFragColor = vec4(col,1.0);
}
