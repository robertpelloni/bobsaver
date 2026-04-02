#version 420

// original https://www.shadertoy.com/view/WlsXDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 genRotMat(float val){
    return mat2(cos(val),-sin(val),sin(val),cos(val));
}
float PI = 3.14159265;
float map(vec3 p){
    p.x = fract(abs(p.x) / 1.5) * 1.5;
    p.y = fract(abs(p.y) / 1.5) * 1.5;
    p.z = fract(abs(p.z) / 0.5) * 0.5;
    p -= vec3(0.75,0.75,0.25);

    p.xy *= genRotMat(time * 2.0);
    float gear_out = max(length(p.xy) - 0.5 + 0.05 * floor(1.0 * sin(12.0 * atan(p.y,p.x)))
              ,abs(p.z) - 0.05);
    float gear_in = max(length(p.xy) - 0.2 + 0.05 * floor(1.0 * sin(12.0 * atan(p.y,p.x)))
              ,abs(p.z) - 0.1);
    return max(gear_out, -gear_in);
}

const float EPS = 0.001;
vec3 getNormal(vec3 p) {
    return normalize(vec3(
        map(p + vec3(EPS, 0.0, 0.0)) - map(p + vec3(-EPS,  0.0,  0.0)),
        map(p + vec3(0.0, EPS, 0.0)) - map(p + vec3( 0.0, -EPS,  0.0)),
        map(p + vec3(0.0, 0.0, EPS)) - map(p + vec3( 0.0,  0.0, -EPS))
    ));
}

vec4 trace (vec3 o, vec3 r){
    float t = 0.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 96; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    return vec4(getNormal(p),t);
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    // Normalized pixel coordinates (from 0 to 1)
    vec3 R = vec3(resolution,1.0),
    r = normalize(vec3((2.*U - R.xy )/  R.y,1.2)),
    o = vec3(0.75 + 0.75 * sin(time),0.75 + 0.75 * cos(time),-1.0 + time * 1.5);
    vec4 data = trace(o,r);
    vec3 n = vec3(data.xyz);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.05);
    vec3 fc = t > 10000.0 ? vec3(0.8) : mix((vec3(data.x,data.y,data.z) + 1.0)/1.5
                                            ,vec3(0.0), - pow(dot(n,r),1.0));
    fc = mix(fc,vec3(1.0),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
