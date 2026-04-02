#version 420

// original https://www.shadertoy.com/view/ldcfz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANIM (-cos(time) + 1.0)/2.0
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.0 * (gl_FragCoord.xy/resolution.y - vec2(0.5 * resolution.x / resolution.y, 0.5));

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    vec3 inv = vec3(1.0);
        
    float d = length(uv - vec2(0));
    d -= 0.10 * ANIM;
    float st = 0.2;

    st += 0.1 * ANIM;
    float nd = 2.0;
    float w = 0.2;
    nd += 0.3 * ANIM;
    
    inv *= smoothstep(st-st*fract(ANIM), nd, d) - smoothstep(st+w, nd, d);
    
    col *= 1.0 - d;
    
    float intensity = 3.0;
    
    col = mix(intensity*col, inv, ANIM / 2.0 - 0.5);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
