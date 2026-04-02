#version 420

// original https://www.shadertoy.com/view/WddGR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv1 = (1.2*gl_FragCoord.xy - resolution.xy) /resolution.y;
    vec2 uv;
    uv.x = uv1.x*cos(1.0*time) - uv1.y*sin(1.0*time);
    uv.y = uv1.x*sin(-1.1*time) + uv1.y*cos(1.3*time);
    // Time varying pixel color
    float r = 0.3 + 0.45*cos(0.923*time + 2.0 + sin(-uv.x+uv.y));
    float g = 0.45 + 0.27*sin(1.3*time + 4.0 + sin(2.0*uv.x) + smoothstep(0.0,1.0,cos(uv.y + uv.x)));
    float b = 0.4 + 0.32*cos(-0.57*time + 6.0 + uv.x*1.8*uv.y);
    vec3 col = vec3(b,r,g);
    
    //col = vec3(uv.x,uv.y,0.0);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
