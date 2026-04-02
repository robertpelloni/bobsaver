#version 420

// original https://www.shadertoy.com/view/wtBXRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;

float genTerra(vec2 uv){
    return sin(uv.x  /2. + time / 2.) * sin(uv.y / 2. + time / 2.) * 0.5;
}

mat2 genRot(float v){
    return mat2(cos(v),-sin(v),sin(v),cos(v));
}

float map(vec3 p){
    float terrain = -abs(-p.y)-(-2. + genTerra(p.xz));
    
    vec3 q = p;
    vec3 r = p;
    vec3 s = p;
    q.y += mod(time * sign(p.x -1.0) + q.z / 5.,2.);
    q.xz = (fract(q.xz / 3. + 0.5) - 0.5) * 3.; 
    q.y *= sign(p.x - 1.0);
    r.xz = (fract(r.xz / 3. + 0.5) - 0.5) * 3.; 
    s.x += mod(time * sign(p.y),2.);
    s.x *= sign(p.y);
    s.y = abs(s.y);
    s.y += 2.;
    s.z += 1.5;
    s.yz = (fract(s.yz / 3. + 0.5) - 0.5) * 3.; 
    q.y = (fract(q.y / 2. + 0.5) - 0.5) * 2.; 
    s.x = (fract(s.x / 2. + 0.5) - 0.5) * 2.;
    float sp = min(length(q) - 0.35,length(q - vec3(0.,0.8,0.)) - 0.15);
    sp = min(sp, max(length(q.xz) - 0.05,abs(q.y - 0.4) - 0.5));
    float sp2 = min(length(s) - 0.35,length(s - vec3(0.8,0.,0.)) - 0.15);
    sp2 = min(sp2, max(length(s.yz) - 0.05,abs(s.x - 0.4) - 0.5));
    sp = min(sp,sp2);
    float hole = length(r.xz) - 3. * (1. / (1. +  abs(r.y) * abs(r.y)));
    float cliff = min(abs(r.x) - 0.25,abs(r.z) - 0.25);
    terrain = max(terrain,-hole);
    terrain = max(terrain,-cliff);
    return min(terrain,sp);
}

vec3 getNormal(vec3 p){
    vec3 x = dFdx(p);
    vec3 y = dFdy(p);
    return normalize(cross(x,y));
}

vec4 trace(vec3 o,vec3 r){
    vec4 data;
    float t = 0.;
    for(int i = 0; i < 128; i++){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    vec3 p = o + r * t;
    vec3 n = getNormal(p);
    return vec4(n,t);
}

vec3 cam(){
    vec3 c = vec3(1.,0.,-2.5 + time * 3.);
    //c.xy += vec2(cos(time/4.),sin(time/4.)) * 0.5;
    return c;
}

vec3 ray(vec2 uv,float z){
    vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(PI / 8.);
    r.yz *= genRot(time / 8.);
    r.xy *= genRot(time / 4.);
    return r;
}

vec3 getColor(vec3 o,vec3 r,vec4 d){
    float t = d.w;
    vec3 n = d.xyz;
    float tmp1 = dot(r,n);
    vec3 bc = vec3(1. - tmp1 * 0.85);
    vec3 p = o + r * t;
    //bc = min(fract(p.x),fract(p.z+time)) < 0.05 ? vec3(1.0) : bc;
    vec3 cc;
    float at = atan(r.y/r.x) * 2.;
    float tmp2 = at + time;
    cc.x = sin(tmp2);
    cc.y = sin(tmp2 + PI * 2. / 3.);
    cc.z = sin(tmp2 - PI * 2. / 3.);
    cc = cc / 2. + 0.5;
    cc = fract(p.z - time) < 0.25 ? vec3(1.) : cc;
    bc *= cc;
    
    float fog = 1. / (1. + t * t * 0.015);
    return mix(bc,vec3(0.),1. - fog);
}

void main(void) {

    vec2 uv = ( (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y );
    vec3 c = cam();
    vec3 r = ray(uv,1.5 + 0.5 * sin(time/2.) );
    vec4 d = trace(c,r);
    vec3 color = getColor(c,r,d);

    glFragColor = vec4( color, 1.0 );

}
