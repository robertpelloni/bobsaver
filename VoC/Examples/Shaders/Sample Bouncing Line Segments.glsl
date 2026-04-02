#version 420

// original https://www.shadertoy.com/view/MlBSWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Line Segments (bouncing) "screensaver" written 2015 by Jakob Thomsen

// mirror/bounce inside -1,+1
vec2 mirror(vec2 pos)
{
    return (2.0 * abs(2.0 * fract(pos) - 1.0) - 1.0);
}

float PointLineAlong2d(vec2 a, vec2 n, vec2 p)
{
    return dot(p - a, n) / dot(n, n);
}

float PointLineDist2d(vec2 a, vec2 n, vec2 p)
{
    //return length(p - (a + n * dot(p - a, n) / dot(n, n)));
    return length(p - (a + n * PointLineAlong2d(a, n, p)));
}

float PointLineSegDist2d(vec2 a, vec2 n, vec2 p)
{
    float q = PointLineAlong2d(a, n, p);
    if(q < 0.0)
        return length(p - a);
    if(q > 1.0)
        return length(p - (a + n));
    
    return length(p - (a + n * q));
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec2 speed0 = vec2(0.0432, 0.0123)*2.0;
    vec2 speed1 = vec2(0.0257, 0.0332)*2.0;
    vec2 I = 2.0 * (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.xy;
    const float n = 50.0;
    for(float i = 0.0; i < n; i++)
    {
        vec2 a = mirror((time - i * .1) * speed0);
        vec2 b = mirror((time - i * .1) * speed1);
        float d = PointLineSegDist2d(a, b - a, I);
        glFragColor = max(glFragColor, vec4(1.0 - smoothstep(0.0, 0.005, d))); // lines
        //glFragColor = max(glFragColor, vec4(pow(1.0 - d, 17.0))); // glow
        //glFragColor = mix(max(glFragColor, vec4(1.0 - smoothstep(0.0, 0.01, d))), max(glFragColor, vec4(pow(1.0 - d, 17.0))), 0.5 + 0.5 * sin(time)); // blinking
    }
}
