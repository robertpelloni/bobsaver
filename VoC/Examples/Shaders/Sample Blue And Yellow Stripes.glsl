#version 420

// original https://www.shadertoy.com/view/WsffW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 6.0 * gl_FragCoord.xy/resolution.xx;
    
    for (int n = 1; n < 8; n++){
         float i = float(n);
         uv += vec2(0.743 / i * sin(i * uv.x + time + 0.322 * i) + 0.808, 0.4613 / i * sin(uv.x + time +0.322 * i) + 1.6);
    }
    uv += vec2(0.714 / cos(sin(uv.x + time + 0.333) * 3.22) + 0.8, 0.432 / sin(uv.x + time +0.322) + 1.43);

    // Time varying pixel color
    vec3 col = vec3(0.505 * sin(uv.x) + 0.505, 0.505 * sin(uv.x) + 0.505, sin(uv.x + uv.x));
                    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
