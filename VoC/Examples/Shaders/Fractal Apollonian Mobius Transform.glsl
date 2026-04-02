#version 420

// original https://www.shadertoy.com/view/tsVSRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 p = 6.0*(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    vec3 z = vec3(p, 1.0);
    vec2 b = (0.5*resolution.xy - mouse*resolution.xy.xy)/resolution.y;
    float a = 2.0 + b.x;
    
    z /= dot(z.xy,z.xy);
    z.x += mod(time*0.25, a);
    z.y += b.y;
    
    for (int i = 0; i < 18; ++i) {
        z /= dot(z.xy,z.xy);
        z.xy = abs(mod(z.xy - a*0.5, a) - a*0.5);
    }
    
    float col = z.y*resolution.y*0.1 / z.z;

    glFragColor = vec4(col, col, col, 1.0);
}
