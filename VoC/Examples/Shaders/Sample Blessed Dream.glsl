#version 420

// original https://www.shadertoy.com/view/Wt2XW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
vec3 modC(vec3 p,vec3 c){
    p = (fract(p / c + .5)-.5) * c;
    return p;
}
mat2 genRot(float v){
    return mat2(cos(v),-sin(v),sin(v),cos(v));
}
vec2 pMod(vec2 p,float c){
    p *= genRot(PI / c);
    float at = mod(atan(p.y/p.x),PI * 2./c);
    float r = length(p);
    p = vec2(r * cos(at),r * sin(at));
    p *= genRot(-PI /c);
    return p;
}

vec2 path(float t){
    vec2 r;
    r.x = sin(t) + 0.5 * cos(t * 2.);
    r.y = cos(t) + 0.5 * sin(t * 2.);
    return r;
}
float map(vec3 p){
    p.xy += path(p.z + time);
    vec3 r = p;
    p.xy = pMod(p.xy,12.);
    p = modC(p,vec3(4.,4.,1.5));
    vec3 q = p;
    q.x -= 1.5;
    q = abs(q);
    float cube = max(q.x,max(q.y / 4.,q.z)) - 0.25;
    float sp = length(p) - 0.3;
    float result = min(cube,sp);
    result = max(result,-(length(r.xy) - 0.5));
    return result;
}

float fog(float d){
    return 1./(1. + d * d * 0.01);
}

vec3 getColor(vec3 p){
    vec3 c = sin(p);
    c = c * 0.5 + 0.5;
    return vec3(c);
}

vec3 trace(vec3 o,vec3 r){
    vec3 volume = vec3(0.);
    float l = 0.05;
    for(int i = 0; i < 512; i++){
        vec3 p = o + r * float(i) * l;
        float d = map(p);
        vec3 c = getColor(p);
        volume += clamp(l- d,0.,l) * c * fog(float(i) * l);
    }
    return volume;
}

vec3 cam(){
    vec3 c = vec3(0.,0.,-1.5);
    c.z += time * 4.;
    //c += vec3(2.5 * sin(time/2.),2.5 * cos(time/2.),time * 2.);
    return c;
}
vec3 ray(vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    //r.yz *= genRot(PI / 4.);
    //r.xy *= genRot(PI/4.-time / 2.);
    return r;
}

void main(void) {

    vec2 uv = ( gl_FragCoord.xy * 2. - resolution.xy) / resolution.y ;
    vec3 c = cam();
    vec3 r = ray(uv,1.5);
    vec3 color = trace(c,r);

    glFragColor = vec4( color, 1.0 );

}
