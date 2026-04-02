#version 420

// original https://www.shadertoy.com/view/csyyRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define TWOPI 6.2831853
#define SS2 0.7071067
#define R vec2(1.,0.)
#define I vec2(0.,1.)

#define iters 100

vec2 cmul(vec2 z, vec2 c) {
    return vec2(z.x * c.x - z.y * c.y, z.x * c.y + z.y * c.x);
}

vec2 cdiv(vec2 z, vec2 c) {
    float r = dot(c, c);
    return vec2(z.x * c.x + z.y * c.y, z.y * c.x - z.x * c.y) / r;
}

vec2 conj(vec2 z) {
    return vec2(z.x, -z.y);
}

vec2 cexp(vec2 z) {
    return vec2(cos(z.y),sin(z.y)) * exp(z.x);
}

vec2 clog(vec2 z) {
    return vec2(0.5 * log(dot(z,z)), atan(z.y,z.x));
}

vec2 mobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d) {
    return cdiv(cmul(a,z)+b, cmul(c,z)+d);
}

vec2 csqrt(vec2 z) {
    float s = length(z);
    return vec2(sqrt(s + z.x), float(sign(z.y)) * sqrt(s - z.x)) * SS2;
}

vec2 casinh(vec2 z) {
    return clog(z + csqrt(cmul(z,z)+1.));
}

vec2 catanh(vec2 z) {
    return clog(mobius(z,R,R,-R,R));
}

vec2 pdj(vec2 z, float a, float b, float c, float d) {
    float nx1 = cos(b * z.x);
    float nx2 = sin(c * z.x);
    float ny1 = sin(a * z.y);
    float ny2 = cos(d * z.y);
    return vec2(ny1 - nx1, nx2 - ny2);
}

vec2 pdjit(vec2 z, float a, float b, float c, float d, float N, int iterations) {
    for(int i = 0; i < iterations; i++) {
        z = z + 0.2*pdj(z,a,b,c,d);
        z = cmul(z, cexp(I * TWOPI/N));
    }
    return z;
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - 0.5*resolution.xy) / -resolution.y;

    uv *= 1.25;

    float d = dot(uv,uv);
    float l = sqrt(d);

    float gap = 0.0;

    float r = d>1.?acosh(l/(1.+gap))+exp(l/(1.+gap)):asin(l*(1.+gap))*2.;
    float a = d>1.?atan(-uv.y,-uv.x) : atan(uv.y,uv.x);
    uv = (r) * vec2(cos(a),sin(a));
    
    uv += (vec2(sin(time),cos(time))*4.);

    uv *= 0.25;
    
    for(int i = 0; i < 7; i++) {

        uv = cexp(clog(cmul(vec2(SS2),mobius(uv,R,-R,R,R)))*2.);
    
    }

    uv = cexp(clog(mobius(uv,R,-R,R,R))*2.);
    
    uv = catanh(uv);

    uv *= 8.;

    float N = 6.;

    uv = pdjit(uv,2.,0.,0.,1.,N,iters);

    vec3 col = (0.5 + 0.5*cos(uv.y*0.25+vec3(0,1,2)));
    col = col + 0.1 * tanh(col);

    glFragColor = vec4(col,1.0);
}
