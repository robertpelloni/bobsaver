#version 420

// original https://www.shadertoy.com/view/3lyBzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    float X = uv.x*42.;
    float Y = uv.y*-32.;
    float t = time*3.6;
    float col = sin(sin(t+X/4.)-t+Y/9.+sin(X/(6.+sin(t*.1)+sin(X/9.+Y/9.))));
    
    glFragColor =  glFragColor = vec4( col / fwidth(col) );
}
