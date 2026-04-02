#version 420

// original https://www.shadertoy.com/view/XlfGDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Testing transformations of a simple circle

float PI = 3.14159269359;

// Fuzzy unit circle.
float circle(in vec2 p)
{
    float r = length(p);
    float angle = atan(p.y, p.x);
    r += .1*sin(angle*8.)*sin(time*.5);
    //return step(abs(r - .5), .1);
    return step(r, 1.) * pow(1.-r, .5);
}

// Project a point onto the circle of radius max(x,y).
vec2 square2circle(in vec2 p)
{
    vec2 ap = abs(p);
    float r = max(ap.x, ap.y);
    float angle = atan(p.y, p.x);

    return r*vec2(cos(angle), sin(angle));
}

// Project a point onto the circle of radius max(x,y).
vec2 mapRects(in vec2 p)
{
    vec2 ap = abs(sin(p*6.));
    float r = max(ap.x, ap.y);
    float angle = atan(p.y, p.x);

    return r*vec2(cos(angle), sin(angle));
}

vec2 duplicate(in vec2 p)
{
    return abs(sin(p*4.));
}

vec2 concentric(in vec2 p)
{
    vec2 ap = abs(p);
    float r = max(ap.x, ap.y);
    float angle = atan(p.y, p.x);

    return sin(5.*r)*vec2(cos(angle), sin(angle));
}

mat2 rotate(float angle)
{
    return mat2(
        vec2( cos(angle), sin(angle)),
        vec2(-sin(angle), cos(angle)));
}

vec2 getTransform(in vec2 p, int which)
{
    if (which == 0) {
        p = square2circle(p);
        p = rotate(time*.1)*p;
        p = duplicate(p);//        p = mapRects(p);
        p = rotate(time*.1)*p;
        p = mapRects(p);
    } else if (which == 1) {
        p = square2circle(p);
        p = rotate(time*.1)*p;
        p = duplicate(p*.5);//        p = mapRects(p*.5);
        p = rotate(time*.1)*p;
        p = mapRects(p);
    } else if (which == 2) {
        p = square2circle(p);
        p = rotate(time*.1)*p;
        p = duplicate(p*.5);//        p = mapRects(p*.5);
        p = mapRects(p);
        p = rotate(time*.1)*p;
        p = mapRects(p);
    } else {
        p = square2circle(p);
        p = rotate(time*.1)*p;
        p = mapRects(p);
        p = duplicate(p);//        p = mapRects(p);
        p = mapRects(p*.5);
        p = rotate(time*.1)*p;
        p = mapRects(p);

    }
    return p;
}

vec2 applyTransform(in vec2 p)
{
    // Slowly fade from 0 to 1 every second.
    float t = time*.3;
    float pct = smoothstep(0., 1., mod(t, 1.));
//    float pct = mod(t, 1.);
    int current = int(mod(t, 4.));
    int next = int(mod(t+1., 4.));
    return mix(getTransform(p, current), getTransform(p, next), pct);
}

void main(void)
{
    vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    p.x *= resolution.x/resolution.y;

    p = applyTransform(p);
    float c1 = circle(p);
    float c2 = circle(p*1.7);
    float c3 = circle(p*1.3);
//    float c2 = circle(p - .2*vec2(sin(time*.6), cos(time*.4)));
//    float c3 = circle(p + .2*vec2(sin(time*.5), cos(time*.5)));

    glFragColor = vec4(c1, c2, c3, 1.0);
}
