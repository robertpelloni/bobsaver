#version 420

// original https://www.shadertoy.com/view/wtG3DK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphere(vec2 uv, float size, vec3 movement)
{
    float x_pos = tanh(movement.x*(sin(movement.y*time))) * movement.z;
    return 1.f / distance(vec2(x_pos, 0), uv) * size;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    uv.x *= resolution.x / resolution.y;

    //uv.y += sin(1200.5 * uv.x)*0.01;
    
    float b = sphere(uv, 0.7f, vec3(0));
    float d = sphere(uv, 0.3f, vec3(1.5f, 1.5f, 0.6f));
    //float c = sphere(uv, 0.1f, vec3(1.f, 1.643453f, 0.7f));
    
    if (d+b < 6.0) glFragColor = vec4(b-d, (d-b)*5.2, d * b * 0.9, 0).brga * 0.2;
    else glFragColor = vec4(1);
}
