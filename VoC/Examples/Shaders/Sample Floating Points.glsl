#version 420

// original https://www.shadertoy.com/view/wlGSzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DistanceToLine(vec3 LineStart, vec3 LineEnd, vec3 Point)
{
    vec3 lineStartToEnd = LineEnd - LineStart;
    return length(cross(Point - LineStart, lineStartToEnd))/length(lineStartToEnd);
}

void main(void)
{
    // UV goes from -0.5 to 0.5 vertically
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    
    float sineOfTime = sin(time);
    float cosineOfTime = cos(time);
    
    vec3 rayOrigin = vec3(0, 0, -1.0 + sineOfTime * 0.25);
    vec3 uvPoint = vec3(uv, 0);
    
    float filledIn = 0.0;

    for (float x = -1.0; x <= 1.0; x += 0.5)
    {
        for (float y = -1.0; y <= 1.0; y += 0.5)
        {
            for (float z = -1.0; z <= 1.0; z += 0.5)
            {
                vec3 point = vec3(x, y, z + 5.0);
                point.x += sineOfTime * 0.75;
                point.z -= cosineOfTime * 0.75;
                point.y -= (cosineOfTime + sineOfTime) * 0.75;
                point.x += (fract(x * 47350.6 - y * 7076.5 + z * 3205.25 + sin(time * x * y * z) * 0.5) - 0.5) * 1.75;
                point.y += (fract(-x * 155.2 + y * 2710.66 + z * 71820.43 - cos(time * x * y * z) * 0.5) - 0.5) * 1.75;
                point.z += (fract(x * 21255.52 + y * 510.16 - z * 6620.73 - cos(time * x * y * z) * 0.5) - 0.5) * 1.75;
                float distanceToLine = DistanceToLine(rayOrigin, uvPoint, point);
                if (distanceToLine < fract(x * 6250.55 + y * 325.35 + z * 6207.58) * 0.1 + 0.05)
                {
                    filledIn += 0.25 * fract(x * 1250.25 + y * 25.5 + z * 120.01);
                }
                filledIn += max(0.01, sineOfTime * 0.5 + 1.0 - distanceToLine) * 0.01;
            }
        }
    }
    
    vec3 color = filledIn * vec3(uv.x + 0.5, uv.y + 0.5, uv.x * uv.y + 0.5) * (max(0.5, (cos(time * 0.35 + 0.25) + 0.5)) * 10.0);
    
    glFragColor = vec4(color, 1);
}
