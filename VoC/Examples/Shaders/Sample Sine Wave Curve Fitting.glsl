#version 420

// original https://www.shadertoy.com/view/WsdfW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float HALF_PI = 1.5707963267;
vec2[5] points;

// Fit a sine wave between the points a and b:
float fitCurve(in vec2 a, in vec2 b, in float x) {
    float sine = sin(((x - a.x) / (b.x - a.x) * 2.0 - 1.0) * HALF_PI);
    return a.y + (0.5 + 0.5 * sine) * (b.y - a.y);
}

void main(void) {
    // Calculate aspect ratio correct UV coordinates of the pixel:
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * 4.0;

    // The output color;
    float color = 0.0;

    // Calculate point positions:
    for (int i=0; i < points.length(); i++) {
        points[i] = vec2(i - 2, sin(float(i) - time) * (mod(float(i), 2.0) * 2.0 - 1.0));
    }

    // Find the x coordinates of the points farthest left and right:
    float minX = points[0].x;
    float maxX = points[0].x;

    for (int i=0; i < points.length(); i++) {
        minX = min(minX, points[i].x);
        maxX = max(maxX, points[i].x);
    }

    // If the UV coordinates are between the farthest points to the left and right:
    if (uv.x > minX && uv.x < maxX) {
        // Find the points closest to the UV coordinates to the left and right:
        vec2 a = points[0];
        vec2 b = points[points.length() - 1];
 
        for (int i=0; i < points.length(); i++) {
            if (points[i].x > a.x && points[i].x <= uv.x) {
                a = points[i];
            }

            if (points[i].x < b.x && points[i].x >= uv.x) {
                b = points[i];
            }
        }

        // Draw the curve:
        color = smoothstep(0.05, 0.0, abs(uv.y - fitCurve(a, b, uv.x)));
    }

    // Draw the points:
    for (int i=0; i < points.length(); i++) {
        color += smoothstep(0.05, 0.0, length(uv - points[i]) - 0.1);
    }

    // Set the output color:
    glFragColor = vec4(vec3(color), 1.0);
}
