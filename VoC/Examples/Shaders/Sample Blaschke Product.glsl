#version 420

// original https://www.shadertoy.com/view/XtsBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cMul(vec2 a, vec2 b) { // complex multiplication
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

vec2 cDiv(vec2 a, vec2 b) { // complex division
    return vec2((a.x * b.x + a.y * b.y), (a.y * b.x - a.x * b.y)) / dot(b, b);
}

vec2 conj(vec2 a) { // complex conjugate
    return vec2(a.x, -a.y);
}

vec2 blaschkeB(vec2 a, vec2 z) { // a is the point in the set, z is the sample point on the grid
    return cDiv(a - z, vec2(1.,0.) - cMul(conj(a), z));
}

// from iq’s article here: http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(float v) {
    return vec3(0.5) + 0.5 * cos(6.28318 * (v + vec3(0.0,0.333,0.667)));
}

vec2 thingPosition(float t) { // from an old thing of mine here: https://www.shadertoy.com/view/Xl33D7
    return vec2(sin(2.2 * t) - cos(1.4 * t), cos(1.3 * t) + sin(-1.9 * t)) * 0.2;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    uv *= 1.1;
    
    vec2 prod = vec2(1.,0.);
    for(int i = 0; i < 43; i++) {
           vec2 a = thingPosition(float(i) * 37. /* arbitrary */ + time * 0.3);
        prod = cMul(prod, blaschkeB(a, uv));
    }
    
    float angle = atan(prod.y, prod.x) * 1.;
    glFragColor = vec4(palette(angle / 6.28318 - time * 1.9),1.0);

}
