#version 420

// original https://www.shadertoy.com/view/WttyWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float f(float x)
{
    return dot(cos(x * vec3(1.0, 2.0, 4.0) + time), vec3(1.0));
}

vec2 viewportMin = vec2(-7.0, -4.0);
vec2 viewportMax = vec2(7.0, 4.0);

vec3 backgroundColor = vec3(1.0);
vec3 gridColor = vec3(0.95);
vec3 axisColor = vec3(0.5);
vec3 graphColor = vec3(0.0);

float sq(vec2 x)
{
    return dot(x, x);
}

vec2 getClosestPointOnGraph(vec2 p, float x0, float x1)
{
    // Bin search (not Newton–Raphson because requires proper gradient)
    for (int n = 0; n < 4; n++)
    {
        float d0 = sq(p - vec2(x0, f(x0)));
        float d1 = sq(p - vec2(x1, f(x1)));
        float mid = (x0 + x1) * 0.5;
        if (d0 < d1)
            x1 = mid;
        else
            x0 = mid;
    }
    // Get closest point on line for result
    vec2 p0 = vec2(x0, f(x0));
    vec2 p1 = vec2(x1, f(x1));
    vec2 v = normalize(p1 - p0);
    return p0 + v * dot(p - p0, v);
}

bool isClosestToZero(float x, float d)
{
    return abs(x) < abs(x - d) && abs(x) < abs(x + d);
}

void main(void)
{
    vec2 pixelSize = (viewportMax - viewportMin) / resolution.xy;
    vec2 position = (gl_FragCoord.xy - 0.5) * pixelSize + viewportMin;

    // Background
    vec3 color = backgroundColor;

    // Grid
    vec2 gd = 1.0 - abs(0.5 - fract(position)) * 2.0;
    if (isClosestToZero(gd.x, pixelSize.x * 2.0) ||
        isClosestToZero(gd.y, pixelSize.y * 2.0))
        color = gridColor;

    // Axis notches
    if (abs(position.y) < pixelSize.y * 2.5 && isClosestToZero(gd.x, pixelSize.x * 2.0) ||
        abs(position.x) < pixelSize.x * 2.5 && isClosestToZero(gd.y, pixelSize.y * 2.0))
        color = axisColor;

    // Axis
    if (isClosestToZero(position.x, pixelSize.x) || 
        isClosestToZero(position.y, pixelSize.y))
        color = axisColor;

    // Graph
    vec2 p = getClosestPointOnGraph(position, position.x - pixelSize.x, position.x + pixelSize.x);
    float d = length((p - position) / pixelSize);
    color = mix(color, graphColor, max(0.0, 1.0 - d));

    glFragColor = vec4(color, 1.0);
}
