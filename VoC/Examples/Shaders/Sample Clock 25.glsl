#version 420

// original https://www.shadertoy.com/view/3ltfW2

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Apple Watch Clock - by moranzcw - 2021
// Email: moranzcw@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159265359
#define ScaleWidth 0.04
#define ClockSize 0.7

#define HoursScaleWidth 0.015
#define MinutesScaleWidth 0.004

#define HourHandColor vec3(1.0)
#define HourHandCoreSize 0.025
#define HourHandLength1 0.1
#define HourHandWidth1 0.005
#define HourHandLength2 0.25
#define HourHandWidth2 0.02

#define MinuteHandColor vec3(1.0)
#define MinuteHandCoreSize 0.025
#define MinuteHandLength1 0.1
#define MinuteHandWidth1 0.005
#define MinuteHandLength2 0.5
#define MinuteHandWidth2 0.02

#define SecondHandColor vec3(0.961, 0.633, 0.332)
#define SecondHandCoreSize 0.02
#define SecondHandLength 0.7
#define SecondHandWidth 0.0035

vec3 line(vec2 coord, vec2 p1, vec2 p2, float width, vec3 color)
{
    vec2 v1 = coord - p1;
    vec2 v2 = p2 - p1;
    float j1 = dot(v1, v2);
    
    vec2 v3 = coord - p2;
    vec2 v4 = p1 - p2;
    float j2 = dot(v3, v4);
    
    float len;
    if( j1 > 0.0 && j2 > 0.0)
    {
        vec2 nv2 = normalize(v2);
        len = length(v1 - dot(v1, nv2) * nv2);
    }
    else
    {
        len = min(length(v1),length(v3));
    }
    return color * (1.0 - step(width, len));
}

vec3 clockScale(vec2 coord)
{
    vec3 color;
    
    //
    float l = length(coord);
    float onRing = step(ClockSize-ScaleWidth, l) - step(ClockSize, l);
    
    //
    float angle = atan(coord.y/coord.x);
    float d1 = mod(angle, PI/6.0);
    float d2 = d1 - PI/6.0;
    float onHoursScale = step(-HoursScaleWidth,d1) - step(HoursScaleWidth,d1);
    onHoursScale += step(-HoursScaleWidth,d2) - step(HoursScaleWidth,d2);
    
    // 
    float d3 = mod(angle, PI/30.0);
    float d4 = d3 - PI/30.0;
    float onMinutesScale = step(-MinutesScaleWidth,d3) - step(MinutesScaleWidth,d3);
    onMinutesScale += step(-MinutesScaleWidth,d4) - step(MinutesScaleWidth,d4);
    
    color += vec3(1.0) * onRing * onHoursScale;
    color += vec3(0.6) * onRing * onMinutesScale;
    return color;
}

vec3 hourHand(vec2 coord)
{
    vec3 color;
    color += HourHandColor * (1.0 - step(HourHandCoreSize, length(coord)));
    
    float angle = 2.0 * PI * (date.w / 43200.0);
    vec2 direction = vec2(sin(angle), cos(angle));
    vec2 p1 = vec2(0.0);
    vec2 p2 = direction * HourHandLength1;
    color = max(color, line(coord, p1, p2, HourHandWidth1, HourHandColor));
    p1 = direction * HourHandLength1;
    p2 = p1 + direction * HourHandLength2;
    color = max(color, line(coord, p1, p2, HourHandWidth2, HourHandColor));
    
    return color;
}

vec3 minuteHand(vec2 coord)
{
    vec3 color;
    color += MinuteHandColor * (1.0 - step(MinuteHandCoreSize, length(coord)));
    
    float angle = 2.0 * PI * mod(date.w / 60.0, 60.0) / 60.0;
    vec2 direction = vec2(sin(angle), cos(angle));
    vec2 p1 = vec2(0.0);
    vec2 p2 = direction * MinuteHandLength1;
    color = max(color, line(coord, p1, p2, MinuteHandWidth1, MinuteHandColor));
    p1 = direction * MinuteHandLength1;
    p2 = p1 + direction * MinuteHandLength2;
    color = max(color, line(coord, p1, p2, MinuteHandWidth2, MinuteHandColor));
    
    return color;
}

vec3 secondHand(vec2 coord)
{
    vec3 color;
    color += SecondHandColor * (1.0 - step(SecondHandCoreSize, length(coord)));
    
    float angle = 2.0 * PI * mod(date.w, 60.0) / 60.0;
    vec2 direction = vec2(sin(angle), cos(angle));
    vec2 p1 = direction * SecondHandLength;
    vec2 p2 = -direction * 0.15 * SecondHandLength;
    color = max(color, line(coord, p1, p2, SecondHandWidth, SecondHandColor));
    
    
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 coord = (uv * 2.0 - 1.0) * vec2(resolution.x/resolution.y, 1.0);
    
    vec3 color;
    vec3 temp;
    temp = clockScale(coord);
    color = step(1e-3, temp) * temp + (1.0-step(1e-3, temp)) * color;
    
    temp = hourHand(coord);
    color = step(1e-3, temp) * temp + (1.0-step(1e-3, temp)) * color;
    
    temp = minuteHand(coord);
    color = step(1e-3, temp) * temp + (1.0-step(1e-3, temp)) * color;
    
    temp = secondHand(coord);
    color = step(1e-3, temp) * temp + (1.0-step(1e-3, temp)) * color;

    float d = 1.0 - step(MinuteHandCoreSize*0.5, length(coord));
    color = vec3(0.0) * d + color * (1.0-d);
    glFragColor = vec4(color,1.0);
}
