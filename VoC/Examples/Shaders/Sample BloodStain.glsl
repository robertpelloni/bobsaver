#version 420

// original https://www.shadertoy.com/view/wlfSDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float HAL(float x,float y,float x0,float y0,float d){
    return (- y + d * x + y0 - d * x0) * 1.0;
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.x;
    float s = 1.0;
    // Time varying pixel color
    vec3 col = vec3(length(uv));
    for(float xi = 0.1; xi < 1.0; xi += 0.2){
        for(float yi = 0.1; yi < 1.0; yi += 0.2){
            s *= HAL(uv.x,
                     uv.y,
                     xi + 0.03 * cos(-time * yi + xi),
                     yi + 0.03 * sin(-time * xi + yi),
                     rand(vec2(xi,yi)) > 0.5 ? 
                    3.0 + 0.25*sin((1.0 - xi) * yi * time * 6.5):
                    0.25*cos(xi * (1.0 - yi) * time * 6.5));
        }
    }

    // Output to screen
    vec3 col1 = vec3(225.0,204.0,155.0) / 255.0;
    vec3 col2 = vec3(195.0,73.0,57.0) / 255.0;
    glFragColor = s > 0.000000000005 ? vec4(col1,0):vec4(col2,0);
}
