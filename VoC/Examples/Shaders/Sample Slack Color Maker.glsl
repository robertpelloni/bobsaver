#version 420

// original https://www.shadertoy.com/view/ltdBzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float rows, cols;
    rows = 10.f;
    cols = 10.f;
    
    float idx = floor(uv.x * rows) / rows;
    float idy = floor(uv.y * cols) / cols;
    
    vec3 col = vec3(.8, .5, .2);

    
    col = vec3(col.x + sin(idx + time) * 0.1 - sin(idy * 200. + time) * 0.2, 
               col.y - cos(idy * 12. + 0.1 * time) * 0.1 + sin(idx * 20. + 0.1 * time) * 0.1, 
               col.z + cos(time * 0.1 + idy * 100.) * 0.2);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
