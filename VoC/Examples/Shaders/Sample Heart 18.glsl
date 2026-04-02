#version 420

// original https://www.shadertoy.com/view/3slSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795

float shape_contains_point(vec2 point)
{
    // circle with radius ~15
    float radius = 15.0 + 3.0*pow(0.5+0.5*sin(2.0*PI*time+point.y/25.0), 6.0);
    float x = abs(point.x);
    float y = 5.0+1.3*point.y-x*sqrt(abs(20.0-x)/15.0);
    float r2 = radius*radius;
    float smoothRadius = radius + 0.5;
    float r2Smooth = smoothRadius*smoothRadius;
    return 1.0-smoothstep(r2, r2Smooth, x*x+y*y);
}

void main(void)
{
    vec4 background_color = vec4(1.0,0.82,0.9, 1.0);
    vec4 heart_color = vec4(0.9,0.02,0.01, 1.0);

    float min_resolution = min(resolution.x, resolution.y);
    // map 0-Width to -30-30
    mat3 to_local = mat3(
        // column 1
        60.0/min_resolution, 0.0, 0.0,
        // column 2
        0.0, 60.0/min_resolution, 0.0,
        // column 3
        -30.0 * resolution.x / min_resolution, -30.0 * resolution.y / min_resolution, 1.0
        );
    vec3 local_position = to_local * vec3(gl_FragCoord.xy, 1.0);
    glFragColor = mix(background_color, heart_color, shape_contains_point(local_position.xy));
}
