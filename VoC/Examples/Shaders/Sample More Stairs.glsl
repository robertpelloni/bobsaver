#version 420

// original https://www.shadertoy.com/view/wlc3Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 R;

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float map(vec3 rp){
    float d = 99.;
    
    d = min(rp.y - floor(rp.z), 1.- (rp.z - floor(rp.y)));
    d = min(min(10. - rp.x, 1. + rp.x), d);
    
    return d;
}
vec3 normal( in vec3 pos ){
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

float march(vec3 rd, vec3 ro){
     float t = 0., d = 0.;   
    
    for(int i = 0; i < 64; i++){
        d = map(ro + rd*t);        
        if(abs(d) < .002){
            break;
        }
        t += d * .75;
    }   
    return t;
}
vec3 color(vec3 ro, vec3 rd, vec3 n, float t){
    vec3 lp = ro + vec3(.1, .3, -.01)*2.;
    vec3 ld = lp-ro;
    float dif = max(dot(n, ld), .0);
    
    vec3 col = vec3(0);
    vec2 id = vec2(0);
    float chk = 0.;
    
    ro.x*=.5;
    if(abs(n.x)>.99){
        id = floor((ro.yz)*2.);
        chk = mod(id.x + id.y, 2.);
        col = mix(vec3(.5, .6, 0.), vec3(.5, 0., .6), chk)*.2;
    }
    else{
        id = floor((ro.xy+ro.xz)*2.);
        chk = mod(id.x + id.y, 2.);
        col = mix(vec3(.5, .6, 0.), vec3(.5, 0., .6), chk) *dif;  
    }
    return col;   
}

void main(void) {
    R = resolution.xy;
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    
    vec3 rd = normalize(vec3(uv, 1. - dot(uv, uv) * .35));
    vec3 ro = vec3(.0,time - 5., -12. + time);
    
    rd.yz*=rot(.2);
    rd.xz*=rot(-.5);
    
    float t = march(rd, ro);
    
    ro += rd*t;
    
    vec3 n = normal(ro);
    vec3 col = color(ro, rd, n, t);
    
    glFragColor = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
}

