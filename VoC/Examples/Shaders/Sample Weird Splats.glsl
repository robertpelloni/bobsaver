#version 420

// original https://www.shadertoy.com/view/dsjBzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{  
    vec2 I=gl_FragCoord.xy;
    vec4 O=vec4(0.0);
    
    I = 4. * I / resolution.y + 1e2 + .4 * time;   
    mat2 M = -mat2(.766,.643, -.643,.766); // rot(a = 21*pi/27)
    O -= O;
    for (int i; i++ < 27;) {   
        I *= M;
        //pow(fract(I.y), 2.); is good too
        O.x += pow(4. * fract(I.y) * (1. - fract(I.y)), 40.);
        O.y += cos(2. * O.x);
        O.yz *= M;
        O.z += cos(O.y);
        O.zw *= M;
        O.w += cos(O.z);
    }
    glFragColor = tanh(.5 * O.yyyy);    
}