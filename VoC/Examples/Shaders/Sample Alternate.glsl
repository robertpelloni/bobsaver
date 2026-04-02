#version 420

// original https://www.shadertoy.com/view/tsByDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float circle(vec2 p, float r, float w) {
    return abs(length(p)-r)-w;
}

float half_pi = acos(0.);

vec2 dist(vec2 p, float t) {
    float d;
    float w = 0.004;

    vec2 q = p - vec2(-0.75, -0.5);
    float d1 = min(
        circle(q, 0.3, w),
        circle(q, 0.4, w));
    
    float a = -(t-half_pi);
    vec2 q1 = q-0.35*vec2(cos(a), sin(a));
    float d2 = circle(q1, 0.04, 0.04);
    d = min(d1, d2);

    vec2 q2 = q - vec2(0., 1.0 + cos(t)*0.4);
    float d3 = circle(q2, 0.04, 0.04);
    d = min(d, d3);

    vec2 q3 = q2;
    float d4 = abs(dot(q3, normalize(q1-q2)*rot(half_pi)));
    d = min(d, d4);

    float d5 = abs(dot(q, normalize(q-q1)*rot(half_pi)));
    d = min(d, d5);

    float d6 = circle(q, 0.04, 0.04);
    d = min(d, d6);

    float s1 = dot(normalize(q1-q2)*rot(half_pi), q2+vec2(-0.005, 0.));
    float s2 = dot(normalize(q-q1)*rot(half_pi), q+vec2(-0.005, 0.));
    float s = ((s1 > 0.) && (s2 > 0.)) || ((s1 < 0.) && (s2 < 0.)) ? 1. : -1.;

    if(s > 0.) {
        float d7 = abs(sin( q.x*9.+t+half_pi)*0.4 - q.y + 1.0) - w*2.;
        d = min(d, d7);
    } else {
        float d8 = circle(mod((p+vec2(t*0.3, 0.))+0.1, 0.2)-0.1, 0.005, 0.005);
        d = min(d, d8);
    }
    
    return vec2(d, s);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy*2.0 - resolution.xy)/min(resolution.x, resolution.y);
    vec4 col = vec4(0.);

    float l = 0.2;

    vec2 m = dist(p, time*3.2);
    float d = m.x;
    float r = m.y;
    float e = 0.1;

    if(r > 0.0) {
      col = vec4(smoothstep(0.02, 0.0, d)*0.8+0.1);
    } else {
      col = vec4(smoothstep(0.0, 0.02, d)*0.8+0.1);
    }

    glFragColor = vec4(col.xyz, 1.);
}
