#version 420

// original https://www.shadertoy.com/view/WtKXD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415;
mat2 rot(float t){
    return mat2(cos(t),sin(t),-sin(t),cos(t));
}

float triwave(float x)
{
    return 1.0-4.0*abs(0.5-fract(0.5*x + 0.25));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    float offset = 1. - sin(time);
    
    vec2 f = abs(uv);
    vec2 e = floor(f);
    
    for (int i=0;i<6;i++){
    f *= 3.;
    e = floor(f-offset); f = fract(f); 
    f = f * ( ((e.x == 0.) && (e.y == 0.))?0.:1. );
    }
    
    
    
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    col = smoothstep(0.1,0.,dot(f,f)) * col;
    // Output to screen
    glFragColor = vec4(col,1.0);
}

