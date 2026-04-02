#version 420

// original https://neort.io/art/bnbqhus3p9f5erb52c70

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

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

//operations on complex numbers borrowed from
//https://shadertoyunofficial.wordpress.com/2019/01/02/programming-tricks-in-shadertoy-glsl/
#define re(a) vec2((a).x, 0.)
#define im(a) vec2(0., (a).y)
#define cmul(a,b) ( mat2(a, -(a).y, (a).x ) * (b) )
#define conj(a)     vec2( (a).x, -(a).y)
#define cinv(a)   ( conj(a) / dot(a, a) )
#define cexp(a)   ( exp((a).x)* vec2(cos((a).y), sin((a).y)) )
#define clog(a)     vec2( log(length(a)), atan((a).y,(a).x) )
#define cpow(a,n)   cexp( float(n)* clog(a) )

void main()
{
    vec2 res = resolution.xy,
          z = ( gl_FragCoord.xy* 2. - res) / min(res.x, res.y);

    float t = time;
    float scale = 1.5;
    z *= scale;
        
    const float delta = 0.1;
    #define f(w)    (cpow(w, 5) + cmul(cpow(w, 4), cexp(vec2(sin(t), t))) + tan(-0.3* t)* cpow(w, 3) +tan(0.21* t)* cpow(w, 2) + cmul(w, cexp(vec2(0., t))) + cexp(vec2(0., -1.47* t)))
    #define df(w)    (f(w + vec2(delta, 0.)) - f(w - vec2(delta, 0.))) / (2.* delta)
    #define ddf(w)    (df(w + vec2(delta, 0.)) - df(w - vec2(delta, 0.))) / (2.* delta)
    #define dddf(w)    (ddf(w + vec2(delta, 0.)) - ddf(w - vec2(delta, 0.))) / (2.* delta)
      
    float l = length(f(z));
    float ld = length(df(z));
    float ldd = length(ddf(z));
    float lddd = length(dddf(z));

    glFragColor = vec4(vec3(.01/ abs(l - 1.)) + vec3(.01/ abs(ld - 1.), .01/ abs(ldd - 1.), .01/ abs(lddd - 1.)), 1.);
}
