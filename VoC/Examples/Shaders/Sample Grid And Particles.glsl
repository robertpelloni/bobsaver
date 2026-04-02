#version 420

// original https://www.shadertoy.com/view/3sScDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 one = vec2(1., 0.);

uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec3 orientation;

float hash(vec2 x) {
    return fract(cos(
        dot(x, vec2(672.529,198.3862))
        )*9857.733);
}

float noise(vec2 x) {
    vec2 ix =floor(x);
    vec2 fx = fract(x);
    fx=fx*fx*(3.-2.*fx);

    float bl = hash(ix);
    float br = hash(ix+one.xy);
    float tl = hash(ix+one.yx);
    float tr = hash(ix+one.xx);

    return mix(
        mix(bl, br, fx.x),
        mix(tl, tr, fx.x),
        fx.y);
}

float fbm(vec2 p) {
    return (
        .5* noise(p)
        + .25* noise(p*2.1)
        + .175* noise(p*3.9)
        + .0875* noise(p*8.2)
    );
}

vec2 pat(vec2 uv) {
    return vec2(
        noise(floor(uv) + time),
        noise(floor(uv) + time + 3.53));
}

float dist(vec2 d, vec2 x) {
    float c = dot(d, x) / dot(d, d);
    if (sign(c) < 0.) {
        return 1000.;
    } else {
        return length(x - c*d);
    }
}

float particles(vec2 uv) {
    vec2 p = pat(uv);
    vec2 pr = pat(uv+one)+one;
    vec2 pl = pat(uv-one)-one;
    vec2 pu = pat(uv+one.yx)+one.yx;
    vec2 pb = pat(uv-one.yx)-one.yx;
    vec2 pbr = pat(uv+one.xx)+one.xx;
    vec2 pul = pat(uv-one.xx)-one.xx;

    vec2 dhere = fract(uv)-p;
    vec2 ppl = pl-p;
    vec2 ppr = pr-p;
    vec2 ppu = pu-p;
    vec2 ppb = pb-p;

    float upl = dist(normalize(ppl), dhere);
    float upr = dist(normalize(ppr), dhere);
    float upu = dist(normalize(ppu), dhere);
    float upb = dist(normalize(ppb), dhere);

    return 1.-smoothstep(.02, .2, length(dhere))
        + .5/pow(length(ppl), 4.)*smoothstep(.03, .01, upl)
        + .5/pow(length(ppr), 4.)*smoothstep(.03, .01, upr)
        + .5/pow(length(ppu), 4.)*smoothstep(.03, .01, upu)
        + .5/pow(length(ppb), 4.)*smoothstep(.03, .01, upb)
        + .5/(length(ppb)+1.);
}

void main(void) {
    float mx = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy/mx;
    vec3 color = vec3(.1,.4,.5);
    color = mix(color, vec3(.9), particles(uv*10.));
    glFragColor = vec4(color, 1.0);
}
