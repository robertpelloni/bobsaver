#version 420

// original https://www.shadertoy.com/view/4lc3Wn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 z = gl_FragCoord.xy/resolution.xy-.5;
    z.x *= resolution.x/resolution.y;
    z = vec2(log(length(z)),atan(z.y,z.x)); //complex logarithm  
    z.x -= fract(time)*1.27;
    z *= mat2(5,-5,5,5); //mat2(0.707,-0.707,0.707,0.707)*2./0.283;
    glFragColor = vec4(9.*sin(z.x)*sin(z.y));

}
