#version 420

// original https://www.shadertoy.com/view/WdSBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 rainbowDisk(vec2 o) {
    // the underlying image
    // source: https://www.shadertoy.com/view/XsSfW1 by Flyguy
    o *= max(resolution.x, resolution.y);
    o += .5 * resolution.xy;
    vec4 c;
    vec2 r = resolution.xy;
    o = vec2(length(o -= r/2.) / r.y - .3, atan(o.y,o.x));    
    vec4 s = c.yzwx = .1*cos(1.6*vec4(0,1,2,3) + time + o.y + sin(o.y) * sin(time)*2.),
    f = min(o.x-s, c-o.x);
    return dot(40.*(s-c), clamp(f*r.y, 0., 1.)) * (s-.1) - f;
}

void main(void) {
    float t = time;
    t = mod(t, 30.);
    float res = max(resolution.x, resolution.y);
    float maxScale = res / 9.;
    // zoom in and out
    float scale = mix(
        4.,  maxScale,
        smoothstep(2., 15., t) - smoothstep(20., 30., t)
    );
    vec2 off = vec2(-.2, .1);
    vec2 uv = scale * ((gl_FragCoord.xy - .5 * resolution.xy) / res - off);
    float pixel = scale / res;

    vec2 pixeluv = fract(uv);
    vec2 imguv = (floor(uv)) / maxScale + off;
    
    vec3 colImg = rainbowDisk(imguv).rgb;
    // make the loop seemless
    colImg = mix(
        // just something to pseudo random
        fract(vec3(
            sin(300.123 * imguv.x + 300.123 * imguv.y),
            sin(100.521 * imguv.y - 250.2 * imguv.x),
            0.4)),
        colImg, smoothstep(0., .1, t) - smoothstep(29.9, 30., t));
    colImg = clamp(colImg, .1, .9);

    vec3 col = vec3(0.);
    col.r = smoothstep(
        pixel, 0.,
        max(
            pixeluv.y - colImg.r,
            pixeluv.x - 0.3333333 + pixel
        )
    );
    col.g = smoothstep(
        pixel, 0.,
        max(
            pixeluv.y - colImg.g,
            max(pixeluv.x - 0.666666 + pixel,
                0.333333 - pixeluv.x + pixel)
        )
    );
    col.b = smoothstep(
        pixel, 0.,
        max(
            pixeluv.y - colImg.b,
            0.666 - pixeluv.x + pixel
        )
    );
    col *= smoothstep(
        0., 4. * pixel * smoothstep(10., 1., scale),
        min(
            min(pixeluv.y, 1. - pixeluv.y),
            min(pixeluv.x, 1. - pixeluv.x)
        )
    );
    glFragColor = vec4(col, 1.0);
}
