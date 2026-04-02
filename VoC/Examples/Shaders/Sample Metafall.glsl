#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wllGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2 R = resolution.xy, P,D,
         U = u / R.y, V = 15.*U; V.y += time;
    float p = 0.;
    
    for (int k=0; k<9; k++)                            // neigborhood
        P = vec2(k%3-1,k/3-1),                         // cur. cell 
        D = fract(1e4*sin(ceil(V-P)*mat2(R.xyyx)))-.5, // node = random offset in cell
        P = fract(V) -.5 + P+ D,                       // node rel. coords
        p += smoothstep( 1.3*U.y,0.,length(P) );       // its potential

    glFragColor = vec4( (p -.5) / fwidth(p) ); // * vec4(.5,.7,1.2,1);
}
