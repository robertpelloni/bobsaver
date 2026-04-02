#version 420

// original https://www.shadertoy.com/view/XscBzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_OCTAVES 6
#define FBM_NOISE_FUNCTION worley2

float rnd(vec2 u) { return fract(3e5 * sin(dot(u, vec2(1, 78)))); }

vec2 rnd2( vec2 p ) {
    vec2 q = vec2( dot(p,vec2(127.1,311.7)),
                   dot(p,vec2(269.5,183.3)));
    return fract(sin(q)*43758.5453);
}

float valueNoise(vec2 u)
{
    vec2 i = floor(u), f = u-i,
    X = vec2(rnd(i), rnd(i+vec2(1, 0))),
    Y = vec2(rnd(i + vec2(0, 1)), rnd(i + 1.));
    f *= f*(3. - 2.*f);
    u = mix(X, Y, f.y);
    return mix(u.x, u.y, f.x);
}

vec2 valueNoise2(vec2 u) {
    vec2 i = floor(u), f = u-i,
    X = vec2(rnd(i), rnd(i+vec2(1, 0))),
    Y = vec2(rnd(i + vec2(0, 1)), rnd(i + 1.));
    f *= f*(3. - 2.*f);
    u = mix(X, Y, f.y);
    return u;
}

// input, rotation angle, scaling, translation
vec2 rigidTransform(vec2 p, float theta, float scale, vec2 t) {
    float c = cos(theta), s = sin(theta);
    return scale * (mat2(c, s, -s, c) * p) + t;
}

vec2 spin(vec2 u) { return .5 + .5 * sin(time + 6.2831*u); }

#define WORLEY_ANIMATION spin
float worley(vec2 u) {
    float d = 1e3, a;
    vec2 k =  floor(u), f = u-k, p, q = k + vec2(0, 0);
    for(int i = -1; i < 2; i++) {
        for(int j = -1; j < 2; j++) {
            p = WORLEY_ANIMATION(valueNoise2(k+vec2(i, j)));
            a = distance(f, vec2(i, j) + p);
            if(a < d) {
                d = a;
                q = p;
            }
    } }
    return dot(q, vec2(.3,.6));
}

float worley2(vec2 u) {
    float d = 1e4, a;
    float acc = 0., acc_w = 0.;
    vec2 k =  floor(u), f = u-k, p, q = k + vec2(0, 0);
    for(int i = -3; i < 3; i++) {
        for(int j = -3; j < 3; j++) {
            vec2 p_i = vec2(i, j);
            vec2 p_f = WORLEY_ANIMATION(rnd2(k+p_i));
            float d = length(p_i - f + p_f);
            float w = exp(-8. * d);
            acc += w * d;
            acc_w += w;
    } }
    return acc / acc_w;
}

float worley3(vec2 u) {
    float d = 1e4, a;
    float acc = 0., acc_w = 0.;
    vec2 k =  floor(u), f = u-k, p, q = k + vec2(0, 0);
    const int r = 3;
    for(int i = -r; i < r; i++) {
        for(int j = -r; j < r; j++) {
            vec2 p_i = vec2(i, j);
            vec2 p_f = WORLEY_ANIMATION(rnd2(k+p_i));
            float d = length(p_i - f + p_f);
            float w = exp(-8. * d) * (1.-step(sqrt(float(r*r)),d));
            acc += w * valueNoise(k+p_i);
            acc_w += w;
    } }
    return acc / acc_w;
}

float fbm(vec2 u) {
    float v = 0.;
    for(int i = 0; i < NUM_OCTAVES; i++) {
        v += pow(.5, float(i+1)) * FBM_NOISE_FUNCTION(u);
        u = rigidTransform(u, .5, 2., vec2(1e3));
    }
    return v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 p = uv * 3.;
    vec3 col = vec3(0.);
    float f = fbm( p );
    //f = fbm( p + f);
    //f = fbm( p + f);
    
    col += f;

    glFragColor = vec4(col,1.0);
}
