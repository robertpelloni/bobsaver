#version 420

// original https://www.shadertoy.com/view/MsyyzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// @lsdlive

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

void amod(inout vec2 p, float m) {
    float a = mod(atan(p.x, p.y) - m*.5, m) - m*.5;
    p = vec2(cos(a), sin(a)) * length(p);
}

void mo(inout vec2 p, vec2 d) {
    p.y = abs(p.y) - d.x;
    p.x = abs(p.x) - d.y;
    if (p.y > p.x) p.xy = p.yx;
}

float rep(float p, float m) {
    return mod(p - m*.5, m) - m*.5;
}

vec2 rep(vec2 p, float m) {
    return mod(p - m*.5, m) - m*.5;
}

vec3 rep(vec3 p, float m) {
    return mod(p - m*.5, m) - m*.5;
}

float smin(float a, float b, float k) {
    float h = clamp(.5 + .5*(b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

float cmin(float a, float b, float k) {
    return min(min(a, b), (a - k + b) * sqrt(.5));
}

float stmin(float a, float b, float k, float n) {
    float s = k / n;
    float u = b - k;
    return min(min(a, b), .5 * (u + a + abs((mod(u - a + s, 2. * s)) - s)));
}

float length8(vec2 p) {
    vec2 q = p*p*p*p*p*p*p*p;
    return pow(q.x + q.y, 1. / 8.);
}

float torus88(vec3 p, vec2 d) {
    vec2 q = vec2(length8(p.xz) - d.x, p.y);
    return length8(q) - d.y;
}

float box(vec3 p, vec3 d) {
    return length(max(abs(p) - d, 0.));
}

float g = 0.;
float id = 0.;
float de(vec3 p) {
    
    float wl = p.x + 1.25;
    float wr = -p.x + 1.25;
    float fl = p.y + 1.;
    float cl = -p.y + 1.;
    
    vec3 q = p;
    q.x += sin(q.z*.2)*4.;
    q += time;
    q.yz += sin(time*.2)*4.;
    q = rep(q, 2.);
    float s1 = length(q) - .01 + sin(time*30.)*.004;
    
    p.x += 1.;
    p = rep(p, 2.);
    
    float d = box(p, vec3(.2, 1., .2));
    d = smin(d, cl +d*.9, .2);
    d = stmin(d, fl, .2, 3.);
    
    //d = stmin(d, wl+d*.8, .4, 8.);
    //d = stmin(d, wr+d*.8, .4, 8.);
    d = cmin(d, wl+d*.2, .4);
    d = cmin(d, wr+d*.2, .4);
    
    d = min(s1, d);
    
    
    p.z += .4;
    p.y-=.6;
    q=p;
    q.xy*=r2d(3.14/4.);
    float symb = 1e6;
    symb = min(symb, torus88(q.xzy, vec2(.05, .01)));
    p.y+=.07;
    p.xy*=r2d(3.14/4.);
    symb = min(symb, box(p, vec3(.01, .07, .01)));
    p.xy*=r2d(-3.14/2.);
    symb = min(symb, box(p, vec3(.01, .07, .01)));
    
    d=min(d,symb);
    
    g += .01 / (.01 + d*d);
    return d;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    vec3 ro = vec3(0, 0, -3. + time);
    vec3 rd = normalize(vec3(uv, 1));

    vec3 p;
    float t = 0., ri;
    for (float i = 0.; i < 1.; i += .01) {
        ri = i;
        p = ro + rd*t;
        float d = de(p);
        if (t > 30.) break;
        d = max(abs(d), .001);
        t+=d*.2;
    }

     vec3 bg = vec3(.2, .1, .2);

    vec3 col = bg;
    if(t<=30.)
        col = mix(vec3(.2, .2, .4), bg, uv.y*2.+ri);
    
    //if(p.y < .13 && p.y > -.2) col = mix(vec3(1, 0,0), bg, uv.y+ri);
    
    //if (id == 1.)
      //  col = vec3(1., 0.,0.);;
    
    col+=g*.015;
    col = mix(col, bg, 1.-exp(-.09*t*t));

    glFragColor = vec4(col, 1.0);
}
