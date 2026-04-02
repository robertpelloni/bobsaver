#version 420

// original https://www.shadertoy.com/view/3sdBR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float myMod(float x, float y) {
    return x - y * floor(x/y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.yy;
    float zoom = 0.1 + 0.5 * (1. + sin(time * 0.1));
    float div = 35. * zoom;
    
    float f = 0.5 + 1. * (1. + sin(uv.y + time*0.7));
    float f2 = 0.5 + 1. * (1. + sin(uv.x + time*1.1));
    bool black = myMod(uv.x * div, f * 2.) < 1.;
    bool black2 = myMod(uv.y * div, f2 * 2.) < 1.;
    black = black && black2;

    // Time varying pixel color
    vec3 col = vec3(black ? 0. : 1.);
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}

