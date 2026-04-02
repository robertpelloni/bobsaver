#version 420

// original https://www.shadertoy.com/view/sl23Rw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

Noise value. https://www.youtube.com/watch?v=zXsWftRdsvU&t=285s

all credits to: https://www.youtube.com/channel/UCcAlTqd9zID6aNX3TzwxJXg

*/

float R21 (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.3245,89.234)))*45987.5632145);
}

float NoiseValue (vec2 uv) {
    vec2 gv = fract(uv);
    vec2 id = floor(uv);
    
    gv = gv * gv * (3. - 2. * gv);

    float a = R21(id);
    float b = R21(id + vec2(1., 0.));
    float c = R21(id + vec2(0., 1.));
    float d = R21(id + vec2(1., 1.));

    return mix(a, b, gv.x) + (c - a)* gv.y * (1. - gv.x) + (d - b) * gv.x * gv.y;
}

float SmoothNoise (vec2 uv) {

    float value = 0.;
    float amplitude = .5;

    for (int i = 0; i < 8; i++) {
        value += NoiseValue(uv) * amplitude;
        uv *= 2.;
        amplitude *= .5;
    }
    
    return value;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;

    vec3 col = vec3(0.);
    
    vec2 r = vec2(1.);
    //r.x = SmoothNoise( uv + 0.00*time);
    //r.y = SmoothNoise( uv + vec2(1.0));

    vec2 rn = vec2(0.);
    rn.x = SmoothNoise(uv + 1.984 * r + vec2(1.7,9.2)+ 0.158*time );
    rn.y = SmoothNoise(uv + 1. * r + vec2(8.3,2.8)+ 0.126*time);
    
    col += SmoothNoise(uv+rn*2.5);

    glFragColor = vec4(col,1.0);
}
