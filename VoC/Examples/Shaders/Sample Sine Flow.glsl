#version 420

// original https://www.shadertoy.com/view/ttdBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;

float hash11(float n) {
    return fract(sin(n*434.4)*543.2);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv *= 10.;
    uv.x += time * .5;
    vec3 col = vec3(0.);
    float f = floor(uv.y - 1.);

    for (float i = 0.; i < 4.; i += 1.0) {
        float n = i + f;
        float c = smoothstep(0.8, 0.5, abs(uv.y - n - sin(uv.x*0.5)));
        col = col + (c * cos(uv.x*0.5 + hash11(n)*10.*time*vec3(.2,.5,.7)));
    }

// Output to screen
    glFragColor = vec4(col,1.0);
}
