#version 420

// original https://www.shadertoy.com/view/mly3W1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pattern(vec3 p, float time)
{
    float r = length(p.xy) * time;
    float angle = atan(p.y, p.x) + time * 0.2;
    float z = p.z * sin(time) * 0.1;
    float color = sin(5.0 * (r - time)) + cos(10.0 * angle) + 2.0 + z;
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y - vec2(0.5*resolution.x/resolution.y, 0.5);
    
    float time = time * 0.3;

    vec3 color = vec3(0.0);
    for(float z = -1.0; z <= 1.0; z += 0.5)
    {
        vec3 p = vec3(uv, z);
        color += cos(pattern(p, time)) * vec3(1.0, 0.5, 0.3);
        color += sin(pattern(p, time + 0.33)) * vec3(0.3, 0.5, 1.0);
        color += cos(pattern(p, time + 0.66)) * vec3(0.5, 1.0, 0.3);
    }
    color /= 6.0;

    glFragColor = vec4(color, 1.0);
}
