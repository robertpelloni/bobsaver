#version 420

// original https://www.shadertoy.com/view/sdKBRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Circle(vec2 uv, vec2 pos, float r, float b)
{
    uv -= pos;
    float d = length(uv);
    return (1.0 - smoothstep(r, r - b, d)) * (1.0 - smoothstep(r, r + b, d));
}

float Pulse(vec2 uv, float t)
{
    float offset = 0.4;
    uv.x += offset * sin(t);
    uv.y += offset * cos(t);
    
    float r = 1.0  * (sin(t) + 1.0);
    float v = max(sin(t)  - sin(t - 1.0), 0.0);
    return v * Circle(uv, vec2(0.0), r, r * r / 2.8);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x / resolution.y;
    vec2 origin = vec2(0.5, 0.5);

    uv = (uv - origin) * 2.0;
    uv.x = uv.x * aspect;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    vec3 color = vec3(1.0);

    float mask = 0.0;
    
    for(int i = 0; i < 7; i++)
    {
        float t = time + float(i);
        mask += Pulse(uv, t);
    }    
    color = col * mask;

    // Output to screen
    glFragColor = vec4(color, 1.0);
}
