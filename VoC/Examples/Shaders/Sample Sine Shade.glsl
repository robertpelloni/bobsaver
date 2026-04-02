#version 420

// original https://www.shadertoy.com/view/ctB3Wy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592635
void main(void)
{    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Scale the coordinates
    uv *= 2.4;
    uv -= vec2(1.2);

    // Create the sine wave 
    float y = 0.5*sin(-0.2+2.0*(uv.x-0.2*time) * PI);

    // Add a shade to the wave 
    float c = smoothstep(y, uv.y, uv.y+ max(0.03*sin(0.6*uv.x * PI + PI/2.0), 0.0));

    // Cap end parts (can this be clamped?)
    if( uv.x < -1.0 || uv.x > 1.0 ) {
        c = 1.0;
    }
        
    // Output color
    glFragColor = vec4(vec3(c), 1.0);
}
