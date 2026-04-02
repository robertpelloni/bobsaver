#version 420

// original https://www.shadertoy.com/view/XlsBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float curve(in vec2 p, in float fy, in float minLimit, in float maxLimit) {
    
    if(p.x < minLimit)
        return 0.;
    
    if(p.x > maxLimit)
        return 0.;
    
    float d = 1. - 150.*abs(p.y - fy);
    
    d = clamp(d, 0., 1.);
    
    return d;
}
float gR = 1.61;

float nSin(in float t) {
    
    return 0.5 + 0.5 * sin(t);   
}

float glowingPoint(in vec2 uv, in vec2 pos, in float size) {
    
    float dist = distance(uv, pos);
    
    float d = (1. - (1./(1.*size)) *dist);
    
    
    
    d = clamp(d, 0., 1.);
    
    d = sqrt(sqrt(d));
    
    //d = (d + d*d) / 2.;
    
    return d;
}

float speed = 0.15;
float trend = +1.5;
float stockFunction(in float x) {
    
    float t = x + time * speed;
    
    float f0 = 6.28;
    float f1 = 3.68;
    float f2 = 13.28;
    float f3 = 32.43;
    float f4 = 123.;
    float f5 = 331.;   
    float f6 = 730.;    
    float f7 = 1232.;
    
    
    float s0 = sin(f0 * t) * 0.4;
    float s1 = sin(f1 * t) * 0.2;
    float s2 = sin(f2 * t) * 0.1;
    float s3 = cos(f3 * t) * 0.15;
    float s4 = sin(f4 * t) * 0.1;
    float s5 = sin(f5 * t) * 0.05;
    float s6 = sin(f6 * t) * 0.035;
    float s7 = sin(f7 * t) * 0.02;
    
    float wave = s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7;
    
    float mod = mod(s1 * s2, 0.1 ) * (5.*sqrt(nSin(f0*t)));
    
    float final = wave + mod;
    
    float fy = -trend / 1.5 + (trend)*x  - 0.5*final;
    
    return fy / 5.;
}

//derivative
float d_stockFunction(in float x, in float delta) {
    
    float x0 = x;
    float x1 = x - delta;
    
    float y0 = stockFunction(x0);
    float y1 = stockFunction(x1);
    
    return (y1 - y0) / delta;
}

float longTrend(in float x) {
    
    float trend0 = d_stockFunction(x, 0.025);
    float trend1 = d_stockFunction(x, 0.05);
    float trend2 = d_stockFunction(x, 0.1);
    
    float finalTrend = trend0 + trend1 + trend2;
    
    return finalTrend / 3.;
}

float shortTrend(in float x) {
    
    float trend0 = d_stockFunction(x, 0.0040);
    float trend1 = d_stockFunction(x, 0.0050);
    float trend2 = d_stockFunction(x, 0.0060);
    
    float finalTrend = trend0 + trend1 + trend2;
    
    return finalTrend / 3.;
}

vec3 trendColor(in float trend) {
    
    vec3 red   = vec3(1., 0., 0.);   
    vec3 green = vec3(0., 1., 0.);
    
    trend *= 100.;
    
    trend = atan(trend) / (1.57079632679);
    trend += 1.;   
    trend /= 2.;
        
    return mix(green, red, trend);
}

float grid(in vec2 uv, float tileSize, float borderSize) {

    float xMod = mod(uv.x, tileSize);
    float yMod = mod(uv.y, tileSize); 
    
    float treshold = borderSize;
    
    if(xMod < treshold || yMod < treshold)
        return 1.;
    
    return 0.;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.x;   
    
    uv.y = uv.y - .33;
    
    vec3 points;
    
    float size = 0.025;
    
    float start = 0.9;
    float end = 0.85;

    float delta = end - start;
    
    //x20
    for(float offset = 0.; offset < 1. ; offset += 0.05) {
    
        float pos = start + delta * offset; 
        
        vec3 pColor = glowingPoint(uv, vec2(pos, stockFunction(pos)),  size) * trendColor(longTrend(pos));
        
        points = max(points, pColor);       
        size *= 0.92;
    }
    
    
    vec3 line = trendColor(shortTrend(uv.x)) * curve(uv, stockFunction(uv.x), 0., start);
    
    vec2 gridOffset = vec2(time * speed, + time * speed * trend/5.);
    vec3 background = vec3(1.,1.,1.) * grid(uv + gridOffset, 0.2, 0.002);
    
    vec3 color = max(line, points) + background * 0.05;
    
    glFragColor = vec4(color,1.0);
}
