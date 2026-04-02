#version 420

// original https://www.shadertoy.com/view/Ndt3Dl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU (2.*PI)

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

vec3 blue = vec3(0.000,0.631,0.616);
vec3 white = vec3(1.000,0.973,0.898);
vec3 yellow = vec3(1.000,0.702,0.267);
vec3 red = vec3(0.878,0.365,0.365);

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float circle(vec2 st, vec2 center, float radius) {
    return 1.0 - step(radius, length(st - center));
}

float circleOutline(vec2 st, vec2 center, float radius, float thickness) {
    float distToEdge = abs(radius - length(st - center));
    return 1.0 - step(thickness, distToEdge);
}

float cornerCircle(vec2 st, float radius) {
    float corner = 0.;
    corner += circle(st, vec2(-.5,.5), radius);
    corner += circle(st, vec2(.5,.5), radius);
    corner += circle(st, vec2(-.5,-.5), radius);
    corner += circle(st, vec2(.5,-.5), radius);
    return corner;
}

float line(float p, float mi, float mx) {
    return step(mi, p) * (1.0-step(mx, p));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xx;
    
    // rotate
    //uv *= rot(-time*0.05);
    uv *= rot(PI*0.12);
    // zoom
    //uv *= mix(0.7, 1.3, 0.5 * 0.5 * sin((time+PI)*5.));
    uv *= 1.4;
    // pan
    uv += vec2(time*0.07);
    
    // Repitition
    uv *= 5.0;
    vec2 id = floor(uv);
    vec2 gv = fract(uv);
    
    
    vec3 col = red;
    
    float stripe_str = 0.8;
    float stripes = ceil(sin(gv.x*PI*60.));
    col = mix(col, stripe_str*red, stripes);
    
    // Randomly rotate by some multiple of PI/2
    //float n = hash12(id+time*0.00001);
    float n = hash12(id);
    
    n *= TAU;
    n = floor(n / (PI/2.)) * (PI/2.);
    
    gv -= 0.5;
    gv *= rot(n);
    
    float off = 0.5 - 0.5 * sin(time);
    off *= 0.4;
    off = 0.287;
    
    col = mix(col, white, line(gv.x - gv.y, off + -1., off + -.9));
    col = mix(col, yellow, line(gv.x - gv.y, off + -.87, off + -.7));
    col = mix(col, blue, line(gv.x - gv.y, off + -.67, off + -.6));
    
    col = mix(col, blue, line(gv.x - gv.y, .9 - off, 1. - off));
    col = mix(col, white, line(gv.x - gv.y, .7 - off, .87 - off));
    col = mix(col, blue, line(gv.x - gv.y, .6 - off, .67 - off));
    
    float osc = 0.5 + 0.5 * sin(time*5.0);
    
    // center circle
    col = mix(col, white, circle(gv, vec2(0), osc*0.1));
    vec3 yellowstripes = mix(yellow, stripe_str*yellow, stripes);
    col = mix(col, yellowstripes, circle(gv, vec2(0), osc*0.05));
    
    // corner circles
    col = mix(col, white, cornerCircle(gv, (1.-osc)*0.1));
    vec3 bluestripes = mix(blue, stripe_str*blue, stripes);
    col = mix(col, bluestripes, cornerCircle(gv, (1.-osc)*0.05));
    
    
    glFragColor = vec4(col,1.0);
}
