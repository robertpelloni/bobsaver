#version 420

// original https://www.shadertoy.com/view/Wdt3D4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float func(float x)
{
    return sin(x);
}

void main(void)
{
    float pi = 3.14159265;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float val = 0.0;
    vec3 col3 = vec3(0.0);
    
    for (float i = 0.0; i < 1.0; i += 0.15)
    {
        vec2 p = vec2(uv.x * 5.0 + time * (mod(pow(i * 5.0 + 2.0, 3.0), 2.77) - 1.4), uv.y * 5.0 - i * 5.0);
        vec2 psin = vec2(p.x, func(p.x));

        val += max(0.0, 1.0 - pow(distance(psin, p) * 2.6, 0.85));
    }
    
    vec3 col = vec3(sin(time * 1.3 + uv.x), cos(time * -0.57 + uv.y), cos(time)) / 2.0 + 0.5;
    col3 = col * pow(val, 2.0);
    // Output to screen
    glFragColor = vec4(col3, 1.0);
}
