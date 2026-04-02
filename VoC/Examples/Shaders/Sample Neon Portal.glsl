#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlXSzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159;
const float PI2 = PI*2.;

float dtoa(float d, float amount){
    return 1. / clamp(d*amount, 1., amount);
}
float nsin(float x) {
    return cos(x)*.5+.5;
}
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 19.19;
    p *= p + p;
    return fract(p);
}

float check(float a, float r, float t) {
    if (r < 0.0001) return 0.;
    float z = 1./r;
    z-=t;
    a += sin(z);
    return min(min(nsin(a*4.),nsin(a*14.)),pow(nsin(z*24.),.4));
}

void main(void)
{
    vec4 o = glFragColor;
    //vec2 in = gl_FragCoord.xy;

    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    vec2 N = uv;
    uv.x *= resolution.x / resolution.y;

    float t = -time + 2.;

    float sd = 1e6;
    float a = atan(uv.x,uv.y);
    
    float ch = check(a+t*.1, length(uv), t);
    o.rgb = N.xyy * vec3(ch) * pow(length(uv),2.) * 4.;
    
    float sg = 3.;
    float r = .44;
    float bh = 1.;
    for (int i = 0; i < 40; ++ i) {
        float id = hash11(float(i));
        sg = -sg;
        r *= .96;
        float h = nsin(a += id*PI2)*.05+.01;
        h *= bh-= .03;
        float rout = nsin((a)*18.)*pow(nsin(8.*a+t*sg),2.)*h+r;
        sd = abs(length(uv)-rout);
        o[i%3] += dtoa(sd, nsin(t)*1000. + 250.);
    }

    o.g += o.r*.4;
    o = clamp(o,o-o,o-o+1.);
    o = pow(o,o-o+.5);
    o.rgb -= (hash32(gl_FragCoord.xy+time))*.1;//noise
    o *= 1.-length(12.*pow(abs(N), vec2(4.)));// vingette
    o.a = 1.;

    glFragColor = o;
}
