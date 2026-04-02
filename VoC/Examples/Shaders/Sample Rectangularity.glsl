#version 420

// original https://www.shadertoy.com/view/3sjBRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI          3.14159265359
#define QUARTER_PI     0.78539816339

float lineSegment(
    vec2 point, 
    vec2 pointA, 
    vec2 pointB,
    float width
) {
    vec2 pa = point - pointA;
    vec2 ba = pointB - pointA;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);

    return smoothstep(width, 0.0, length(pa - ba * h));
}

float rect(
    vec2 point, 
    float size, 
    float startAngle,
    float lineWidth,
    float index
) {
    float angle = startAngle;
    float nextAngle = 0.;
    float angleStep = PI / 2.;
    float color = 0.;

    for (int i = 0; i < 4; i++) {
        nextAngle = angle + angleStep;
        
        color += lineSegment(
            point, 
            vec2(cos(angle) * size, sin(angle) * size), 
            vec2(cos(nextAngle) * size, sin(nextAngle) * size),
            lineWidth
        );
        
        angle = nextAngle;
    }
    
    return color;
}

float getSize(float size, float R, float iteration) {
    return size * pow(
        R,
        iteration
    );
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy - vec2(0.5);
    
    float d = 32. + sin(time) * 16.;
    float deltaAngle = PI / d * (0.5 + 0.5 * sin(time * 0.5));
    float R = sin(QUARTER_PI) / cos(QUARTER_PI - deltaAngle);
    float D = pow(R, d / 2.);
    float lineWidth = 1. / resolution.x * 2.;
    
    float size = 0.5 / D;// + mod(time, 0.5 / (D * D) - 0.5 / D);

    float color = 0.;
    float angle = -time * 0.6;
    
    for (float i = 0.; i < 100.0; i += 1.) {
        color += rect(
            st, 
            getSize(size, R, i), 
            angle, 
            lineWidth,
            i
        );
        angle += deltaAngle;
    }

    glFragColor = vec4(
        color * (.5 + sin(time * 0.3) * .5 - length(st)),
        color * (.5 + cos(time * 0.5) * .5 - length(st)),
        color * (.5 + sin(time * 1.2) * .5 - length(st)),
        1.0
    );
}
