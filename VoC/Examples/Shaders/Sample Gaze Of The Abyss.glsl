#version 420

// original https://www.shadertoy.com/view/Xt3yRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define thick   0.04
#define smooth  (0.000015 * resolution.x)
#define PI      3.14159265359
#define grid    10.0
#define SM(x, offset) smoothstep(smooth, -smooth, x - offset)
#define SMX(x, offset) smoothstep(1.0, -1.0, x - offset)
#define scale vec2(4.0, 6.0) 
#define rots 360.0

float rand(vec3 v){
    return fract(cos(dot(v,vec3(13.46543,67.1132,123.546123)))*43758.5453);
}

float rand(vec2 v){
    return fract(sin(dot(v,vec2(5.11543,71.3177)))*43758.5453);
}

float rand2(vec2 v){
    return fract(sin(dot(v,vec2(330.2322,91.1132)))*63232.2312);
}

float rand(float v){
    return fract(sin(v * 71.3132)*43758.5453);
}

vec2 rotate(vec2 st, float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * st;
}
float smrand(float v){
    float vv = floor(v);
    return mix(rand(vv),rand(vv+1.0),fract(v));
}

vec3 eye(vec2 st, float rt, vec2 mouse, float open, float siz, float lrt){
    vec2 str = st * scale;
        
    float cs = cos(str.x);
    float eyelidx = 1.0 -  max(SMX(cs * 2.0 - str.y + 0.5, 0.51), 1.0 - SMX(-cs * 2.0 - str.y + 0.5, 0.51));
    cs *= min(open,rt + 0.5);
    float top = cs - str.y + 0.5;
    float bot = -cs - str.y + 0.5;
    float eyelid = 1.0 -  max(SM(top, 0.51), 1.0 - SM(bot, 0.51));
    float eyelid2 = 1.0 - max(SM(top, 0.44), 1.0 - SM(bot,0.44));
    
    
    vec2 sti = (st + mouse * vec2(1.5,0.6)) * scale.x;
    float a = (atan(sti.x,sti.y) + PI) /PI /2.;
    float l = length(sti);
    float irf = SM(l,0.5 * siz);
    float irl = SM(l,0.45 * siz);
    float irm = SM(l,0.15 * siz * (rt + 0.5));
    float irn = smrand(a * 200.0);
    float irnn = abs(fract(l * (irn + 1.0) - 0.35 * siz * (rt + 0.5) -0.7) - 0.5)* 3. *(1.0 -l);
    vec2 stir = (st + mouse * vec2(2.0,1.0)) * scale.x;
    float irr = SM(length(stir),0.1 + 0.05 * lrt);
    vec2 stis = (st + mouse * vec2(3.0,2.0)) * scale.x;
    float irs = SMX(length(stis),1.0) * eyelidx;
    
    
    vec3 col = vec3(1.0 - (irf));
    col = mix(col, irnn * vec3(2.0,(1.0 - fract(l)) * 0.75,0.0),irl -irm);
    col = mix(col,(1.0 -fract(l /scale.x)) * vec3(2.0,1.0,1.0), 1.0 - irf) + irr;
    col = min(vec3(eyelid2), col);
    col = mix(col,irs * vec3(0.15) * (open * 0.65 + 0.25 + 0.05 *lrt), 1.0 - eyelid2);
    col = mix(col,vec3(0.5,0.0,0.0),max(eyelid - eyelid2, eyelid2 - eyelid));
    return col;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - 0.5 * resolution.xy)/ resolution.x;
    vec2 mouse = (mouse*resolution.xy.xy - 0.5 * resolution.xy) / resolution.x;
    vec2 toMouse = -mouse + st;
    float r = rand(floor(st*grid));
    float r2 = rand2(floor(st*grid));
    float rt = (sin(time * 2.0 + r * 100.0)+ 1.0)/2.0;
    vec2 cor = (fract(st * grid) - 0.5) * (1.0 + r2 * 0.5) + 0.25 * (vec2(r, r2) - 0.5);
    cor = rotate(cor, rots * r);
    float tm = 1.0 - length(toMouse);
    float lrt = smrand(time* 15.0);
    float open = length(mouse - floor(st * grid)/grid);
    open = clamp(pow(1.1 - open, 25.0),0.0, 1.);
    vec3 col = eye(cor,rt, rotate(toMouse, rots * r), open, r2 + 1.0, lrt);
    col = col * tm * tm + pow(tm,75.0 + 15.0 * lrt) * vec3(1.5,1.4,1.2);
        
    col = max(col, vec3(0.05,0.05,0.025)*rand(gl_FragCoord.xy/2.0 + time));
        
    //float line = min(SM(st.y - 0.0001, 0.0),SM(-st.y - 0.0001, 0.0));
    glFragColor = vec4(col, 1.0);
}
