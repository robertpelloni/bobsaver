#version 420

// original https://www.shadertoy.com/view/3lySDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
      vec2 uv = (gl_FragCoord.xy-.5 * resolution.xy) /resolution.y;
    vec2 uv2= uv;
    
    uv.x = mod(uv.x+ .25, .5) -.25;
    uv.y = mod(uv.y + .25, .5) - .25;
    uv.x = abs(uv.x);
    
    uv2.x = mod(uv2.x+ .12, .24) -.12;;
    
    
    uv.xy *= 5.0;
    // Time varying pixel color
    vec2 d= vec2(length(uv) * (abs(sin(time / 5.))  * 2.5) + 1.5);
    d.x = mod(d.x+ .5, 1.) -.5;
    d.y = mod(d.y+ .3, 0.6) -.3;
    d.x = abs(d.y+ abs(sin((time))) * d.x + abs(cos(time) / 2.));
    
    // Tile 2
    vec2 d2 = vec2(length(uv2) * (abs(cos(time / 2.5))  * 1.75) + 12.5);
    d2.x = mod(d2.x+ 1., .5) - 1.;
    d2.y = mod(d2.y+ .3, 0.6) -.3;
    d2.x = abs(d2.y+ abs(sin((time))) * d2.x + abs(cos(time) / 2.));
     
    
    

    vec3 col = vec3(d.y, d.x, sin(d.x));
    vec3 col2 = vec3(d2.x, d2.y, 0.25);
    
    col += (col2 * sin(time));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
