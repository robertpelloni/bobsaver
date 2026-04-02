#version 420

// original https://www.shadertoy.com/view/stjXzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: paperu
// Title: ancient horology

#define P 6.283185307

float t;
mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float c(vec2 p, float s) { return length(p) - s; }
const int NS = 7;
float S[NS];

float mask(vec2 p) { p = abs(p) - .5; return max(p.x,p.y); }

float a0(vec2 p) { p = abs(p) - 0.320; return max(c(p, 0.300),-c(p + -0.296, 0.658)); }
float a1(vec2 p) { return max(c(p, .35),-c(p + -0.104, 0.250)); }
float a2(vec2 p) { p = -p; return max(c(p, .35),-min(c(p + -0.104, 0.250),c(p + 0.120, 0.114)));}
float a3(vec2 p) { p = p.yx; float px = p.x;p.x = abs(p.x);p.y -= sign(px)*-.1; return max(c(p, 0.230),-c(p +vec2(1,0)*0.096, .25)); }
float a4(vec2 p) { vec2 pp = p; float px = p.x;p.x = abs(p.x);p.y -= sign(px)*-0.1; return min(c(pp,0.068), max(c(p, 0.230),-c(p +vec2(1,0)*0.096, .25))); }
float a5(vec2 p) { vec2 pp = -p*1.624 + 0.172; pp *=rot(step(.24,length(pp))*5.504 + t*P/5.);return min(max(c(pp, .35),-c(vec2(abs(pp))-0.200, 0.210))/1.624, max(c(p, .35),-c(p + -0.104, 0.250))); }
float a6(vec2 p) {
    vec2 pp = p.yx*rot(-0.096)*2. + vec2(-0.250,0.010);
    return min(
        max(abs(c(p -  vec2(0.,.045),0.285)) - 0.042, abs(c(p + vec2(0.,.045),0.285)) - 0.042),
        max(abs(c(pp - vec2(0.,.045),0.285)) - 0.042, abs(c(pp + vec2(0.5,0.),0.277)) - 0.042)
    );
}

float shapesGen(vec2 p) {
    const vec2 s = vec2(0.,1.);
    S[0] = a0(p);
    S[1] = a1(p+s*1.);
    S[2] = a2(p+s*2.);
    S[3] = a3(p+s*3.);
    S[4] = a4(p+s*4.);
    S[5] = a5(p+s*5.);
    S[6] = a6(p+s*6.);
    
    float d = S[0];
    for(int i = 1; i < NS; i++)
        d = min(d, S[i]);
    
    return d;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    float aa = 1./resolution.x;
    
    t = P*.515 + time;
    
    float scale1 = 20.;
    vec2 p1 = st*scale1;
    p1 += t*.5;
    p1 = vec2(mod(p1.x, 1.) - .5, mod(floor(p1.x)*2.5 + p1.y, float(NS)) - float(NS) + .5);
    float d_bg = shapesGen(p1);
    d_bg = abs(d_bg) - .005;
    d_bg /= scale1;
    
    float scale2 = 5.;
    float nb = 7.;
    vec2 ptemp = st;
    float rot_s = -P/20.;
    ptemp *= rot(t*rot_s);
    float a = floor((atan(ptemp.x,ptemp.y)/P + .5)*nb);
    float a_2 = (a/nb)*P + (P/nb)/2.;
    float kk = (cos(-t*rot_s + a*3.5)*.5+.5)*1.;
    ptemp *= scale2;
    vec2 p2 = ptemp + vec2(sin(a_2),cos(a_2)) *(1.785 - kk*kk*kk*kk*kk*kk*kk*5.);
    p2 *= rot(-t*rot_s);
    
    float d_ft = shapesGen(p2 + vec2(0.,-a));
    d_ft = max(d_ft,mask(p2));
    d_ft = max(d_ft, -c(ptemp, 1.436));
    
    p2 *= rot(t*rot_s - a_2);
    float lines = max(abs(p2.x) - .01, -p2.y);
    lines = max(-lines, (abs(c(ptemp, 1.300)) - 0.044));
    d_ft = min(d_ft, lines);
    
    float d_ft2 = (abs(d_ft + .02)) - 0.01;
    d_ft = max(d_ft, -d_ft2);
    d_ft /= scale2;
    
    vec2 p = st;
    
    float S = 1.5;
    p *= S;
    float s = 0.408;
    float d_set = a1(p);
    s = 1.6;
    float pdlm = cos(P*t*.25)*.5;
    p = (p - .1)*s*rot(pdlm);
    d_set = min(d_set, a2(p)/s);
    float t_s = 1.72;
    d_set = min(d_set, a5((p + .1)*t_s*rot(-pdlm))/s/t_s);
    t_s = 4.;
    d_set = min(d_set, a6((p - .12)*t_s*rot(-pdlm))/s/t_s);
    d_set /= S;
    d_set = max(d_set, -(abs(d_set + .005) - 0.002));
    
    float d = -min(d_bg, (d_ft));
    d = max(d, -d_set);
    
    vec3 c = d == -d_set ? vec3(1.)
        : d == -d_ft ? mix(vec3(0.880,0.584,0.077),vec3(1.000,0.994,0.000),st.y+.5)
        : vec3(0.208,0.171,0.335);
    vec3 color = smoothstep(-aa,aa, d)*c;
    
    float l = length(st);
    glFragColor = vec4(color - l*l*l*.3,1.0);
}
