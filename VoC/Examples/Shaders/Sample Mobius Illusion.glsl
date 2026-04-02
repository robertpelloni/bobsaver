#version 420

// original https://www.shadertoy.com/view/ttVXR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// From this video https://youtu.be/2SzmkCseDi0?t=337

float tau = 6.28;

float doPatt(vec2 uv){
    
    vec2 uvp = vec2(atan(uv.y, uv.x)/tau, length(uv));
    
    float uvpb = mod(uvp.x*80.,1.) - 0.5;

    uvpb *= length(uvp.y)*4.;
    
    return smoothstep(0.2,0.01, abs(uvpb) - 0.2 + - sin(mouse.x*resolution.xy.x/resolution.x)*0.2 )*(smoothstep(0.,1.,length(uv)*2.));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(1);

    
    
    col -= doPatt(uv);
    col -= doPatt(uv + vec2(0.04 + sin(time)*0.04, 0.04 + sin(time)*0.04));
    col -= doPatt(uv + vec2(-0.05, 0.1));
    
    
    glFragColor = vec4(col,1.0);
}
