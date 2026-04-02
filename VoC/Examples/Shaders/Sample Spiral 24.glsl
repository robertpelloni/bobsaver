#version 420

// original https://www.shadertoy.com/view/wdtSD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) //WARNING - variables void ( out vec4 c, in vec2 f ) need changing to glFragColor and gl_FragCoord
{
    vec4 c = glFragColor;
    vec2 f = gl_FragCoord.xy;
    vec2 uv = (2.*f-resolution.xy)/resolution.y;
    vec2 ap = vec2(atan(uv.y,uv.x),length(uv));
    c.rgb=(0.5 + 0.5*cos(time+ap.xyx+vec3(0,2,4))*2.)*
        (cos(ap.y*cos(time)*(100.+ap.y*50.*cos(time)*2.)+ap.x-time*7.5));
    glFragColor = c;
}
