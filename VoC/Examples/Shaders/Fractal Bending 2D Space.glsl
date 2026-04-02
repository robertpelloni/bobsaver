#version 420

// original https://www.shadertoy.com/view/3dKXzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Space is bended so the fractals can be drawn with a single length() command
// x-axis is green
// y-axis is red
// space origin is blue
// fractal is white
//
// The Koch fractal is just a line being drawn in a bended space.
// The Sierpinski carpet fractal is just a square being drawn in a bended space.
// The Sierpinski carpet fractal is just a triangle being drawn in a bended space.
    
#define PI 3.141592653589793238

vec2 sincos(float angle) {
    return vec2(sin(angle), cos(angle));
}

vec2 mirror(vec2 uv, vec2 p, float angle) {    
    vec2 n = sincos(angle);
    return uv - n*min(dot(uv - p, n), 0.0)*2.0;
}

vec2 rotate2d(vec2 uv, float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * uv;
}

float sd_equilateral_triangle(vec2 p) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if(p.x+k*p.y>0.0) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float fractal_koch(inout vec2 uv, int steps) {
    float scale = 1.0;
    uv.y -= sqrt(3.0)/6.0;
    uv.x = abs(uv.x);
    uv = mirror(uv, vec2(0.5, 0), 11.0/6.0*PI);
    uv.x += 0.5;
    for(int i=0;i<steps; ++i) {
        uv.x -= 0.5;
        uv *= 3.0;
        scale *= 3.0;
        uv.x = abs(uv.x);
        uv.x -= 0.5;
        uv = mirror(uv, vec2(0,0), (2.0/3.0)*PI);
    }
    uv.x = abs(uv.x);
    float d = length(uv - vec2(min(uv.x,1.0),0.0)) / scale;
    uv /= scale;
    return d;
}

float fractal_sierpinski_carpet(inout vec2 uv, int steps) {
    float scale = 4.0;
    uv *= 4.0;
    uv = abs(uv);

    for(int i=0;i<steps;++i) {
        uv *= 3.0;
        scale *= 3.0;
        uv = abs(uv);
        uv *= 1.0 - step(uv.x, 3.0)*step(uv.y, 3.0);
        uv -= vec2(0, 3); uv = abs(uv);
        uv -= vec2(0, 3); uv = abs(uv);
        uv -= vec2(3, 0); uv = abs(uv);
        uv -= vec2(3, 0); uv = abs(uv);
    }

    float d = length(uv - vec2(min(uv,vec2(1)))) / scale;
    uv /= scale;
    return d;
}

float fractal_sierpinski_triangle(inout vec2 uv, int steps) {
    float scale = 1.5;
    uv *= 1.5;
    for(int i=0;i<steps;++i) {
        uv *= 2.0;
        scale *= 2.0;
        uv.y -= 2.0*sqrt(3.0)/3.0;
        uv.x = abs(uv.x);
        uv = mirror(uv, vec2(1.0,-sqrt(3.0)/3.0), (11.0/6.0)*PI);
    }

    float d = sd_equilateral_triangle(uv) / scale;
    uv /= scale;
    return d;
}

void main(void) {
    vec2 coord = gl_FragCoord.xy;

    vec3 col;

    vec2 uv = 2.0*(coord-0.5*resolution.xy)/resolution.y;
    vec2 mouse = (mouse*resolution.xy.xy - 0.5*resolution.xy)/resolution.xy;
    uv = rotate2d(uv, atan(mouse.y, mouse.x) + 3.0*PI/4.0);

    float d;

    int mode = int(mod(time / 6.0, 3.0));
    int iterations = 5 - int(mod(time, 6.0));
    switch(mode) {
        case 0:
            d = fractal_koch(uv, iterations);
            break;
        case 1:
            d = fractal_sierpinski_carpet(uv, iterations);
            break;
        case 2:
            d = fractal_sierpinski_triangle(uv, iterations);
            break;
    }

    float linewidth = 4.0/resolution.y;
    col += smoothstep(linewidth, 0.0, d) * 0.5;
    col.rg += smoothstep(-0.5, 0.5, sin(time*10.0+uv*100.0)) * 0.1;
    col.r += smoothstep(linewidth, 0.0, length(uv.x))*0.5;
    col.g += smoothstep(linewidth, 0.0, length(uv.y))*0.5;
    col.b += smoothstep(linewidth, 0.0, pow(length(uv), 1.4));

    glFragColor = vec4(col,1);
}
