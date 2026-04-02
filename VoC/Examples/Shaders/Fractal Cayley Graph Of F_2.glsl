#version 420

// original https://www.shadertoy.com/view/Xsdczr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float w() {
    return 1./resolution.y;
}

void tree( vec2 pos, float len, inout vec4 color) {
    for(int i=0;i<9;i++) {
        color *= smoothstep(-0.1, 0.1, (length(pos) - len*0.08) * 100.);
        color *= max(
            smoothstep(-0.1, 0.1, (abs(pos.y)-w()) * 100.), 
            smoothstep(-0.1, 0.1, (abs(pos.x-len/2.)-len/2.) * 100.)
        );
        pos.x -= len;
        if(pos.y > 0. && pos.x < pos.y) pos *= mat2(0,1,-1,0);
        else if(pos.y < 0. && pos.x < -pos.y) pos *= mat2(0,-1,1,0);
        len *= 0.48;
    }
}
void three( vec2 pos, float len, inout vec4 color) {
    tree(pos, len, color);
    tree(pos.yx, len, color);
    tree(-pos.yx, len, color);
}
float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}
float dir(float t) {
    float orig = floor(rand(vec2(t,0.)) * 4.);
    float prev = floor(rand(vec2(t-1.,0.)) * 4.);
    float next = floor(rand(vec2(t+1.,0.)) * 4.);
    if(mod(t,2.) < 0.5) {
        // do not back
        for(int i=0;i<4;i++) {
            if(orig==prev || orig==next) orig = mod(orig+1., 4.);
        }
    }
    return orig;
}

void main(void)
{
    vec2 pos = (gl_FragCoord.xy-resolution.xy/2.)/resolution.y;
    glFragColor = vec4(1.0);
    float ratio = smoothstep(0.,1.,mod(time,1.));
    float a = (dir(floor(time)) + mod(floor(time),2.) * 2.) * 3.1415926535/2.;
    pos *= mat2(cos(a),sin(a),-sin(a),cos(a));
    float s1 = mix(1.,0.48,1.-pow(1.-ratio,1.5));
    float s2 = mix(1.,0.48,1.-pow(ratio,1.5));
    three(pos - vec2(0.4*ratio, 0.), 0.4*s1, glFragColor);
    three(-pos - vec2(0.4*(1.-ratio), 0.), 0.4*s2, glFragColor);
    glFragColor = min(glFragColor, max(
        smoothstep(-0.1, 0.1, (abs(pos.y)-w()) * 100.),
        smoothstep(-0.1, 0.1, (abs(-pos.x)-0.8/2.) * 100.)
    ));
}
