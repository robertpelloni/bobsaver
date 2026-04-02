#version 420

// original https://www.shadertoy.com/view/fdK3RD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_SEGMENTS  150
#define PI            3.141592653
#define ss(a, b)      (1. - smoothstep(0., a, b))
#define colorA   vec3(1, 0.2, 0.2)
#define colorB   vec3(0.3, 1., 0.5)

mat2 rot2(in float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// complex multiplication
vec2 cmul(vec2 p, vec2 q) {
    return vec2(p.x*q.x-p.y*q.y, p.x*q.y+p.y*q.x);
}

// complex division
vec2 cdiv(vec2 z, vec2 w) {
    return vec2(z.x * w.x + z.y * w.y, -z.x * w.y + z.y * w.x) / dot(w, w);
}

vec2 transform(vec2 z, vec2 a) {
    return cdiv(z - a, vec2(1, 0) - cmul(vec2(a.x, -a.y), z));
}

float n2D(vec2 p) {
    const vec2 s = vec2(1, 113);
    vec2 ip = floor(p); p -= ip;
    vec4 h = vec4(0., s.x, s.y, s.x + s.y) + dot(ip, s);
    p = p*p*(3. - 2.*p);
    h = fract(sin(h)*43758.5453);
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x);
}

float fbm(vec2 p) {
    return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }

float distLine(vec2 a, vec2 b) {
    b = a - b;
    float h = clamp(dot(a, b)/dot(b, b), 0., 1.);
    return length(a - b*h);
}

float sBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - r;
}

float dot2(in vec2 v) {
    return dot(v, v);
}

float dSegment(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return dot2(pa - ba*clamp(dot(pa,ba) / dot(ba,ba), 0.0, 1.0));
}

vec2 map1(float t) {
    const float s = 2.;
    vec2 p = vec2(cos(t), sin(t));
    vec2 z = transform(p, vec2(.5, .7));
    z = cmul(z, transform(p, vec2(-.6, 0.5)));
    z = cmul(z, transform(p, vec2(-0.4)));
    z = cmul(z, p - vec2(s, s));
    return z;
}

vec2 map2(float t) {
    return map1(t) + vec2(cos(t) * 1.6, sin(t) * 1.2);
}

float dcurve(vec2 p, int index) {
    float h = 0.05;
    float t = 0.0;

    vec2  a = index == 0 ? map1(t) : map2(t);
    float d = dot2(p - a);

    for(int i = 0; i < NUM_SEGMENTS; i++) {
        vec2  b = index == 0 ? map1(t) : map2(t);
        d = min(d, dSegment(p, a, b));
        t += clamp(0.01*length(a-p)/length(a-b), 0.01, 0.05);
        a = b;
    }
    return sqrt(d);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453);
}

float doHatch(vec2 p, float res) {
    p *= res/16.;
    float hatch;
    float hRnd = hash21(floor(p*6.) + .73);
    if(hRnd>.66) hatch = hRnd;
    else if (hRnd > 0.33) hatch = clamp(sin((p.x - p.y)*3.14159*200.)*2. + .5, 0., 1.);
    else hatch = clamp(sin((p.x + p.y)*3.14159*200.)*2. + .5, 0., 1.);
    return hatch;
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    vec2 p = uv * 9.;
    p -= vec2(.5, .5); // adjust the postion of the curves
    vec2 O = vec2(0.5);

    // Smoothing factor.
    float sf = 8./resolution.y;

    // background color
    vec3 col = vec3(1);
    float hatch = doHatch(uv, resolution.y);
    col *= hatch*.2 + .8;
    
    vec2 e = vec2(.015, .03);
    float le = length(e);

    // curve width
    float lw = .02;

    float dc1 = dcurve(p, 0);
    float dc2 = dcurve(p, 1);

    float tA = mod(time*.2, 2.*PI);
    float tB = max(0., tA + sin(time) * .1 - .1);
    vec2 A0 = map1(0.), B0 = map2(0.);
   
    vec2 A = map1(tA);
    vec2 B = map2(tB);
    float dA = length(p - A) ;
    float dB = length(p - B) ;

    // dash grid lines
    vec2 p1 = uv * 6.;
    p1 -= floor(p1) + 0.5;
    float bord = max(abs(p1.x), abs(p1.y))-0.49;
    vec2 q1 = abs(mod(p1, 1./8.) - .5/8.);
    float lines = (min(q1.x, q1.y) - .5/8./3.);
    bord = min(bord, lines);
    bord = step(0., bord);
    
    float dlink = dSegment(p, A, B);
    // noisy background pattern
    col *= fbm(p*48.)*.4 + .6;
    // draw the grid lines
    col = mix(col, vec3(0), bord*.8);

    col = mix(col, vec3(0), (1. - smoothstep(0., sf*16., dc2))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*8., dc2 - lw*2.4));
    col = mix(col, colorB, (1. - smoothstep(0., sf*4., dc2 - lw*1.6))*.8);

    col = mix(col, vec3(0), (1. - smoothstep(0., sf*16., dc1))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*8., dc1 - lw*2.4));
    col = mix(col, colorA, 1. - smoothstep(0., sf*4., dc1 - lw*1.6));

    col = mix(col, vec3(0), (1. - smoothstep(0., sf*.7, dlink - 0.005))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf*.7, dlink - .008));
    col = mix(col, vec3(1, 1, .3), 1. - smoothstep(0., sf*.7, dlink));

    lw *= 12.;

    dA -= lw;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., dA - 0.02))*.75);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, dA - 0.04));
    col = mix(col, colorA, 1. - smoothstep(0., sf, dA));
    dA += .12;
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, dA - .03));
    col = mix(col, vec3(1, .8, .6), 1. - smoothstep(0., sf, dA)); 
    dA += .08;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, dA))); 

    dB -= lw;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8., dB - 0.02))*.75);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, dB - 0.04));
    col = mix(col, colorB, 1. - smoothstep(0., sf, dB));
    dB += .12;
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, dB - .03));
    col = mix(col, vec3(1, .8, .6), 1. - smoothstep(0., sf, dB)); 
    dB += .08;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, dB)));

 
    vec2 q = p - O;
    float ci = length(q) - .7;
    float sh = max(.75 - ci*4., 0.);
    col = mix(col, vec3(0), (ss(sf*6., ci - .04))*.5);
    col = mix(col, vec3(0), ss(sf, ci));
    col = mix(col, vec3(1, .7, .4)*(ci + sh*sh*.1 + .5), ss(sf, ci + .03));
    col = mix(col, col*1.6, ss(sf*4., ci + .15));
       col = mix(col, vec3(0), ss(sf, abs(ci + .1) - .01));   
    col = mix(col, vec3(0), (ss(sf, length(q) - .18))*.5);
    col = mix(col, vec3(0), ss(sf, abs(length(q) - .12) - .01));
    col = mix(col, vec3(0), ss(sf, length(q) - .05));
        
    A -= O;
    B -= O;
    vec2 qA = rot2(atan(A.y, A.x-.5) -PI/2.) * q;
    vec2 qB = rot2(atan(B.y, B.x)-PI/2.) * q;
    float indA = distLine(qA - vec2(0, -.005), qA - vec2(0, .46)) - .01;
    float indB = distLine(qB - vec2(0, -.005), qB - vec2(0, .3)) - .01;
    
    const float rad = .45;
    const float aNum = 12.;
    q = rot2(3.14159/aNum)*q;
    float a = atan(q.y, q.x);
    float ia = floor(a/6.283*aNum) + .5; // .5 to center cell.
    ia = ia*6.283/aNum;
    q = rot2(ia)*q;
    q.x -= rad;
        
    // Markings.
    float mark = sBox(q, vec2(.04, .022), 0.);
    col = mix(col, vec3(.5), ss(sf, mark - .015));
    col = mix(col, vec3(0), ss(sf, mark));
        
    // Indicator.        
    col = mix(col, vec3(0), ss(sf, indA - .025));
    col = mix(col, colorA, ss(sf, indA));
    col = mix(col, vec3(0), ss(sf, indB - .025));
    col = mix(col, colorB, ss(sf, indB));
    
    // Subtle vignette.
    uv = gl_FragCoord.xy/resolution.xy;
    col *= pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./16.)*1.05;

    // Output to screen
    glFragColor = vec4(sqrt(max(col, 0.)), 1);
}
