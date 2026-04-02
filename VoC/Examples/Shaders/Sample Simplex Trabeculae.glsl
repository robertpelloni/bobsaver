#version 420

// original https://www.shadertoy.com/view/3tXcRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 256
#define TMAX 100.
#define PRECIS .0001

#define r(a) mat2( cos(a), -sin(a), sin(a), cos(a) )

#define shaded 0

vec3 hash33(vec3 c, float r) {
    vec3 h = .5*normalize(fract(vec3(8., 1., 64.)*sin( dot(vec3(17., 59.4, 15.), c) )*32768.)-.5);
    return mix(vec3(.4), h, r); // attenuate randomness (make sure everything on the path of the camera is not random)
}

/* 3d simplex noise from candycat's "Noise Lab (3D)" https://www.shadertoy.com/view/4sc3z2
based on the one by nikat: https://www.shadertoy.com/view/XsX3zB */
vec4 simplex_noise(vec3 p, float r) {
    
    const float K1 = .333333333;
    const float K2 = .166666667;
    
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    vec3 e = step(vec3(0.), d0 - d0.yzx);
    vec3 i1 = e * (1. - e.zxy);
    vec3 i2 = 1. - e.zxy * (1. - e);
    
    vec3 d1 = d0 - (i1 - 1. * K2);
    vec3 d2 = d0 - (i2 - 2. * K2);
    vec3 d3 = d0 - (1. - 3. * K2);
    
    vec4 h = max(.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33(i, r)), dot(d1, hash33(i + i1, r)), dot(d2, hash33(i + i2, r)), dot(d3, hash33(i + 1., r)));
    
    return 70.*n;
}

// see https://www.shadertoy.com/view/ttsyRB
vec4 variations(vec4 n) {
    vec4 an = abs(n);
    vec4 s = vec4(
        dot( n, vec4(1.) ),
        dot( an,vec4(1.) ),
        length(n),
        max(max(max(an.x, an.y), an.z), an.w) );
    
    float t =.27;
    
    return vec4(
        // worms
        max(0., 1.25*( s.y*t-abs(s.x) )/t),
        // cells (trabeculae)
        pow( (1.+t)*( (1.-t)+(s.y-s.w/t)*t), 2.), //step( .7, (1.+t)*( (1.-t)+(s.y-s.w/t)*t) ),
        .75*s.y,
        .5+.5*s.x);
}

float map(vec3 p) {
    float c = smoothstep(0., 1., length(p.xy)-.1); // controls the randomness
    p += vec3(-.65, .35, 44.85);
    float s = 1.;
    float n = variations( simplex_noise(p*s*.5, c) ).y;
    n = .78-n;
    n /= s*4.;
    
    return n;
}

float march(vec3 ro, vec3 rd) {
    float t = .01;
    for(int i; i<STEPS; i++) {
        float h = map(ro + rd * t);
        t += h;
        if(t>TMAX || abs(h)<PRECIS) break;
    }
    return t;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.4, 0);
    return normalize(
        map(p) - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx)
        ) );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 ro; ro.z = time*.67;
    vec3 rd = vec3(uv, .5);
    
    vec3 l = normalize( vec3(-3,2,1) );
    
    float fc = exp2( .5*dot(rd, l) )*.5;
    
    float t = march(ro, rd);
    vec3 p = ro + rd * t;
    
    float dif;
#if shaded
    vec3 n = normal(p);
    dif = dot(n, l)*.5+.5;
    dif *= .125;
#endif
    
    float fog = pow(1.-.05/(t*.75+.5), 25.);
    float v = mix(dif, fc, fog);
    v *= v;
    
    vec3 col = 1.-vec3(.67, .45, .05);
    col = pow(vec3(v), col*1.5 );
    
    col = smoothstep(0., 1., 2.3*col);
    
    glFragColor = vec4(col, 1);
}
