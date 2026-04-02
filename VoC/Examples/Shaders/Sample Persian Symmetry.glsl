#version 420

// original https://www.shadertoy.com/view/ldSXzc

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 fold = vec2(-0.5, -0.5);
vec2 translate = vec2(1.5);
float scale = 1.25;

vec3 hsv(float h,float s,float v) {
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

vec2 rotate(vec2 p, float a){
    return vec2(p.x*cos(a)-p.y*sin(a), p.x*sin(a)+p.y*cos(a));
}

void main( void ) {
    vec2 p = -1.0 + 2.0*gl_FragCoord.xy/resolution.xy;
    p.x *= resolution.x/resolution.y;
    p *= 0.022;
    float x = p.y;
    p = abs(mod(p, 4.0) - 2.0);
    for(int i = 0; i < 34; i++){
        p = abs(p - fold) + fold;
        p = p*scale - translate;
        p = rotate(p, 3.14159/(0.10+sin(time*0.0005+float(i)*0.1)*0.5+0.50));
    }
    float i = x*10.0 + atan(p.y, p.x) + time*0.5;
    float h = floor(i*6.0)/5.0 + 0.07;
    h += smoothstep(0.0, 0.4, mod(i*6.0/5.0, 1.0/5.0)*5.0)/5.0 - 0.5;
    glFragColor=vec4(hsv(h, 1.0, smoothstep(-1.0, 3.0, length(p))), 30);
}
