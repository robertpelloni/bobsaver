#version 420

// original https://www.shadertoy.com/view/WlGGWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 s = resolution.xy;
    
    vec2 p = (gl_FragCoord.xy-s*0.5)/s.y;
    
    float a = atan(p.x, p.y);
    
    float l = log(length(p))-time;
    
    float d = sin(a + 6.28318 * l);
    
    float c = smoothstep(0.5-d, d+0.5, d*sin(d));

    glFragColor = vec4(sin(vec3(8,12,10)*c),1);
}
