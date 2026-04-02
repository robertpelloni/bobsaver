#version 420

// original https://www.shadertoy.com/view/WdG3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265

float contour(float x, float thickness) {
    // function is 0 except between x = 0 and 2 * thickness, where it smoothly
    // peaks at 1.
    // Useful for drawing contours.
    return (
        x < thickness
    ) ? smoothstep(0., thickness, x) :
        smoothstep(2. * thickness, thickness, x);
}

float rand(float x, float y) {
    // Generate a psuedo-random number from two inputs.
    return fract(
        103.2 * sin(5102.2 * x + 983.87 * y + 23.1) * (7. * x + 923.2*y));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 outputRGB;
    
    // convert to polar.
    uv = vec2(
        atan(uv.x, uv.y),
        sqrt(uv.x * uv.x + uv.y * uv.y)
    );
    // spiral
    uv.x += 0.2 * uv.y;
   
    
    // Add distortion to the coordinates.
    float noise = 0.0;
    for (float i = 1.; i <= 64.; i += 4.) {
        float amp = 1. / (1. + 0.01 * i);
        noise += amp * sin(
            time
            + 2. * i * (uv.x + PI * rand(i, 1.0) + .5 * clamp(uv.y, 0., .5)));
    }
    for (float i = 1.; i <= 64.; i += 4.) {
        float amp = 1. / (1. + 0.01 * i);
        noise += amp * sin(
            -2.5 * time
            + 2. * i * (uv.x + PI * rand(i, 2.0) - .5 * clamp(uv.y, 0., .5)));
    }
    uv += mix(0., 0.0025 * noise, clamp(uv.y - 0.1, 0., 1.));
    
    // Modulo the angle to create polygons.
    float nSides = 5.;
    uv.x = mod(uv.x, 2. * PI / nSides) - PI / nSides;
    
    uv.y *= cos(uv.x);
 
    
    outputRGB += contour(fract(0.5 + 45. * uv.y), 50. / resolution.y);
    
    
    if (uv.y < 0.1) {
        outputRGB *= 0.;
    }
    
    
    // Output to screen
    glFragColor = vec4(1. - outputRGB, 1.0);
}
