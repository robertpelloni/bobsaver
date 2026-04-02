#version 420

// original https://www.shadertoy.com/view/wlySWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float fn2(float x)
{
    x = mod(x + 1.0, 2.0) - 1.0;
    float n = x * x * x;
    return (8. * n - 4. * x) * 3.14159265;
}

float fn(float x)
{
    float n = abs(sin(x));
    return max((n - 0.5) * 1.5, 0.);
}

float vignette(float v, float d)
{
    return v * (0.8 - 0.7 * d);
}

void main(void)
{
    const float PI = 3.14159265;
    const float PI_3 = PI / 3.;
    const float speed = 0.4;
    float hue = fract(time / 2.) * PI;
    
    // Normalized pixel coordinates (from 0 to 1)
    float scale = min(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= vec2(resolution.x / scale, resolution.y / scale) / 2.;
    uv *= 2.0;
    
    //float distance = length(uv);
    //float distance = pow(sqrt(uv.x*uv.x+uv.y*uv.y), 1./3.);
    float distance = log(uv.x*uv.x+uv.y*uv.y) / 2.;
    float angle = atan(uv.y, uv.x);
    
    // Time varying pixel color
    // spiral 1
    float c1 = vignette(fn(distance * 3.0 + angle * 3.0 + fn2(time * speed) + PI), distance);
    // spiral 2
    float c2 = vignette(fn(distance * 3.0 - angle * 3.0 + fn2((time * speed) + 2. / 3.) + PI), distance);
    // rings 
    float c3 = vignette(fn(angle * 16.0 + sin(time) * 8.0 - time * 0.5) * 0.5
             + fn(distance * 8.0 + fn2((time * speed) + 4. / 3.) * 0.5), distance);
    
    // Flashing
    const float flashIntvl = 1.2;
    const float flashStrength = 1.5;
    const float flashSudden = flashStrength / flashIntvl * 4.0;
    float f1 = max(0., flashStrength - mod(time, flashIntvl) * flashSudden);
    float f2 = max(0., flashStrength - mod(time + flashIntvl * 1.0/3.0, flashIntvl) * flashSudden);
    float f3 = max(0., flashStrength - mod(time + flashIntvl * 2.0/3.0, flashIntvl) * flashSudden);
    c1 += f1; c2 += f2; c3 += f3;

    // Output to screen
    glFragColor = vec4(
        abs(c1 * sin(hue))        + abs(c2 * -sin(hue + PI_3)) + abs(c3 * -sin(hue - PI_3)),
        abs(c1 * sin(hue + PI_3)) + abs(c2 * -sin(hue - PI_3)) + abs(c3 * -sin(hue)),
        abs(c1 * sin(hue - PI_3)) + abs(c2 * -sin(hue))        + abs(c3 * -sin(hue + PI_3)),
        1
    );
}
