#version 420

// original https://neort.io/art/br0gl0c3p9f48fkiurlg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = radians(180.);

vec4 dist2color(float d) {
    return vec4(1. - 100. * d, 1. - 50. * d, 1. - 100. * d, 1.);
}

float distWithLine(vec2 p, vec2 s, vec2 t) {
    float d;
    if(dot(t - s, p - s) < 0.) {
        return length(p - s);
    }
    if(dot(s - t, p - t) < 0.) {
        return length(p - t);
    }
    vec2 n = vec2(s.y - t.y, t.x - s.x);
    d = abs(dot(n, p - s)) / length(t - s);
    return d;
}

void line(inout vec4 c, vec2 p, vec2 s, vec2 t) {
    c = max(c, dist2color(distWithLine(p, s, t)));
}

float distWithCircle(vec2 p, vec2 center, float r) {
    return abs(r - length(p - center));
}

void circle(inout vec4 c, vec2 p, vec2 center, float r) {
    c = max(c, dist2color(distWithCircle(p, center, r)));
}

void rack(inout vec4 c, vec2 p) {
    const float module = 0.5 * pi / 24.;
    const float diff = 0.03;
    float t = fract(time);
    for(float y = -1.; y <= 1.5; y += module) {
        vec2 base = vec2(-0.55, y + 0.2 * module - pi / 8. * t);
        line(c, p, base + vec2(-diff, 0.), base + vec2(diff / 2., -module / 2.));
        line(c, p, base + vec2(-diff, -module), base + vec2(diff / 2., -module / 2.));
    }
    for(float y = -1.; y <= 1.5; y += 2. * module) {
        vec2 base = vec2(-0.7, y - pi / 8. * t);
        circle(c, p, base + vec2(-diff, 0.), 0.025);
    }
}

void gear1(inout vec4 c, vec2 p) {
    const int NumOfTeeth = 24;
    const vec2 center = vec2(-0.3, 0.);
    const float radius = 0.25;
    const float diff = 0.03;
    float t = fract(time);
    float module = 2. * pi / float(NumOfTeeth);
    for(int i = 0; i < NumOfTeeth; ++i) {
        float angle = module * (float(i) + 0.5) + 2. * pi / 4. * t;
        line(c, p, center + (radius - diff) * vec2(cos(angle), sin(angle)), center + (radius + diff / 2.) * vec2(cos(angle + module / 2.), sin(angle + module / 2.)));
        line(c, p, center + (radius - diff) * vec2(cos(angle + module), sin(angle + module)), center + (radius + diff / 2.) * vec2(cos(angle + module / 2.), sin(angle + module / 2.)));
    }
}

void gear2(inout vec4 c, vec2 p) {
    const int NumOfTeeth = 48;
    const vec2 center = vec2(vec2(-0.3, 0.) + 0.75 * vec2(cos(pi / 6.), sin(pi / 6.)));
    const float radius = 0.5;
    const float diff = 0.03;
    float t = time;
    float module = 2. * pi / float(NumOfTeeth);
    for(int i = 0; i < NumOfTeeth; ++i) {
        float angle = -(module * float(i) + 2. * pi / 8. * t);
        line(c, p, center + (radius - diff) * vec2(cos(angle), sin(angle)), center + (radius + diff / 2.) * vec2(cos(angle + module / 2.), sin(angle + module / 2.)));
        line(c, p, center + (radius - diff) * vec2(cos(angle + module), sin(angle + module)), center + (radius + diff / 2.) * vec2(cos(angle + module / 2.), sin(angle + module / 2.)));
    }
    
    float angle = -2. * pi / 8. * t;
    vec2 p1 = center + radius / 2. * vec2(cos(angle), sin(angle));
    circle(c, p, p1, 0.05);
    vec2 p2 = vec2(center.x, -0.6 + radius / 2. * sin(angle));
    circle(c, p, p2, 0.05);
    line(c, p, p1, p2);
    
    float left = center.x - 0.08;
    float right = center.x + 0.08;
    float top = -0.6 + radius / 2. + 0.08;
    float bottom = -0.6 - radius / 2. - 0.08;
    line(c, p, vec2(left, top), vec2(right, top));
    line(c, p, vec2(right, top), vec2(right, bottom));
    line(c, p, vec2(right, bottom), vec2(left, bottom));
    line(c, p, vec2(left, bottom), vec2(left, top));
}

void main(void) {
    vec2 p = 1.1 * (2. * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
    
    vec4 c = vec4(0., 0., 0., 1.);
    
    line(c, p, vec2(-1., 1.), vec2(1., 1.));
    line(c, p, vec2(1., 1.), vec2(1., -1.));
    line(c, p, vec2(1., -1.), vec2(-1., -1.));
    line(c, p, vec2(-1., -1.), vec2(-1., 1.));
    
    if(p.y < -1. || 1. < p.y) {
        glFragColor = c;
        return;
    }
    
    rack(c, p);
    
    circle(c, p, vec2(-0.3, 0.), 0.035);
    gear1(c, p);
    
    circle(c, p, vec2(-0.3, 0.) + 0.75 * vec2(cos(pi / 6.), sin(pi / 6.)), 0.035);
    gear2(c, p);
    glFragColor = c;
}
