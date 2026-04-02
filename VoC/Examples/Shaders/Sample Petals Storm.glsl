#version 420

// original https://www.shadertoy.com/view/ttVBWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: paperu
// Title: petals storm

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define P 6.28318530717
float t;

vec3 SpectrumPoly(float x) {
    // https://www.shadertoy.com/view/wlSBzD
    return (vec3( 1.220023e0,-1.933277e0, 1.623776e0)
          +(vec3(-2.965000e1, 6.806567e1,-3.606269e1)
          +(vec3( 5.451365e2,-7.921759e2, 6.966892e2)
          +(vec3(-4.121053e3, 4.432167e3,-4.463157e3)
          +(vec3( 1.501655e4,-1.264621e4, 10.375260e4)
          +(vec3(-2.904744e4, 1.969591e4,-2.330431e4)
          +(vec3( 3.068214e4,-1.698411e4, 2.229810e4)
          +(vec3(-1.675434e4, 7.594470e3,-1.131826e4)
          + vec3( 3.707437e3,-1.366175e3, 2.372779e3)
            *x)*x)*x)*x)*x)*x)*x)*x)*x;
}

mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float sph(in vec3 p, in float r) { return length(p) - r; }
float box(in vec3 p, in vec3 s, in float r) { return length(max(abs(p) - s,0.)) - r; }

float df(in vec3 p) {
    p.xz *= rot(P*.125);
    p.yz *= rot(P*.125 - t*4.);
    float d = 10e9, v = 1.;
    mat2 rotV1 = rot(P*.125 + t), rotV2 = rot(P*.125 + t*2.), rotV3 = rot(P*.125 + t*4.);
    for(int i = 0; i < 5; i++) {
        d = min(d,max(-box(p, vec3(.5)*v, .015),sph(p, .55*v)));
        p.xz *= rotV1;
        p.xy *= rotV2;
        p.yz *= rotV3;
        p.z = abs(p.z) - 0.378;
        v *= .75;
    }
    return d;
}

vec3 normal(in vec3 p) { float d = df(p); vec2 u = vec2(0.,.00001); return normalize(vec3(df(p + u.yxx),df(p + u.xyx),df(p + u.xxy)) - d); }

vec3 rm(in vec3 c, in vec3 r) {
    const float MAX_D = 5., LIM = .0001;
    const int MAX_IT = 150;
    vec3 color = vec3(-1.);
    vec3 p = c;
    bool h = false;
    for(int i = 0; i < MAX_IT; i++) {
        float d = df(p);
        if(d < LIM) { h = true; break; }
        if(distance(c,p) > MAX_D) { break; }
        p += d*r;
    }
    if(h) {
        vec3 n = normal(p);
        color = SpectrumPoly(clamp(dot(n,-r),0.,1.));
    }     
    
    return color;
}

vec3 rgb2hsv(in vec3 c) {
    vec4 K = vec4(0., -1./3., 2./3., -1.);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1e-10;
    return vec3(abs(q.z + (q.w - q.y)/(6.0*d + e)), d/(q.x + e), q.x);
}

vec3 hsv2rgb(in vec3 c) {
    vec4 K = vec4(1., 2./3., 1./3., 3.);
    return c.z * mix(K.xxx, clamp(abs(fract(c.xxx + K.xyz)*6. - K.www) - K.xxx, 0., 1.), c.y);
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy - .5;
    float g = -4.312 - m.x*.1;
    t = g*.25 + cos(g*.5)*8.2 + pow(length(st)*0.7,2.) + time*.1;
    
    vec3 c = vec3(st*1.75,-2.);
    vec3 r = normalize(vec3(0.,0.,1.));

    vec3 color = rm(c,r);
    st += g;
    color += vec3(fract(st*5. + cos(st.x*10.)*cos(st.y*10.)),1.);
    st *= rot(P*.125);
    color = mix(color,color.bgr,step(0.,fract(st.x*8.) - .5));
    color *= .5;
    color = clamp(color,0.03,1.);
    vec3 colHSV = rgb2hsv(color);
    color = hsv2rgb(vec3(colHSV.x,colHSV.y*.985,colHSV.z));
    
    glFragColor = vec4(color,1.);
}
