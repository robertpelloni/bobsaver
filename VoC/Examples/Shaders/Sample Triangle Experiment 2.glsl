#version 420

// original https://www.shadertoy.com/view/3lsSzj

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
float dtoa(float d, float amount){
    return 1. / clamp(d*amount, 1., amount);
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
const float C = sqrt(3.)/3.; // dist from center to 
float sdEquilateralTriangle(in vec2 p)
{
    p.y += C; // anchor center
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    if( p.x + k*p.y > 0.0 ) p = vec2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x += 2.0 - 2.0*clamp( (p.x+2.0)/2.0, 0.0, 1.0 );
    return -length(p)*sign(p.y);
}
// end boilerplate ======================

float scurve(float x, float p) {
    x = x / p * PI2;
    return (x + sin(x+PI)) / PI2;
}

void sdthing(inout float sd, inout float sd2, vec2 uv, float a, float scale) {
    sd2 = opXor(sd2, sdEquilateralTriangle(uv*scale));
    sd = opXor(sd, sdEquilateralTriangle(scale*(((uv + vec2(0,-C*2.)) * rot2D(a - PI/3.)) - vec2(1.,C))));
    sd = opXor(sd, sdEquilateralTriangle(scale*(((uv + vec2(-1.,C)) * rot2D(a+PI)) - vec2(1.,C))));
    sd = opXor(sd, sdEquilateralTriangle(scale*(((uv + vec2(1.,C)) * rot2D(a + PI/3.)) - vec2(1.,C))));
}

vec4 thing(vec2 uv, float s) {
    vec2 modperiod = vec2(8., 12.*C);
    uv = mod(uv+modperiod*.5, modperiod) - modperiod*.5;
    
    float t = s*time*.6;
    if (s < 0.)
        t = scurve(t, 1.) * .5;

    float sd = 1e6, sd2=sd;
    // bank 1
    float seg = mod(t, 3.);
    float a = fract(seg) * PI * 4./3.;
    sdthing(sd, sd2, uv, a, 1.);
    sdthing(sd, sd2, uv, a, 3.);
    
    // bank 2
    uv = mod(uv + modperiod, modperiod) - modperiod*.5;
    seg = mod(-t+.5, 3.);
    a = fract(seg) * PI * 4./3.;
    sdthing(sd, sd2, uv, a, 1.);
    sdthing(sd, sd2, uv, a, 3.);

    vec4 o;
    o.rgb = dtoa(sd, 3.*vec3(400,400,20)) * .5;
    o.rgb += dtoa(sd2, 1.*vec3(5,40,80)) * .8;
    o = pow(o, o-o+4.);
    o.br *= rot2D(sd*.6);
    o = clamp(o,o-o,o-o+1.);
    o.a = min(sd,sd2);
    return o;
}

void main(void)
{
    vec4 o = glFragColor;
    vec2 uvorig = gl_FragCoord.xy/resolution.xy-.5;
    uvorig.x *= resolution.x / resolution.y;
    //uvorig.x += time*.1;
    uvorig *= 8.;
    vec2 uv = uvorig;

    o = thing(uv*3., 1.) * .5;
    o = vec4(o.r*dtoa(-o.a,40.)*.05);
    vec4 fore = thing(uv, -1.);
    o = mix(o, fore, dtoa(fore.a,2000.));
        
    vec2 N = gl_FragCoord.xy / resolution.xy-.5;

    o = pow(o, o-o+.5);
    o.rgb += (hash32(gl_FragCoord.xy+time)-.5)*.08;
    o.rgb += dot(N,N) * vec3(.2,.5,1);
    o = clamp(o,o-o,o-o+1.);
    o *= 1.-length(12.*pow(abs(N), vec2(4.)));// vingette
    o.a = 1.;

    glFragColor = o;
}

