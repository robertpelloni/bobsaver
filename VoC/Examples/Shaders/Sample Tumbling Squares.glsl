#version 420

// original https://www.shadertoy.com/view/wlfXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// boilerplate ======================
const float PI = 3.14159;
const float PI2 = PI*2.;

vec3 dtoa(float d, vec3 amount){
    return vec3(1. / clamp(d*amount, vec3(1), amount));
}
mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}
float nsin(float x) {
    return cos(x)*.5+.5;
}
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
float opUnion( float d1, float d2 ) { return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float opIntersection( float d1, float d2 ) { return max(d1,d2); }
float opXor(float lhs, float rhs) {
    return opUnion(opIntersection(lhs, -(rhs)), opIntersection(rhs, -(lhs)));
}

float sdSquare(vec2 p, vec2 center, float s) {
    vec2 d = abs(p-center) - s;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}
// end boilerplate ======================

const float th = 1./3.;
float hello(float sd, vec2 uv, float off, float a, vec2 sgn) {
    sd = opXor(sd, sdSquare((uv + sgn*vec2(.5,.5)+vec2(-off,0)) * rot2D(a), vec2(-th*.5), th*.5));
    sd = opXor(sd, sdSquare((uv + sgn*vec2(-.5,.5)+vec2(0,-off)) * rot2D(a+PI*.5), vec2(-th*.5), th*.5));
    sd = opXor(sd, sdSquare((uv + sgn*vec2(.5,-.5)+vec2(0,off)) * rot2D(a-PI*.5), vec2(-th*.5), th*.5));
    sd = opXor(sd, sdSquare((uv + sgn*vec2(-.5,-.5)+vec2(off,0)) * rot2D(a-PI), vec2(-th*.5), th*.5));
    return sd;
}

float scurve(float x, float p) {
    x = x / p * PI2;
    return (x + sin(x+PI)) / PI2;
}

void main(void) //WARNING - variables void ( out vec4 o, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_FragCoord
{
    vec4 o = glFragColor;
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    uv.x *= resolution.x / resolution.y;
    
    uv *= 2.8;
    float tsteady = time*.25;
    float t = scurve(tsteady, th);
    float sd = 1e6;
    float sdout = 1e6;
    
    uv *= rot2D(-tsteady*PI2*.25);
    float r = .5+(sqrt(2.)*th);
    uv -= r;
    float padding = .1; // kinda important because blurriness doesn't cross cells
    uv = mod(uv, r+r+padding)-r-padding*.5; // repetition

    float seg = mod(t, 3.);
    float aout = fract(seg)*PI*.5;
    float ain = -(aout+PI*.5);
    float offout = 0.;
    float offin = th*2.;
    if (seg >= 2.) {
        aout = (fract(seg)-.5)*PI;
        ain = PI;
    } else if (seg >= 1.) {
        offout = th*2.;
    } else {
        offout = th;
        offin = th;
    }

    float tsel = mod(t/3., 3.);
    bool A = false, B = false, C = false, D = false;
    
    if (tsel >= 2.) {
        // (none)
    } else if (tsel >= 1.) {
        // (big plus)
        A = B = true;
    } else {
        // (minimal + outline)
        B = C = D = true;
    }
    
    if (A) sd = sdSquare(uv, vec2(0),.5);
       if (B) sd = opXor(sd, sdSquare(uv, vec2(0),r));
       if (C) sd = opXor(sd, sdSquare(uv, vec2(0),r));
    if (D) sd = hello(sd, uv, offout, aout, vec2(1));
    
    sdout = hello(sdout, uv, offout, aout, vec2(1));
    sd = hello(sd, uv, offout, aout, vec2(1));
    sd = hello(sd, uv, offin, ain, vec2(1));

    o.rgb = dtoa(sd, 3.*vec3(50.,100.,200.)) * vec3(.9,.9,.8);
    o.rgb += dtoa(sdout, 2.*vec3(100.,50.,50.)) * vec3(.1,-.8,.4);
    
    vec2 N = gl_FragCoord.xy / resolution.xy-.5;

    o.rgb += (hash32(gl_FragCoord.xy+t)-.5)*.1;
    o.rgb += dot(N,N) * vec3(.2,.5,1);
    o = clamp(o,o-o,o-o+1.);
    o *= 1.-length(9.*pow(abs(N), vec2(3.)));// vingette
    o.a = 1.;

    glFragColor = o;
}

