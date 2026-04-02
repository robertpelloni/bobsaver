#version 420

// original https://www.shadertoy.com/view/3sSXzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// comment out glow to gain performance
#define GLOW

vec2 noise(vec2 p) {
    return fract(123.1234 * sin(123.1234 * (fract(123.1234 * p) + p.yx)));
}

float dist(vec2 uv) {
    uv *= uv;
    uv *= uv;
    return sqrt(uv.x + uv.y) - 1.;
}

vec3 col(float d, float g) {
    vec2 n = g * vec2(.5, 1.);
    vec2 b = smoothstep(vec2(0.), vec2(-.75, -1.5), vec2(d)) * n;
    b.y += b.x * 2.;
    return vec3(0., b.x,  b.y);
}

float ripples(vec2 oid) {
    vec2 rui = oid * .2;
    vec2 ruiId = floor(rui);
    rui = fract(rui) - .5;
    float g = 0.02;
    for (float i = -1.; i < 1.5; i++) {
        for (float j = -1.; j < 1.5; j++) {
            vec2 lId = ruiId + vec2(i, j);
            vec2 luv = rui - vec2(i, j);
            float n = .8 * noise(lId).x + .2;
            float t = mod(time + 100., n * 100.);
            float d = dot(luv, luv);
            float o = 1.;
            g = max(g, 2. * smoothstep(t, t + o, d) * smoothstep(t + o, t, d) 
                        * smoothstep(2., 1.8, d));
        }
    }
    return g;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec2 uv2 = uv;
    
    float z = uv.y - 1.;
    uv /= z;
    uv.y -= time * .3;
    
    float tiling = 10.;
    uv *= tiling;
    vec2 oid = floor(uv);
    vec2 id = oid;// + floor(sin(floor(time/3.)) * 30.);
    uv = fract(uv) * 2. - 1.;
    
    float h = .3;
    for (float i = 0.; i < 10.; i++) {
        float d = dist(uv);
        if (-d > h)
            break;
        uv -= vec2(uv2.x, -z) * .01;
        h -= .01;
    }
    
    vec3 c = vec3(0.);
    #ifdef GLOW
    for (float i = -1.; i < 1.5; i += 1.) {
        for (float j = -1.; j < 1.5; j += 1.) {
            for (float k = 0.; k < 8.; k++) {
                vec2 uv2c = uv - vec2(i, j) * 2.;
                 c += col(dist(uv2c * (1. - k * .085)), ripples(id + vec2(i, j)));
            }
        }
    }
    #endif
    
    float fft = 0.0; //texelFetch(iChannel0, ivec2(1, 0), 0).x;
    vec3 f = c * .1 * (fft) + col(dist(uv), ripples(id));
    
    f = mix(f, (fft*.5+.5) * vec3(0., gl_FragCoord.y / resolution.y * .75, gl_FragCoord.y / resolution.y),smoothstep(0.5, .9, gl_FragCoord.y / resolution.y * .85));
    glFragColor = vec4(f, 1.0);

}
