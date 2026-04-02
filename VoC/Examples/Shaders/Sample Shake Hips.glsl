#version 420

// original https://www.shadertoy.com/view/7tfcWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float Thickness = 0.005;

float drawLine( vec2 p, vec2 a, vec2 b ){
    vec2 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    float d = length(pa - ba*h) - Thickness;
    return sqrt(smoothstep(1., -1., d*resolution.y));
}

void main(void) {
    float time = time*4.;
    vec2 p = gl_FragCoord.xy/resolution.y;
    vec2 p2 = vec2(1.-0.01*cos(time), 0.58);
    vec2 p3 = vec2(1.-0.02*sin(time), 0.5);
    vec2 p4 = vec2(1.-0.05*sin(time), 0.42);

    vec2 p11 = vec2(0.95, 0.3);
    vec2 p12 = vec2(1.05, 0.3);
    vec2 p21 = vec2(0.92, 0.22);
    vec2 p22 = vec2(1.07, 0.22);
    vec2 p31 = vec2(0.9, 0.2);
    vec2 p32 = vec2(1.09, 0.2);

    vec2 p51 = vec2(0.9-0.025*cos(time), 0.58);
    vec2 p52 = vec2(1.09-0.02*cos(time), 0.58);
    vec2 p61 = vec2(0.9-0.025*sin(time), 0.64);
    vec2 p62 = vec2(1.09-0.02*sin(time), 0.64);

    float r=0., g=0.;

    g += step(length(p-p2), 0.03);
    g += step(length(p-p2 - (p3-p2)), 0.04);
    g += step(length(p-p4), 0.03);
    g += step(length(p-p11), 0.01);
    g += step(length(p-p12), 0.01);
    g += step(length(p-p21), 0.01);
    g += step(length(p-p22), 0.01);
    g += step(length(p-p31), 0.005);
    g += step(length(p-p32), 0.005);

    g += step(length(p-p51), 0.01);
    g += step(length(p-p52), 0.01);
    g += step(length(p-p61), 0.01);
    g += step(length(p-p62), 0.01);

    r += mix(r, drawLine(p, p2, p3), 1.-g);
    r += mix(r, drawLine(p, p3, p4), 1.-g);
    r += mix(r, drawLine(p, p4, p11), 1.-g);
    r += mix(r, drawLine(p, p4, p12), 1.-g);
    r += mix(r, drawLine(p, p11, p21), 1.-g);
    r += mix(r, drawLine(p, p12, p22), 1.-g);
    r += mix(r, drawLine(p, p21, p31), 1.-g);
    r += mix(r, drawLine(p, p22, p32), 1.-g);

    r += mix(r, drawLine(p, p3, p51), 1.-g);
    r += mix(r, drawLine(p, p3, p52), 1.-g);
    r += mix(r, drawLine(p, p51, p61), 1.-g);
    r += mix(r, drawLine(p, p52, p62), 1.-g);

    glFragColor.r = r;
    glFragColor.g = g;
}
