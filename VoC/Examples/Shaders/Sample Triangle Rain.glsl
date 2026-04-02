#version 420

// original https://neort.io/art/bm8pgn43p9fd22fs7jcg

uniform vec2  resolution;     
uniform vec2  mouse;          
uniform float time;           
uniform sampler2D backbuffer; 

out vec4 glFragColor;

const float PI = 3.1415926;

mat2 rot(float a){
    float c= cos(a),s = sin(a);
    return mat2(c,s,-s,c);
}

vec2 pmod(vec2 p, float n){
    float a = atan(p.x,p.y) + PI / n;
    float r = PI * 2.0 / n;
    a = floor(a/r) * r;
    return rot(a) * p;
}

float hash(vec2 uv){
    return fract(44531.521*sin(dot(uv,vec2(12.6121,17.531))));
}

float triangle(vec2 p, float s){
    p = pmod(p,3.);
    p.xy -= s;
    float a = p.y;
    return a;
}

float draw(vec2 p,vec2 index){
    float rnd = hash(index);
    p = rot(time * (rnd + 0.1)  * 5.0+ rnd * PI) * p;
    float a = triangle(p,.01);
    if(rnd < 0.02){
        a = step(a,0.25);
    } else {
        a = 0.;
    }
    return a;
}

float draw2(vec2 p,vec2 index){
    p /= 0.3;
    float rnd = hash(index);
    p *= rot(time * (rnd + 0.1) * 0.5);
    float a = step(triangle(p,0.1),0.2);
    float b = step(triangle(p,0.5),0.2) - step(triangle(p,0.5),0.175);
    float c = step(triangle(p,0.5),0.05) - step(triangle(p,0.5),0.0175);
    return rnd < 0.25 ? a + b + c : 0.0;
}

float draw3(vec2 p,vec2 index){
        p /= 0.3;
    float rnd = hash(index);
    p *= rot(time * (rnd + 0.1) * 0.5);
    float b = step(triangle(p,0.5),0.2) - step(triangle(p,0.5),0.175);
    float c = step(triangle(p,0.5),0.05) - step(triangle(p,0.5),0.0175);
    return rnd < 0.25 ? b + c : 0.0;
}

void main(){
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / resolution.y;
    vec2 uv = p;
    vec2 q = p;
    vec2 q1 = p;
    
    p *= 4.0;
    vec2 iuv = floor(p);
    float rnd = hash(vec2(iuv.x));
    p.y += time * (rnd + 0.5) * 0.5;
    iuv = floor(p);
    vec2 fuv = fract(p);
    vec3 c = vec3(0.0);
    c = vec3(draw(fuv-0.5,iuv));
    
    p += 12.0;
    vec2 iuv3 = floor(p);
    float rnd3 = hash(vec2(iuv3.x));
    p.y += time * (rnd3 + 0.5) * 0.5;
    iuv3 = floor(p);
    vec2 fuv3 = fract(p);
    c += vec3(draw(fuv3-0.5,iuv3));
    
    q *= .75;
    vec2 iuv2 = floor(q);
    float rnd2 = hash(vec2(iuv2.x));
    q.y += time * (rnd2 + 0.5) * 0.4;
    iuv2 = floor(q);
    vec2 fuv2 = fract(q);
    c += vec3(draw2(fuv2 - 0.5,iuv2));
    
    q1 += vec2(9.1,12.61);
    q1 *= 0.9;
    vec2 iuv4 = floor(q1);
    float rnd4 = hash(vec2(iuv4.x));
    q1.y += time * (rnd4 + 0.5) * 0.1;
    iuv4 = floor(q1);
    vec2 fuv4 = fract(q1);
    c += vec3(draw3(fuv4 - 0.5,iuv4));
    
    c = clamp(c,0.,1.0);
    c *= smoothstep(-1.0,0.0,uv.y);
    c = uv.x < 0. ? c : 1. - c;
    
    glFragColor = vec4(c, 1.0);
}
