#version 420

// original https://www.shadertoy.com/view/3dcXWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "[phreax] cube waves" by phreax. https://shadertoy.com/view/Wd3SWl
// 2019-11-06 22:43:34

float tt, mat = 0., cy;
vec2 id;
mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

float box(vec3 p, vec3 r) {
    p = abs(p) - r;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

vec2 repeat(inout vec2 p, vec2 s) {
    vec2 id = floor(p/s-.5);
   // p = (fract(p/s-.5)-.5)*s;
    p = mod(p+.5*s, s)-.5*s;
    return id;
}

float N(float x) {
    return fract(sin(x*92856.957)*64556.549);
}

float N21(vec2 p) {
    return fract(dot(p, vec2(N(p.x), N(p.y)))*8847.523);
}

vec3 kifs(vec3 p, float a) {
    for(int i=0; i<3; i++) {
        p.xz *= rot(sin(float(i)*.4+tt*a+a));
        p.xz -= vec2(0.2, 0.4);
        p.xz = abs(p.xz);
    }
    return p;
}

float map(vec3 p) {
    id = repeat(p.xz, vec2(5.2));
    float h = N21(id);
    p.xz *= rot(tt*h);
   
    p = kifs(p, h);
    //mat = id.x;
    vec3 s = vec3(.6);

    p.y += sin(length(id+vec2(1, -5.))*0.7+tt*2.)*1.5;
    cy = p.y;
    p.xy *= rot(h);
  
    return (box(p, s)-.1);
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    tt = time;
    vec3 ro = vec3(0, -10., -20),
         rd = normalize(vec3(-uv, .7)),
         l = normalize(vec3(0, -1, -4.));
    rd.yz *=rot(.6);
    
    vec3 col,
         bg = mix(vec3(.74, .91, .99), vec3(.1), -(uv.y-0.4));
    
    
    
    float i, t = 0.1, d=.01;
    
    vec3 p;
    for(i=0.; i<100.; i++) {
         p = ro + t*rd;
        d = map(p);
        if(t < 0.001 || t > 90.) break;       
        t += d;
    }
    
    vec2 e = vec2(.0005, -.0005);
    if(d < 0.0001) {
        
        vec3 n = normalize(e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) +
                           e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx));
        float dif= max(dot(n, l), .0);
        
        
        float sss = smoothstep(0., 1., map(p+l*.4));
        vec3 al = mix(vec3(0.1, 0.6, 0.8)*.9, vec3(.1, 0, 1), p.y-cy);
        col += al*.4 + 0.8*al*(dif+sss);
        col = mix(col, bg, 0.5*(1.-exp(-.00002*t*t*t)));
     
    } else {
         col = bg;
    }
   
    
    glFragColor = vec4(col,1.0);
}
