#version 420

// original https://www.shadertoy.com/view/DdSGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time * 0.5

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const float degreeToRad = 0.0174533;

const vec3 blackColor = vec3(0.0);
const vec3 darkGreyColor = vec3(0.12);
const vec3 brightGreyColor = vec3(0.88);
const vec3 white = vec3(1.0);

float rand(float n)
{
     return fract(abs(cos(n*72.42))*173.42);
}

vec2 rotate(vec2 p, float angleDegree)
{
    float angleRad = angleDegree * 0.0174533;
    return p * mat2(cos(angleRad), sin(angleRad),
                   -sin(angleRad), cos(angleRad));
}

vec3 square(vec2 uv, vec2 pos, float size, vec3 color)
{
    vec3 retCol = vec3(0.0);
    vec2 dist = abs(uv-pos);
    if (dist.x < size && dist.y < size )
    {
        retCol = vec3(color);
    }
    return retCol;
}

vec3 rect(vec2 uv, vec2 pos, vec2 size, vec3 color)
{
    vec3 retCol = vec3(0.0);
    vec2 dist = abs(uv-pos);
    if (dist.x < size.x && dist.y < size.y)
    {
        retCol = vec3(color);
    }
    return retCol;
}

vec3 circle(vec2 uv, vec2 pos, float size, vec3 color)
{
    vec3 retCol = vec3(0.0);
    if (distance(uv, pos) < size)
    {
        retCol = vec3(color);
    }
    return retCol;
}

vec3 triangle(vec2 uv, float size, vec3 color)
{
    float a = atan(uv.x, uv.y) + PI;    
    float r = TWO_PI / float(3);
    float d = cos(floor(.5 + a / r) * r - a) * length(uv * 2.);

    return vec3(1.0 - smoothstep(size * 0.98, size, d)) * color;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    float xOffset = 0.125;
    uv -= vec2(xOffset, 0.0);
    uv *= vec2(3.0) * vec2(resolution.x / resolution.y, 1.0);
    float scaledXOffset = xOffset * 3.0 * resolution.x / resolution.y;
    
    vec2 uvf = fract(uv);
    vec2 uvi = floor(uv);
    vec2 pos = uvi + vec2(0.5);

    vec3 col = vec3(0.0);
    // Rect - Column 0, Row 2 (0,0 is lower left corner)
    if (int(uvi.x) == 0 && int(uvi.y) == 2)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        float angle = 45.0;
        int stepsCount = 34;
        vec3 stepColor0 = vec3(0.15, 0.15, 1.65) / float(stepsCount);
        vec3 stepColor1 = vec3(0.125, 1.426, 0.78) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec2 size = vec2(0.37 - float(i) * (stepSize - (rand(pos.x*pos.y) * 0.02)));
            size *= vec2(0.5 + 0.65 * abs(sin(float(i)* 0.05 + time * 0.1)));
            vec3 finalColor = mix(stepColor0, stepColor1, float(i+1)/float(stepsCount));
            col += rect(rotate(uvi+uvf, angle), rotate(pos, angle), size, finalColor);
            angle += cos(time + (1.43 * float(i) * 4.1/ float(stepsCount))) * 19.0;
        }
    }
    // Rect - Column 0, Row 1
    if (int(uvi.x) == 0 && int(uvi.y) == 1)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        float angle = 0.0;
        int stepsCount = 40;
        vec3 stepColor0 = vec3(0.3, 0.3, 1.1) / float(stepsCount);
        vec3 stepColor1 = vec3(0.281, 1.812, 1.7523) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec2 size = vec2(0.4 - float(i) * (stepSize - (rand(pos.x*pos.y) * 0.02))) * vec2(0.618, 0.83);
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += rect(rotate(uvi+uvf, angle), rotate(pos, angle), size, finalColor);
            angle += sin(time + (8.2 * float(i)/ float(stepsCount))) * 12.0;
        }
    }
    // Rect - Column 0, Row 0
    if (int(uvi.x) == 0 && int(uvi.y) == 0)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        float angle = 0.0;
        int stepsCount = 55;
        vec3 stepColor0 = vec3(0.75, 0.01, 1.4) / float(stepsCount);
        vec3 stepColor1 = vec3(0.641, 1.412, 1.3523) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec2 size = vec2(0.4 - float(i) * (stepSize - (rand(pos.x*pos.y) * 0.02))) * vec2(0.658, 1.33);
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += rect(rotate(uvi+uvf, angle), rotate(pos, angle), size, finalColor);
            angle += cos(time + (8.0 * float(stepsCount-i)/ float(stepsCount))) * 6.0;
        }
    }
    // Circle - Column 1, Row 2
    if (int(uvi.x) == 1 && int(uvi.y) == 2)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        int stepsCount = 20;
        vec3 stepColor0 = vec3(0.121, 0.412, 1.153) / float(stepsCount);
        vec3 stepColor1 = vec3(0.121, 1.412, 0.753) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            float OneMinusI = float(stepsCount - i);
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += circle(uvi + uvf, pos, OneMinusI * (stepSize * 0.37), finalColor);
            pos += sin(time) * vec2(cos(float(i) + time), sin(float(i) + time)) * 0.03;
        }
    }
    // Circle - Column 1, Row 1
    if (int(uvi.x) == 1 && int(uvi.y) == 1)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        int stepsCount = 60;
        vec3 stepColor0 = vec3(0.25, 0.25, 2.163) / float(stepsCount);
        vec3 stepColor1 = vec3(1.721, 0.112, 1.153) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            float OneMinusI = float(stepsCount - i);
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += circle(uvi + uvf, pos, OneMinusI * (stepSize * 0.43), finalColor);
            pos += vec2(sin(0.7*time + (1.43 * float(i) * 4.1/ float(stepsCount))), -cos(1.2*time + (1.13 * float(i) * 3.1/ float(stepsCount)))) * 0.01;
        }
    }
    // Circle - Column 1, Row 0
    if (int(uvi.x) == 1 && int(uvi.y) == 0)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        int stepsCount = 70;
        vec3 stepColor0 = vec3(1.4, 0.12, 0.73) / float(stepsCount);
        vec3 stepColor1 = vec3(0.5, 1.5, 0.73) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            float OneMinusI = float(stepsCount - i);
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += circle(uvi + uvf, pos, OneMinusI * (stepSize * 0.3), finalColor);
            pos += 5.0*sin(time * 0.1) * vec2(2.0*cos(float(i) + time * 0.8), 2.0*sin(float(i) + time * 1.2)) * 0.01;
        }
    }
    // Triangle - Column 2, Row 2
    if(int(uvi.x) == 2 && int(uvi.y) == 2)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        float angle = time * 21.0;
        int stepsCount = 30;
        vec3 stepColor0 = vec3(0.08, 0.912, 1.3) / float(stepsCount);
        vec3 stepColor1 = vec3(0.903, 0.612, 0.152) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += triangle(rotate(uvf - vec2(0.5), angle), 0.4 * (abs(sin((float(i) * stepSize * 3.0) + time * 0.75))), finalColor);
            angle += sin(time * 0.01) * 20.0;
        }
    }
    // Triangle - Column 2, Row 1
    if(int(uvi.x) == 2 && int(uvi.y) == 1)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        float angle = -time * 14.0;
        int stepsCount = 70;
        vec3 stepColor0 = vec3(1.712, 1.402, 0.132) / float(stepsCount);
        vec3 stepColor1 = vec3(0.712, 0.302, 0.732) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += triangle(rotate(uvf - vec2(0.5), angle), 0.5 * (abs(sin((float(stepsCount-i) * stepSize * 4.0)))), finalColor);
            angle += cos(0.2*time + (4.2 * float(i)/ float(stepsCount))) * 7.0;
        }
    }
    // Triangle - Column 2, Row 0
    if(int(uvi.x) == 2 && int(uvi.y) == 0)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        float angle = time * 17.0;
        int stepsCount = 50;
        vec3 stepColor0 = vec3(0.421,0.513,0.662) / float(stepsCount);
        vec3 stepColor1 = vec3(1.521, 0.112, 0.143) / float(stepsCount);
        float stepSize = 1.0 / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += triangle(rotate(uvf - vec2(0.5), angle), 0.45 * (abs(sin((float(i) * stepSize * 3.0) + time * 0.35))), finalColor);
            angle += sin(0.4*time + (4.4 * float(i) / float(stepsCount))) + sin(1.4*time + (10.0 * float(stepsCount - i) / float(stepsCount))) * 4.0;
        }
    }
    // Oval - Column 3, Row 2
    if (int(uvi.x) == 3 && int(uvi.y) == 2)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        vec2 scale = vec2(2.5, 1.2);
        vec2 scaledUV = (uvi + uvf) * scale;
        vec2 scaledPos = pos * scale;
        float angle = -time * 10.0;
        int stepsCount = 40;
        float stepSize = 1.0 / float(stepsCount);
        vec3 stepColor0 = vec3(1.912, 1.412, -0.253) / float(stepsCount);
        vec3 stepColor1 = vec3(0.502, 0.151, 0.346) / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += circle(rotate(uvi + uvf, angle) * scale, rotate(pos, angle) * scale, 0.5 - float(i) * (stepSize * 0.4), finalColor);
            angle -= 11.0;
        }
    }
    // Oval - Column 3, Row 1
    if (int(uvi.x) == 3 && int(uvi.y) == 1)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        vec2 scale = vec2(2.1, 1.1) * 0.75;
        vec2 scaledUV = (uvi + uvf) * scale;
        vec2 scaledPos = pos * scale;
        float angle = time * 10.0;
        int stepsCount = 80;
        float stepSize = 1.5 / float(stepsCount);
        vec3 stepColor0 = vec3(1.912, 0.512, -0.253) / float(stepsCount);
        vec3 stepColor1 = vec3(1.912, 1.402, 0.132) / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += circle(rotate(uvi + uvf, angle) * scale, rotate(pos, angle) * scale, 0.5 - float(i) * (stepSize * 0.4), finalColor);
            angle += sin(0.3*time + (6.1 * float(i)/ float(stepsCount))) * 13.0;
        }
    }
    // Oval - Column 3, Row 0
    if (int(uvi.x) == 3 && int(uvi.y) == 0)
    {
        col += square(uvi + uvf, pos, 0.5, darkGreyColor);
        vec2 scale = vec2(1.7, 1.3);
        vec2 scaledUV = (uvi + uvf) * scale;
        vec2 scaledPos = pos * scale;
        float angle = time * 10.0;
        int stepsCount = 60;
        float stepSize = 1.0 / float(stepsCount);
        vec3 stepColor0 = vec3(2.5, 0.03, 0.03) / float(stepsCount);
        vec3 stepColor1 = vec3(0.0, 1.53, 0.52) / float(stepsCount);
        for(int i = 0; i < stepsCount; ++i)
        {
            vec3 finalColor = mix(stepColor0, stepColor1, float(i)/float(stepsCount));
            col += circle(rotate(uvi + uvf, angle) * scale, rotate(pos, angle) * scale, 0.5 - float(i) * (stepSize * 0.55), finalColor);
            angle += abs(cos(0.2*time + (4.0 * float(i) / float(stepsCount)))) * 12.0;
        }
    }

    // Oscilate contrast
    vec3 finalCol = mix(col, pow(col, vec3(1.8)), abs(sin(time*0.2)));
    glFragColor = vec4(finalCol,1.0);
}
