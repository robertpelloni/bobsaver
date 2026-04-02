#version 420

// original https://www.shadertoy.com/view/Wd3SWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tt, cy; 

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

float N21(vec2 p) {
    return fract(sin(dot(p, vec2(341.234, 934.838)))*34234.23);
}

float map(vec3 p) {
    vec2 id = repeat(p.xz, vec2(3.2));
    float h = N21(id);
    vec2 c = vec2(1, -5.);
    float s = cos(length(id+c)+tt*2.)*.3 +.6;
    p.y += sin(length(id+c)*0.7+tt*3.)*1.5;
    cy = p.y;
    p.xy *= rot(h+0.3*tt*h*sign(h-.5));
  
    return (box(p, vec3(s))-.1);
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    tt = time;
    
    vec3 ro = vec3(0, -10., -20),
         rd = normalize(vec3(-uv, .7)),
         l = normalize(vec3(0, -1, -4.));
    
    rd.yz *= rot(.6);
    
    vec3 col, bg;
    col = bg = mix(vec3(.78, .97, .99), vec3(.3), -(uv.y-0.3));  
    
    
    float i, d, t = 0.1;
    
    vec3 p;
    for(i=0.; i<100.; i++) {
         p = ro + t*rd;
        d = map(p);
        if(t < 0.0001 || t > 90.) break;       
        t += d;
    }
    
    vec2 e = vec2(.0005, -.0005);
    if(d < 0.001) {
        
        vec3 n = normalize(e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) +
                           e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx));
        
        float ch = p.y - cy; // cube height
        float dif = max(dot(n, l), .0);
        float fog = 1.-exp(-.00002*t*t*t);
        
        // subsurface scattering from evvvvil
        float sss = smoothstep(0., 1., map(p+l*.4));
        
        vec3 al = mix(vec3(0.1, 0.6, 0.8)*.9, vec3(.15, 0, 1), ch);
        col = al*.4 + 0.8*al*(dif+sss);
        col = mix(col, bg, 0.5*fog);
    }
    
    glFragColor = vec4(col,1.0);
}
