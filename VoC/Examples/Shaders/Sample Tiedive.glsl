#version 420

/*
TIEDYE by Jonathan Proxy
*/

vec2 uv;

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rainbow1( in float h )
{
    h = mod(h, 1.0);
    
    return vec3(smoothstep(0.3, 1.0, h)+smoothstep(0.5, 0.3, h), smoothstep(0.0, 0.3, h)*smoothstep(0.7, 0.4, h), smoothstep(0.3, 0.7, h)*smoothstep(1.0, 0.8, h));
}

vec2 cln(in vec2 v)
{
    float r = length(uv);
    return vec2(log(r), atan(uv.y, uv.x)) / 6.283;
}

void main( void ) 
{
    vec2 aspect = resolution.xy / resolution.y;
    uv = ( gl_FragCoord.xy / resolution.y ) - aspect / 2.0;

    uv = cln(uv);

    vec3 bg_color = mix(
        rainbow1(uv.x*3.0+(uv.y-0.25*time)),
        vec3(1.0, 0.5, 1.0),
        0.25);
        
    vec3 fg_color = mix(
        rainbow1(uv.x+(uv.y*13.0)),
        vec3(1.0, 1.0, 1.0),
        0.25);
    
    glFragColor = vec4(bg_color*fg_color, 1.0);
}
