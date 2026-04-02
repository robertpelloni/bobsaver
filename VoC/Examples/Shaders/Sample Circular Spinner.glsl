#version 420

// original https://www.shadertoy.com/view/WtBfzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float AA = .01;

const float PI = radians(180.);

mat2 rot(in float t) {
    float c = cos(t);
    float s = sin(t);
    return mat2(c, -s, s, c);
}

float atan2(in vec2 p){
    return p.x == 0.? sign(p.y)*PI/2.: atan(p.y, p.x);
}

float circle(in vec2 uv, in float w, in vec2 theta) {
    float len = length(uv);
    float t   = atan2(uv);
    return
        smoothstep(1.-w-AA, 1.-w, len) *
        (1.-smoothstep(1.-AA, 1., len)) *
        smoothstep(theta.x, theta.x+AA, t) *
        (1.-smoothstep(theta.y, theta.y+AA, t));
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy*2. - 1.;
    uv.x *= resolution.x/resolution.y;
    
    float t = fract(time/5.);
    t  = t*t*(3.-2.*t);
    
    float theta = t*2.*PI;
    
    vec3 col = vec3(1.);
    for (float i = 0.; i < 10.; ++i) {
        uv *= rot(theta+PI/6.);
        
        glFragColor.rgb += col*circle(uv, .05, vec2(-PI, abs(t*2.-1.)*PI));
        col *= .95;
        uv  *= 1.1;
    }
}
