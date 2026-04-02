#version 420

// original https://www.shadertoy.com/view/WlXcR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float spacing = 0.2;
const float margin = 0.1;

float checkerboard(vec2 pos) {
    vec2 p = mod(pos, spacing);
    
    //Smoothstep
    float w = fwidth(pos.x); // to recover the scaling;
    p = smoothstep(-w, w, p-.1);
    
    // Step
    //p = step(margin, p);
    
    return max(p.x, p.y);
}
const vec3 blue = vec3(0,0,1);
const vec3 green = vec3(0,1,0);
const vec3 red = vec3(1,0,0);
const vec3 black = vec3(0,0,0);

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 pos = gl_FragCoord.xy/resolution.xy * 2. - 1.;
    pos.x *= resolution.x/resolution.y;
    
    float time = time;
    
    float blueCheckerboard = checkerboard((pos + time/8.) * sin(time/8.) * (sin(time/8.) + 0.5));
    float greenCheckerboard = checkerboard((pos - time/16.)* sin(time/8.));
    float redCheckerboard = checkerboard((pos + time/8.) * sin(time/8.) + vec2(0.2, 0.2*sin(time/8.)));
    
    vec3 color =  blueCheckerboard * blue
        + (1. - blueCheckerboard) * greenCheckerboard * green
        + (1. - blueCheckerboard) * (1. - greenCheckerboard) * redCheckerboard * red;
    //glFragColor = vec4(color, 1.0);                    
 
    glFragColor = vec4(pow(color,vec3(1./2.2)), 1);   
}
