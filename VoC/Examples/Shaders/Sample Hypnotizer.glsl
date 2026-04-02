#version 420

// original https://neort.io/art/bnhred43p9f5erb52uqg

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
#define cdiv(a,b) ( cmul(a, cinv(b)) )
#define cexp(a)   ( exp((a).x)* vec2(cos((a).y), sin((a).y)) )
#define clog(a)     vec2( log(length(a)), atan((a).y,(a).x) )
#define arg(a)    ( atan(a.y, a.x) )
#define cpow(a,n)   cexp( float(n)* clog(a) )
#define round(x)    floor(x + 0.5)

void main(void)
{
    vec2 res = resolution.xy,
          z = ( gl_FragCoord.xy* 2. - res) / min(res.x, res.y);

    float t = time;
    float scale = 7.;
    z *= scale;
    
    vec2 f =  cexp(z) + cexp(-z) + cexp(vec2(0, t));
    float r = length(f - round(f));
    float th = arg(cmul(f, cexp(vec2(0., t* length(z) * 0.2))));

    glFragColor = vec4((hsvToRgb(th, 0.5/r, 0.5/r) + vec3(0., 0., 1.)) / 2., 1.);
}
