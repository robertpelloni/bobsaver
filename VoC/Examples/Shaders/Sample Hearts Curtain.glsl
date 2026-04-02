#version 420

// original https://www.shadertoy.com/view/MljczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Wanted to make something with hearts, don't know why.

This work is licensed under a Creative Commons Attribution 4.0 International License.
https://creativecommons.org/licenses/by/4.0/
*/

vec3 heart(vec2 uv, vec2 orient)
{
    uv -= vec2(0.5,0.81);    // Offset so heart is placed better
    vec2 uvp = vec2(length(uv), atan(uv.y, uv.x));    // Turn cartesian UV into polar coordinates
    
    float heartdist = 2.-2.*sin(uvp.y) + sin(uvp.y) * (sqrt(abs(cos(uvp.y)))/(sin(uvp.y)+1.4));    // Polar heart function
    heartdist *= 0.2;    // scale it down a bit
    

    vec3 col = mix(vec3(255,105,180)/255. * 0.9 - uvp.x*0.4,    // Pink with some distance-based shading
                   vec3(0.5,0.5,0.5),
                   (smoothstep(heartdist, heartdist + .05, uvp.x)));   
    
    return col;
}

// Resolution dependent cell-size
#define cellsize (resolution.x / 23.)
void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2. / resolution.xy)-vec2(1);
    
    #define heartoffset vec2(sin(uv.x + time)*10., cos(uv.x * 10. + time)*15.*(1.5-uv.y)*0.4)
    #define heartcoord fract(((gl_FragCoord.xy + heartoffset) - resolution.xy/2.) / cellsize)
    
    vec3 col = heart(heartcoord, vec2(1));
    
    // Add a bit of shading to make things seem more 3-dimensional
    col -= (heartoffset.y + heartoffset.x) * 0.01 * (1.-uv.y)*0.4;
    col -= vec3((1.-uv.y)*0.1,0,0);
    
    glFragColor = vec4(col, 1);
}
