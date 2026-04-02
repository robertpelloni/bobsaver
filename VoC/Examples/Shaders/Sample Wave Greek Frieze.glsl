#version 420

// original https://www.shadertoy.com/view/MtjfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// variant of https://shadertoy.com/view/MljBDG
// variant of https://shadertoy.com/view/ll2fWG

void main(void){
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;
    vec2 R = resolution.xy;
    vec2 U = 8.*u/R.y, V; U.x -= time; V = floor(U);
    float s = sign(mod(U.y,2.)-1.);
    U.y = dot( cos( (2.*(time+V.x)) * (V.y>3.?s:1.) * max(0.,.5-length(U = fract(U)-.5)) - vec2(33,0) ), U); \
    O += smoothstep(-1.,1., s*U.y / fwidth(U.y) );
    glFragColor = O;
}
        
