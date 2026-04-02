#version 420

// original https://www.shadertoy.com/view/WljSzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float v){
    return mat2(cos(v),-sin(v),sin(v),cos(v));
}
vec3 pmod(vec3 p,float c){
    float tmp = PI * 2. / c;
    float l = length(p.xy);
    float theta = atan(p.y/p.x);
    theta = mod(theta,PI * 2. / c);
    return vec3(l * cos(theta), l * sin(theta),p.z);
    
}
vec3 cellMod(vec3 p,vec3 c){
    p.z = mod(p.z + c.z / 2.,c.z) - c.z/2.;
    p.x = mod(p.x + c.x / 2.,c.x) - c.x/2.;
    p.y = mod(p.y + c.y / 2.,c.y) - c.y/2.;
    return p;
}

float cube(vec3 p, vec3 o){
    return max(
        abs(p.x - o.x),
        max(abs(p.y - o.y),
            abs(p.z - o.z))
    );
}

float map(vec3 p){
    p.xy *= genRot(time);
    p = cellMod(p,vec3(2.0,2.0,0.5));
    p.xy *= genRot(PI / 12.);
    p = pmod(p,12.);
    p.xy *= genRot(-PI / 12.);

    float cu = cube(p,vec3(1.,0.,0.)) - 0.2;
    float sp = length(p - vec3(1.,0.,0.)) - 0.1;
    sp = min(sp,length(p.xz - vec2(1.,0.)) - 0.05);
    return mix(cu,sp,smoothstep(0.4,0.6,abs(fract(time/2.) - 0.5) * 2.0));

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
    vec3 R = vec3(resolution.xy,1.0),
    r = normalize(vec3((2.*U - R.xy )/  R.y,1.2)),
    o = vec3(0,0,-1.5 + time * 2.);
    r.yz *= genRot(time * PI / 8.);
    vec4 data = trace(o,r);
    vec3 n = vec3(data.xyz);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.05);
    float tmp = sqrt(dot(n,r));
vec3 fc = t > 10000.0 ? vec3(0.8) : mix((vec3(data.z) + 1.0)/1.5
                                            ,vec3(0.0), - pow(dot(n,r),1.0));
    fc = mix(fc,vec3(1.),1. - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
