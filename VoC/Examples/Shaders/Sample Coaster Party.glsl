#version 420

// original https://www.shadertoy.com/view/tlsXz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592654;

vec3 hash32(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
vec4 disco(vec2 uv) {
    float v = abs(cos(uv.x * PI * 2.) + cos(uv.y *PI * 2.)) * .5;
    uv.x -= .5;
    vec3 cid2 = hash32(vec2(floor(uv.x - uv.y), floor(uv.x + uv.y))); // generate a color
    return vec4(cid2, v);
}
mat2 rot2D(float r){
    float c = cos(r), s = sin(r);
    return mat2(c, s, -s, c);
}
vec2 warp(vec2 uv, float f, out float sd) {
    float d = length(mod(uv+1.,2.)-1.);
    sd = d-1.;
    return uv*f*(1.-d);
}

vec4 purty(vec2 V, float t, float f) {
    float t2 = t*.2;
    V *= rot2D(t2*.25);
    V += vec2(sin(t2), cos(t2));

    float sd;
    vec2 uvP = warp(V, f, sd);

    uvP += t*.2;

    vec4 d = disco(uvP);
    vec3 col = d.rgb * pow(d.a, .15);

    col.rg *= rot2D(.1);
    col.br *= rot2D(-.2);

    float a = pow(smoothstep(0.,1.,-sd), .4);
    return vec4(col, a);
}
void main(void)
{
    vec4 o = glFragColor;
    vec2 O = gl_FragCoord.xy;

    float t = time+1e3;
    vec2 R = resolution.xy
        ,V=(O-.5*R)/R.y
        ,N=O/R-.5
        ,P=O-R*.5;
    V *= 4.;
    
    vec4 p =purty(V, t, 4.);
    V += 1.;
    V = -V * 2.;
    vec4 p2 = purty(V, t, 1.);
    p2.rgb *= .15;
    p2.rgb = mix(p2.rgb,vec3(p2.r+p2.g+p2.b)/3.,.9);//desaturate

    o = mix(p2,p,smoothstep(0.,.05,p.a));//mix the lower layer where a = 0
    
    o=clamp(o,0.,1.);
    o = pow(o,o-o+.5);
    o *= 1.-dot(N,N*2.);
    o *= 1.-step(.42,abs(N.y));
    o.a= 1.;

    glFragColor = o;
}

