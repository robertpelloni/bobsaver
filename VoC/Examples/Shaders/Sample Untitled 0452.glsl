#version 420

// original https://www.shadertoy.com/view/tljXWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}
vec2 pmod(vec2 p,float count){
    p *= genRot(PI/count);
    float at = atan(p.y/p.x);
    float r = length(p);
    at = mod(at,2. * PI / count);
    p = vec2(r * cos(at),r * sin(at));
    p *= genRot(-PI/count);
    return p;
}
float map(vec3 p){
    vec3 q = p;
    p.xy *= genRot(p.z/4.);
    p = (fract(p/1.5 + 0.5) - 0.5) * 1.5;
    p.xy = pmod(p.xy,8.);
    float string = length(p.xy - vec2(0.25 + 0.05 * sin(q.z + time * PI),0.)) - .01 + 0.005 * sin(q.z);
    float sphere = length(p - vec3(0.25 + 0.05 * sin(q.z + time * PI),0.,0.)) - .03;
    string = min(string,sphere);
    return string;
}
vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}
vec4 trace(vec3 o,vec3 r){
    float t = 0.;
    vec3 p;
    for(int i = 0; i < 128; i++){
        p = o + r * t;
        float d = map(p);
        t += d * 0.75;
    }
    vec3 n = getNormal(p);
    return vec4(n,t);
}

vec3 cam(){
    vec3 c = vec3(0.,0.,-1.5);
    c += vec3(.5 * sin(time/2.),.5 * cos(time/2.),time * 2.);
    return c;
}
vec3 ray(vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(PI / 8.);
    r.xy *= genRot(-time/4.);
    //r.xz *= genRot(time/8.);
    //r.yz *= genRot(time/8.);
    return r;
}

vec3 getColor(vec3 o, vec3 r, vec4 d){
    vec3 light = normalize(vec3(r.xy,0.));
    vec3 p = o + r * d.w;
    vec3 n = d.xyz;
    float a = dot(n,r);
    vec3 cc = (vec3(sin(p.x),sin(p.y),sin(p.z)) * 0.5 + 0.5);
    vec3 bc = vec3(1.-a);
    cc = fract(p.z / 1.5) < 0.9 && fract((p.z/2. - time * 4.) / 8.) < 0.95  ? vec3(0.) : cc;
    bc += cc * 2.;
    float t = d.w;
    float fog = 1./(1. + t * t * 0.05);
    return mix(bc,vec3(0.),1. - fog);
}

void main(void) {

    vec2 uv = ( gl_FragCoord.xy * 2. - resolution.xy) / resolution.y ;
    vec3 c = cam();
    vec3 r = ray(uv,1.5);
    vec4 d = trace(c,r);
    vec3 color = getColor(c,r,d);

    glFragColor = vec4( color, 1.0 );

}
