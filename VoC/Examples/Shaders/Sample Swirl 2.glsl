#version 420

// original https://www.shadertoy.com/view/3sBXDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float r_2 = (uv.x - 0.5)*(uv.x - 0.5) + (uv.y - 0.5) * (uv.y - 0.5);
    float radius = sqrt(r_2);
    float angle = atan((uv.y - 0.5)/(uv.x - 0.5)); 
 
    float intensity = sin(-time*10. + radius*50. + angle*2.);

    // Output to screen
    glFragColor = vec4(
        intensity*vec3(0.0,1.0,1.0) + -intensity*vec3(1.0,0.0,0.0),
        1.0);

}
