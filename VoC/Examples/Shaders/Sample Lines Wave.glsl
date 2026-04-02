#version 420

// original https://www.shadertoy.com/view/llsSzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec2 mouse = mouse.xy / resolution.xy;
    float aspect = resolution.x / resolution.y;
    vec2 position = 0.5 - uv;
    vec2 uva = vec2(position.x, position.y / aspect);
    uva.x += .3 * (mouse.x / 2.0);
    uva.y += .5 * (mouse.y / 2.0);
    float radius = .1;
    float r = 10.0 * sqrt(dot(uva, uva));
    vec2 uvd = uva;
    uvd.x = uvd.x + .1 * cos(10. * uvd.y + 0.5 * time );
    uvd.y = uvd.y + .1 * sin(10. * uvd.x + 0.5 * time );
    
    float r1 = 10.0 * sqrt(dot(uvd, uvd));
    
    float value = 1000.0 * 0.2 * radius * r1;
    
    float col = smoothstep(0.2, 0.22, sin(value) * 0.9);
    vec3 color = vec3(col, col, col);
    glFragColor = vec4(color, 1.0);
}
