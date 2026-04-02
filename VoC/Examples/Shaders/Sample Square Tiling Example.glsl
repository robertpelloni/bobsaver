#version 420

// original https://www.shadertoy.com/view/NdfBzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a+b*cos(2.*pi*(c*t+d));
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float sdBox( in vec2 p, in vec2 b ) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    uv.x -= 1. + 0.25 * pi * 0.2 * time; 
    uv.y += 0.06 * cos(4. * uv.x + pi* 0.2 * time);
    
    float sc = 42. + .025 * (1. + thc(1., 4. * uv.x + uv.y + time));
    vec2 ipos = floor(sc * uv);
    vec2 fpos = fract(sc * uv);
       
    // m determines what new cell the old cell lies in
    // 3 -> small
    // 0 -> tl big, 2 -> tr big, 4 -> bl big, 1 -> br big
    float m = mod(2. * ipos.x - ipos.y, 5.);
    
    // id = 2 if small cell, id = 1 if big cell (used to make outlines same size)
    float id = 2.;
    vec2 o = vec2(0);
    
    if (m != 3.) { fpos *= 0.5;  id = 1.; }    
    if (m == 2.)      o = vec2(1,0); // top right
    else if (m == 4.) o = vec2(0,1); // bottom left
    else if (m == 1.) o = vec2(1);   // bottom right
    
    // if in big cell, halve fpos + translate
    fpos += 0.5 * o - 0.5;
    ipos -= o;
    
    float h = h21(ipos);    
    float v = 0.3 * ipos.x/sc + 0.25 * h + 0.2 * time;
    
    float d = sdBox(fpos, vec2(0.1)) - 0.28 - 0.1 * thc(20., 2. * pi * v);
    float k = 10. / resolution.y;
    float s = smoothstep(-k, k, -d);
        
    float c = (0.75/sc) * ipos.y + 0.5 + 0.5 * h;
    c *= s;
    
    vec3 e = vec3(1.);
    float f = smoothstep(-0.5, 0.5, fpos.x);
    vec3 col = c * pal(v, 0.6 * f * e, e, 0.8 * e, (0.75/sc) * ipos.y * vec3(0., 0.33, 0.66)); 
    //col -= step(sdBox(fpos, vec2(0.1)), 0.28 * id);
    col = clamp(col, 0., 1.);
    col += 0.1;
    glFragColor = vec4(col,1.0);
}
