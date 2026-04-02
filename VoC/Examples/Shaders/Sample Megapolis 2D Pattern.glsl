#version 420

// original https://www.shadertoy.com/view/3t2SWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// extracted and refactored from skaplun 3D "Megapolis" https://shadertoy.com/view/MlKBWD

#define TIME_MULT   .25
#define IDLE_TIME   .05

#define rnd(p) fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453123)

void main(void) {
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec2 R  = resolution.xy;
    float p = 6./R.y;
    U *= p;
    O-=O; 
    
    float t = fract(time * TIME_MULT),
         mt = ceil(time * TIME_MULT),
        cellStartTime = rnd(ceil(U) * mt) * .5 + IDLE_TIME,
          w = .25 + .75* smoothstep(0., .175, t-cellStartTime-.225);

    if (t > cellStartTime) 
        U = smoothstep(p,0.,abs(fract(U)-.5) - w/2. ),
        O += U.x*U.y;

    glFragColor = O;
 }
