#version 420

// original https://www.shadertoy.com/view/wsSBRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float distCustom(float x, float y)
{
    float n = -0.5 * abs(x) + y;
    return log(
        x * x + 1.5 * n * n
    );
}

float fn(float x, float multi, float offset)
{
    return max(0.0, min(1.0, (sin(x * 3.14159265) + offset) * multi));
}

void main(void)
{
    const float PI = 3.14159265;
    const float PI_3 = PI / 3.;
    const float speed = 5.;
    const float density = 3.;
    const float period = 15.;
    const vec3 color1 = vec3(1.2, 0.5, 0.8);
    const vec3 color2 = vec3(0.3, 0.8, 1.0);
    
    float hue = time * 2. * PI / 5.;
    vec3 color3 = (vec3(sin(hue), sin(hue + 2. * PI_3), sin(hue - 2. * PI_3)) + 1.0) * .5;
    
    // Normalized pixel coordinates (from 0 to 1)
    float scale = min(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= vec2(resolution.x / scale, resolution.y / scale) / 2.;
    uv *= 2.0;
    
    float dist = log(uv.x*uv.x+uv.y*uv.y) / 2.;
    float distH = distCustom(uv.x, uv.y);
    float angle = atan(uv.y, uv.x);
    
    float timeH = 32.0 * cos(smoothstep(0.0, 1.0, fract(time / period)) * PI);
    
    // Time varying pixel color
    float c1 = fn((distH + timeH) * density + 0.0, 1.8, -0.2);
    float c2 = fn((distH + timeH) * density + 0.8, 4., -0.7);
    float c3 = fn(dist * 4.0 + angle / PI + time * speed + PI, 3.0, -0.8);
    // Output to screen
    glFragColor = vec4(
        c1 * color1 + c2 * color2 + c3 * color3,
        1.
    );
}
