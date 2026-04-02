#version 420

// original https://www.shadertoy.com/view/4tVyzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 pos, vec2 uv, float rad) {
    return smoothstep(rad, rad - 0.1, length(pos - uv));

}

float ring(vec2 pos, vec2 uv, float rad) {
    float length = length(pos - uv);
    return smoothstep(rad - 0.01, rad, length) * smoothstep(rad + 0.05, rad, length);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    // Time varying pixel color
    // vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    vec3 col = vec3(0);
    
    float size = sin(time) + sin(time * 2.0) + sin(time*5.0);
    size = abs(size) * 0.02 + 0.2;
    float c = circle(vec2(0, -1.05), vec2(uv.x, uv.y - sqrt(abs(uv.x) + 1.0)), size);
   
    
    float pulse = ring(vec2(0), uv, (time / 2.0 - floor(time / 2.0)) * 2.0);
    
    col += c * 2.0;
    col += pulse;
    col = vec3(col.r, col.g * (uv.x + 0.5), col.b * (uv.y + 0.5));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
