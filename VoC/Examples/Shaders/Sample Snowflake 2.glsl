#version 420

// original https://www.shadertoy.com/view/tdySRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cmul(in vec2 a, in vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.y * b.x + a.x * b.y);
}

vec2 re(in vec2 a) {
    return vec2(a.x, 0);
}

vec2 im(in vec2 a) {
    return vec2(0, a.y);
}

vec2 conj(in vec2 a) {
    return vec2(a.x, -a.y);
}

vec2 cinv(in vec2 a) {
    return vec2(conj(a))/ dot(a, a);
}

vec2 cpow(in vec2 a, in int n) {
    vec2 z = vec2(1, 0);
    
    if (n < 0) {
        n *= -1;
        a = cinv(a);
    }
        
    for (int i = 0; i < n; i++) {
        z = cmul(z, a);
    }
    return z;
}

vec2 cexp(in vec2 a) {
      return exp(a.x)* vec2(cos(a.y), sin(a.y));
}

const float PI  = 3.141592653589793;

vec3 hsvToRgb(float h, float s, float v) {
    // h: -π - +π, s: 0.0 - 1.0, v: 0.0 - 1.0
    h = (h + PI) / (2.* PI) * 360.;

    float c = s; // float c = v * s;
    float h2 = h / 60.0;
    float x = c * (1.0 - abs(mod(h2, 2.0) - 1.0));
    vec3 rgb = (v - c) * vec3(1.0, 1.0, 1.0);

    if (0.0 <= h2 && h2 < 1.0) {
        rgb += vec3(c, x, 0.0);
    } else if (1.0 <= h2 && h2 < 2.0) {
        rgb += vec3(x, c, 0.0);
    } else if (2.0 <= h2 && h2 < 3.0) {
        rgb += vec3(0.0, c, x);
    } else if (3.0 <= h2 && h2 < 4.0) {
        rgb += vec3(0.0, x, c);
    } else if (4.0 <= h2 && h2 < 5.0) {
        rgb += vec3(x, 0.0, c);
    } else if (5.0 <= h2 && h2 < 6.0) {
        rgb += vec3(c, 0.0, x);
    }

    return rgb;
}
// hsvToRgb borrowed from
// https://qiita.com/sw1227/items/4be9b9f928724a389a85
// (slightly modified by Kanata)

vec2 f (in vec2 z) {
    return cpow(z, 6) - vec2(1.11, 0.);
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2 res = resolution.xy,
          z = ( u* 2. - res) / min(res.x, res.y);

    float t = time;
    float scale = 2.;
    z *= scale;
    
    vec2 w = cmul(z, cexp(vec2(0., t* 0.1)));
    
    for (int i = 0; i < 8; i++) {
        w = f(w);
    }
    
    w += cmul(z, cexp(vec2(0., t)));

    float theta = atan(w.x, w.y);
    float r = length(w);

    glFragColor = vec4(hsvToRgb(0., 0.1/r+0.1, 0.5/r), 1.);
}
