#version 420

// original https://www.shadertoy.com/view/4lyXz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define LINE_COUNT 200.

float getLineThickness(float thickness) {
    // thickness optimized for resolution
    return thickness * 400. / max(resolution.x, resolution.y); 
}

//------- CIRCLE

float circle(vec2 origin, vec2 pos, float radius, float thickness)
{
    float n = 100.0 / getLineThickness(thickness);
    return clamp(((1.0-abs(length(origin + pos)-radius))-(1.0 - 1.0/n)) * n, 0.0, 1.0);
}

float circle(vec2 origin, vec2 pos, float radius)
{
    return circle(origin, pos, radius, 1.0);
}

float circleFill(vec2 origin, vec2 pos, float radius)
{
    return clamp(((1.0-(length(origin+pos)-radius))-0.99)*100.0, 0.0, 1.0);   
}

float circleGlow(vec2 origin, vec2 pos, float radius, float len, float str)
{
    float inCircle = ((1.0-(length(origin + pos)-(radius + len)))-0.99) * str;
    return clamp(inCircle, 0.0, 1.0);   
}

float circleLineGlow(vec2 origin, vec2 pos, float radius, float len, float str)
{
    float inCircle = ((1.0-abs(length(origin + pos)-(radius)) + len)-0.99) * str;
    return clamp(inCircle, 0.0, 1.0);   
}

// ------ LINE 

float line(in vec2 p, in vec2 a, in vec2 b, float thickness)
{
    vec2 pa = -p - a;
    vec2 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    float d = length( pa - ba*h );
    //return clamp(((1.0 - d)-0.99)* 100.0 , 0.0, 1.0);
    //float n = 100.0 / thickness;
    float n = 100.0 / getLineThickness(thickness);
    return clamp(((1.0 - d) - (1.0 - 1.0/n)) * n , 0.0, 1.0);
}

float line( in vec2 p, in vec2 a, in vec2 b )
{
    return line(p, a, b, 1.0);
}

float lineGlow(in vec2 p, in vec2 a, in vec2 b, float str )
{
    vec2 pa = -p - a;
    vec2 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    float d = length( pa - ba*h );
    float n = 10.0;
    return 0.1 * str * clamp(((1.0 - d) - (1.0 - 1.0/n)) * n , 0.0, 1.0);
}

// ------- GEOM

vec2 pointOnACircle(vec2 pos, float r, float a) {
     return vec2(pos.x + r * sin(a),  pos.y + r * cos(a));
}

// ------ GRAPH

float multCircle(vec2 origin, vec2 pos, float radius, float multiplier, 
           float cglow, float cglows, float lglow) {
    float c = .0;
    
    c += circle(origin, pos, radius, 1.0);
    c += circleLineGlow(origin, pos, radius, cglow, cglows);
    
    for (float i = 0.0; i <= LINE_COUNT; i++) {
        float angle1 = i * (2.*PI/LINE_COUNT);
        float angle2 = multiplier * i * (2.*PI/LINE_COUNT);
        
        vec2 pos1 = pointOnACircle(pos, radius, angle1);
        vec2 pos2 = pointOnACircle(pos, radius, angle2);
        
        c += line(origin, pos1, pos2, 0.8) * 0.5;
        c += lineGlow(origin, pos1, pos2, lglow) * 0.5;
    }
    
    return c;
}

/// =============== MAIN ===================

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    // origin
    vec2 p = -1.0 + 2.0 * uv;
    p.x *= resolution.x / resolution.y;
    
    float t = time * 0.5;
    
    #define c(t, s) 0.5 + 0.25 * sin(t+s)
    
    vec3 colour1 = vec3(c(t,2.96), c(t,54.88), c(t,48.11));
    vec3 colour2 = vec3(c(t,12.51), c(t,2.58), c(t,71.99));
    
    vec3 c = vec3(0);
    
    bool clicked = false; //mouse*resolution.xy.z > 0. || mouse*resolution.xy.w > 0.;
    
    #define C_RAD 0.9
    #define C_POS vec2(0)
    // 8.69 10.091 11.0 12.11 13.5 15.285 17.666 19.182
    #define START_FRAME 102.5
    
    float M = START_FRAME + time * (clicked ? 0.1 : 0.5);
    
    float inCircle = circleFill(p, C_POS, C_RAD);
    if (inCircle > .0) {
           c += multCircle(p, C_POS, C_RAD, M, 0.1, 0.5, 0.4);
        c *= colour1;
    } else {
        c += multCircle(p, C_POS, 2.0, START_FRAME + M * 0.05, 0.1, 1.0, 0.9);
        c *= colour2;
    }
    
    c = clamp(c, 0.0, 1.0);
    glFragColor = vec4(c, 1.0);
}
