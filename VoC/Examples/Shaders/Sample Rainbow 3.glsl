#version 420

// original https://www.shadertoy.com/view/wslcWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Loops from 0 to 3
 */
vec3 rainbow(float x) {
    vec3 xyz = abs(mod(x + vec3(0.5,1.5,2.5), 3.) - 1.5);
    return 1.0 - pow(max(vec3(0.0), xyz * 1.5 - 0.5), vec3(2.2));
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy - 0.5 * (resolution.xy);

    // Time varying pixel color
    float dist = log(dot(uv, uv));
    float angle = atan(uv.y, uv.x) / 6.28318530718;
    vec3 col = rainbow(dist * 0.2 + angle * 3.0 + time * -0.2 + sin(time + dist * 2.) * 0.3);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
