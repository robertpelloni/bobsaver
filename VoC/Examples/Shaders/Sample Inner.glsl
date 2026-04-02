#version 420

// original https://www.shadertoy.com/view/XdGfW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rep 0.8 // try smaller numbers around 0.2. looks cool

void main(void)
{
    vec2 uv = 2.0*vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    float mx = 0.0;//gl_FragCoord.x / mouse*resolution.y;
    
    vec3 pixel = vec3(0.2, 0.2, 0.2); 
    
    vec2 h = fract(uv / length(rep * uv * uv) + time);

    h -= 0.5;
    
    pixel = mix(pixel, vec3(0.0, 1.0, 0.0), step(min(h.x, h.y), 0.01));
    
    float shade = smoothstep(0.68, 0.0, h.x); // lines shadows
       float s = smoothstep(-0.005, 0.22, length(uv * uv) * 0.5); // far dark shadow
    vec3 s2 =  mix(vec3(1.0, 0.0, 1.0), vec3(.3, 1.0, 1.3), 0.2); // additional coloring
    
    glFragColor = vec4(mix(pixel, s2, 0.25) * shade * s * 1.2, 1.0);
    
}
