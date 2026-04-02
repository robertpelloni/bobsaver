#version 420

// original https://www.shadertoy.com/view/fdlXz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec2 s = vec2(1., 1.7320508);

float hexSDF(vec2 p){
    p = abs(p);
    return max(dot(p, s * 0.5), p.x);
}

vec4 hexTiling(vec2 p){ 
    vec4 centers = round(vec4(p, p - vec2(0.5, 1.)) / s.xyxy);
    vec4 offsets = vec4(p - centers.xy * s, p - (centers.zw + 0.5) * s);
    
    vec2 oxy = offsets.xy;
    vec2 ozw = offsets.zw;
    
    //return dot(oxy, oxy) > dot(ozw, ozw) ? vec4(ozw, centers.zw * s) : vec4(oxy, centers.xy * s);
    
    // branchless version of the above ternary operator
    float comp = step(0., dot(oxy, oxy) - dot(ozw, ozw));
    return vec4(ozw, centers.zw * s) * comp + vec4(oxy, centers.xy * s) * (1.-comp);
}

float hash(vec2 p){
    return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453123);
}

float clamp01(float x){
    return clamp(x, 0., 1.);
}

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c,-s,s,c);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;

    vec3 col = vec3(0.);
    
    vec4 h = hexTiling(uv*rot(sin(time*0.2)*0.5)*5. + time*0.3);
    float d = hexSDF(h.xy);
    
    float rand = hash(h.wz);
    
    float w = 6.283*12.;
    float i = clamp01(sin(d*w)+0.8);
    float t = mod(floor(time*10.+rand*123.475), 6.);
    float clear = step(0.5, rand);
    float unc = 1. - clear;
    float q = step(0.076*t, d) * step(d, 0.076*(t+1.)) * unc;
    
    col = vec3(1.,0.5,0.5);
    float shad = step(0., dot(h.xy, vec2(0.5, 0.8660254))) * clear;
    
    vec3 stripes = mix(vec3(1.,0.,0.), vec3(0.,0.2,1.), rand);
    col = stripes * q + col * (1.-q) * (2.*unc*d+1.-unc-d);
    col *= i;
    
    float glow = step(0.9, rand) * (clear > 0. ? 1. : 0.);
    col *= shad > 0. ? vec3(0.5,0.6,0.7) : vec3(1.);
    
    float g = clamp01(pow(abs(sin(time)), 12.)+0.1);
    if(glow > 0.) col = mix(col, col + vec3(0.6, 0.1, 0.29), g);
    
    float k = clear * 0.08;
    col *= 1.-pow(abs(d+k)+0.5, 12.);

    glFragColor = vec4(col,1.0);
}
