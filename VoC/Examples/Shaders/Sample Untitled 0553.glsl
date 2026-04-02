#version 420

// original https://www.shadertoy.com/view/3dSyDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Coordinate Scaling
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / min(resolution.x, resolution.y);
    
    // polar coordinates
    float theta = atan(uv.y / uv.x);
    float r = length(uv) - .1*time;
    
    // repeats
    float d = 0.1; 
    
    // get ID
    float ringID = floor(r / d);
    // Make every other ID negative
    if(mod(ringID, 2.0) == 1.0){ ringID *= -1.; }
    
    // Colouring with polar coordinates
    // and spinning from ring number
    float l = mod(r, d) * sin(theta*20. + time*ringID);
    
    // Ring colouring
       vec3 colour = vec3(1., cos(ringID), sin(ringID));   // red
    float strength = l / d;                           // Will give 1 when l = d and 0 when l = 0
    
    // smooth step shadows
    strength *= smoothstep(0.1, 0.3, length(uv)) * smoothstep(0.9, 0.5, length(uv));
    
    // final colour
    glFragColor.xyz = colour * strength;
}

