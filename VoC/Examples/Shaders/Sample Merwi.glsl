#version 420

// original https://www.shadertoy.com/view/ctt3Rf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv *= 15.0;
    uv.y += 0.2 * sin((uv.x) + time * 0.1);
    uv.x += 2.5 * sin((uv.y + 0.4) + time * 0.2);
    uv.y += 0.2 * sin((uv.x) + time * -1.5);
    
    float shape = smoothstep( 0.2, 0.3, fract(uv.y)) * smoothstep( 0.9, 0.8, fract(uv.y)); 

    shape = 1.0 - shape;
    glFragColor = vec4(shape, shape, shape, 1.0);
}
