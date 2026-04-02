#version 420

// original https://www.shadertoy.com/view/3st3WX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;
    
    vec2 q = p-vec2(0.5,0.5);

    q.x *= resolution.x / resolution.y;
    
    vec3 col = vec3(1.0,1.0,1.0);

    q = abs(q); //symmetry
    q = (q + vec2(q.y, -q.x))*sqrt(0.5); // rotate 45 degrees

    
    float r = 0.3 + 0.1*cos(atan(q.y,q.x)*time*20.0);

    col *= smoothstep(r, r+0.01, length(q)); 

    glFragColor = vec4(sin(col.x), sin(col.y-r), sin(col.z-r) ,1.0);
}
