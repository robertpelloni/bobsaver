#version 420

// original https://www.shadertoy.com/view/wtKXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsl2rgb(float h, float s, float l){
    vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0,4.0,2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return l + s * (rgb - 0.5) * (1.0 - abs(2.0 * l - 1.0));
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float phi = 1.16;
    float base = 256.0;

    // Time varying pixel color
    vec3 col = hsl2rgb(uv.x - uv.y * time, 1.0, cos(uv.y * base) / 2.0 + sin(uv.y * base / phi * time / 64.0) / 2.0);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
