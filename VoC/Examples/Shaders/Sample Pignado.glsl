#version 420

// original https://www.shadertoy.com/view/Dl2SRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define black vec3(0.01)
#define pink vec3(1, 0.5, 0.5)
#define darkPink vec3(200, 100, 100) / 255.

#define pi 3.14159
#define t 0.25 * time
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

// 🐖 ty fabrice 🐖
float box(vec2 f, int x, int y, int w, int h) {
    vec2 p = vec2(x,y);
    f = step(p, f) * step(f, p + vec2(w,h) - 1.);
    return f.x*f.y;
}

float drawPink(vec2 p) {
    float s = box(p, 0, -8, 9, 17);
    s += box(p, 6, 9, 2, 2);
    s += box(p, 9, -5, 2, 3);
    s += box(p, 9, -2, 1, 1);
    return s;
}

float drawBlack(vec2 p) {
    // Snout
    float s = box(p, 0, 0, 2, 1);
    s += box(p, 2, 1, 1, 1);
    s += box(p, 3, 2, 1, 4);
    s += box(p, 0, 6, 3, 1);
    s += box(p, 1, 3, 1, 2);
    
    // Outline
    s += box(p, 0, 8, 5, 1);
    s += box(p, 5, 9, 1, 3);
    s += box(p, 6, 11, 2, 1);
    s += box(p, 8, 0, 1, 11);
    s += box(p, 8, -8, 1, 5);
    s += box(p, 9, -6, 2, 1);
    s += box(p, 11, -5, 1, 3);
    s += box(p, 10, -2, 1, 1);
    s += box(p, 9, -1, 1, 1);
    s += box(p, 0, -9, 8, 1);
    
    // Eyes
    s += box(p, 6, 6, 1, 1);
    return s;
}

float drawDarkPink(vec2 p) {
    // Snout
    float s = box(p, 0, -1, 2, 1);
    s += box(p, 2, 0, 1, 1);
    s += box(p, 3, 1, 1, 1);
    
    // Eyes
    s += box(p, 6, 5, 1, 1);
    return s;
}

vec3 drawPiggy(vec2 ipos, vec3 col, vec3 bgcol, float shade) {
    ipos.x = abs(ipos.x);
    col = mix(col, mix(bgcol, pink, shade), drawPink(ipos));
    col = mix(col, mix(bgcol, black, shade), drawBlack(ipos));
    col = mix(col, mix(bgcol, darkPink, shade), drawDarkPink(ipos));
    return col;
}

vec3 drawGridPiggy(vec2 uv, vec3 col, vec3 bgcol, float i, float n, float m) {
    float io = 0.25 * 3.14159 * i /n;
    
    float th = tanh(0.3 * max(0., t - 1.5));
    uv *= rot(th * (pi * cos(0.5 * t + 4. * io)));  
    uv.y += th * cos(t + io);
    
    vec2 o = vec2(cos(t + io), sin(t + io));
    vec2 fpos = fract((n-i) * uv + t + o) - 0.5;
    vec2 ipos2 = floor((m + 4. * cos(10.*uv.x + io + 10.*t)) * fpos + vec2(0,0.5)) ;
    return drawPiggy(ipos2, col, bgcol, i /n);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    vec3 bgcol = vec3(exp(-abs(uv)), 0.8 + 0.2 * cos(length(uv) - t));
    vec3 col = bgcol;
    
    // Number of layers
    float n = 14.;
    
    // Grid piggy scale
    float m = 50.;
    
    // Centre piggy scale
    float piggyAmount = 0.45 + 0.4 * cos(4.*t);
    float piggyLayer = piggyAmount * n;
    float piggyScale = piggyLayer * m;
    
    // Back piggies
    for (float i = 0.; i <= floor(n - piggyLayer); i++) 
        col = drawGridPiggy(uv, col, bgcol, i, n, m);   
    
    // Centre piggy
    vec2 ipos1 = floor(piggyScale * uv + vec2(0, 2.5));
    col = drawPiggy(ipos1, col, bgcol, 1. - piggyAmount);
    
    // Front piggies
    for (float i = ceil(n - piggyLayer); i < n; i++)
        col = drawGridPiggy(uv, col, bgcol, i, n, m);
       
    glFragColor = vec4(col,1.0);
}
