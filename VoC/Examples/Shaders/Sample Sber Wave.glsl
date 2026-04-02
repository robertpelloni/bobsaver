#version 420

// original https://www.shadertoy.com/view/Wt3GDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float time = time * 2.;
    // Time varying pixel color
    vec3 col = vec3(1);
    
    vec3 gr = vec3(0.1, 0.6, 0.2);
    
    float w = uv.y - 0.3;
    w += sin(uv.x * 4. + time/3.) / 8.;
    w += sin(uv.x * 8. + time/2.) / 16.;
    w += sin(uv.x * 16. - time/1.) / 32.;
    
    w = smoothstep(0.02, 0., w);
    w -= step(0.9, sin(uv.x * 220.));
    
    w -= smoothstep(0.3, 0., uv.x);
    w -= smoothstep(0.7, 1., uv.x);
    col = mix(col, gr, w);
    
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
