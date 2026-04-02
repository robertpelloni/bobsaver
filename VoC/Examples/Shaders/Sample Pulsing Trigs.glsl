#version 420

// original https://www.shadertoy.com/view/wdcXRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = ( 2.* gl_FragCoord.xy - resolution.xy) / resolution.xy;  
    
    float s = sin(time);
    uv *= 1. + 3. * s * s;
    uv.x *= resolution.x / resolution.y;
    
    float x = uv.x, y = uv.y;
    
    float zRed = smoothstep(0.2, 0., abs(sin(x + time) + sin(y)));
    float zGreen = smoothstep(0.2, 0., abs(cos(x-time) + sin(y)));;
    float zBlue = smoothstep(0.2, 0., abs(sin(x) * sin(y + time)));;

    glFragColor = vec4(zRed, zGreen, zBlue ,1);
}
