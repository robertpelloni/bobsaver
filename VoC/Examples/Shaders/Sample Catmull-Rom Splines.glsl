#version 420

// original https://www.shadertoy.com/view/tdGcRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Reference: https://qroph.github.io/2018/07/30/smooth-paths-using-catmull-rom-splines.html

// Constants

#define time (time/1.0)
#define LINES 32
#define STEP 1.0/float(LINES)

#define POINTS 10
#define MAX_POINTS POINTS

const float PI = acos(-1.0);
const float TAU = PI * 2.0;

// Draw helpers

vec2 p;

float line(vec2 a, vec2 b) {
    vec2 v  = b-a;
    vec2 p0 = p-a;
    float k = min(length(p0)/length(v),1.0);
    return smoothstep(4.0/resolution.y,0.0,length(p0-k*v));
}

float point(vec2 o) { return smoothstep(10.0/resolution.y,7.5/resolution.y,length(p-o)); }

void drawPoint(inout vec3 color, vec3 drawColor, vec2 p) {
    color = mix(color, drawColor, point(p));
}

void drawPoints(inout vec3 color, vec3 drawColor, vec2 p[MAX_POINTS], int count) {
    for (int i = 0; i < count; i++)
        drawPoint(color, drawColor, p[i]);
}

void drawLine(inout vec3 color, vec3 drawColor, vec2 p[MAX_POINTS], int count) {
    for (int i = 0; i < count - 1; i++) {
        color = mix(color, drawColor, line(p[i], p[i+1]));
    }
}

vec2 splineInterpolation(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    float alpha = 1.0;
    float tension = 0.0;
    
    float t01 = pow(distance(p0, p1), alpha);
    float t12 = pow(distance(p1, p2), alpha);
    float t23 = pow(distance(p2, p3), alpha);

    vec2 m1 = (1.0f - tension) *
        (p2 - p1 + t12 * ((p1 - p0) / t01 - (p2 - p0) / (t01 + t12)));
    vec2 m2 = (1.0f - tension) *
        (p2 - p1 + t12 * ((p3 - p2) / t23 - (p3 - p1) / (t12 + t23)));
    
    vec2 a = 2.0f * (p1 - p2) + m1 + m2;
    vec2 b = -3.0f * (p1 - p2) - m1 - m1 - m2;
    vec2 c = m1;
    vec2 d = p1;

    return a * t * t * t +
           b * t * t +
           c * t +
           d;

}

float spline(vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
    float curve = 0.0;
    vec2 a = p1;

    for (int i = 1; i <= LINES; i++) {
        vec2 b = splineInterpolation(p0, p1, p2, p3, STEP*float(i));
        curve = mix(curve,1.0, line(a, b));
        a = b;
    }
    
    return curve;
}

void drawSpline(inout vec3 color, vec3 drawColor, vec2 p[MAX_POINTS], int count) {
    for (int i = 0; i < count - 3; i++) {
        color = mix(color, drawColor, spline(p[i], p[i+1], p[i+2], p[i+3]));
    }
}

vec2[MAX_POINTS] deformedCircle(int count) {
    vec2 p[MAX_POINTS];
    for (int i = 0; i < count; i++) {
        float a = float(i) / float(count) * TAU;
        p[i] = vec2(3.0, 1.5) * vec2(cos(a), sin(a)) * (0.3 + 0.1 * sin(time) + 0.15 * sin(a * 3.456 + time));
    }
    return p;
}

void main(void) {
    p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 color = vec3(0.94);
    
    vec2 p[MAX_POINTS] = deformedCircle(POINTS);
    
    drawLine(color, vec3(0.0), p, POINTS);
    drawPoints(color, vec3(0.0), p, POINTS);
    drawSpline(color, vec3(1.0, 0.0, 0.0), p, POINTS);
    
    glFragColor = vec4(color ,1.0);
}
