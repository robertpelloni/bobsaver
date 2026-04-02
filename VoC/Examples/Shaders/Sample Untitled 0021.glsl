#version 420

// forked from wgld.org's "Draw the shape in GLSL" http://wgld.org/d/glsl/g004.html

uniform float time;
uniform vec2  mouse;
uniform vec2  resolution;

out vec4 glFragColor;

vec4 main2(vec2 p){
    vec2 m = vec2(mouse.x * 2.0 - 1.0, -mouse.y * 2.0 + 1.0);
    
    // ring
//    float t = 0.02 / abs(0.5 - length(p));
    
    // time scale ring
//    float t = 0.02 / abs(sin(time) - length(p));
    
    // gradiation
//    vec2 v = vec2(0.0, 1.0);
//    float t = dot(p, v);
    
    // cone
//    vec2 v = vec2(0.0, 1.0);
//    float t = dot(p, v) / (length(p) * length(v));
    
    // zoom line
//    float t = atan(p.y, p.x) + time;
//    t = sin(t * 10.0);
    
    // flower
//    float u = sin((atan(p.y, p.x) + time * 0.5) * 6.0);
//    float t = 0.01 / abs(u - length(p));
    
    // wave ring
//    float u = sin((atan(p.y, p.x) + time * 0.5) * 20.0) * 0.01;
//    float t = 0.01 / abs(0.5 + u - length(p));
    
    // flower
//    float u = abs(sin((atan(p.y, p.x) + time * 0.5) * 20.0)) * 0.5;
//    float t = 0.01 / abs(0.25 + u - length(p));
    
    // fan
//    float u = abs(sin((atan(p.y, p.x) - length(p) + time) * 10.0) * 0.5) + 0.2;
//    float t = 0.01 / abs(u - length(p));
    
    // custom
    float u = abs(sin((atan(p.y, p.x) - length(p) + time) * 10.0) * 0.1) + 0.1;
    float r = 0.03 / abs(u - length(p) * 0.3);
    float g = 0.04 / abs(u - length(p) * 0.5);
    float b = 0.05 / abs(u - length(p) * 0.7);
    //glFragColor = vec4(r, g, b, 1.0);
    return min(vec4(1), vec4(r, g, b, 1.0));
    //return max(0.0, max(1.0, length(vec3(r, g, b))));
    //return abs(r * g * b);
}

float map(vec3 p)
{
    return 1.2-dot(abs(p), vec3(0,1,0)) + -0.5 * length(main2(p.xz).xyz) * sin(time * 2.0) + (sin(p.z * 5.0 + time * 5.0) + sin(p.x * 5.0 + time * 5.0)) * 0.1;
}

void main(void)
{
    vec2 p = -1.0 + 2.0 * (gl_FragCoord.xy / resolution);
    if(abs(p.y) > 0.75)
    {
        glFragColor = vec4(0);
        return;
    }
    
    p.y = -p.y;
    vec3 d = normalize(vec3(p, 1.0));
    float a = -0.1;
    
    d.y = cos(a) * d.y - sin(a) * d.z;
    d.z = sin(a) * d.y + cos(a) * d.z;

    vec3 e = vec3(0,0.0,-2.0);
    float t = 0.0;
    for(int i = 0 ; i < 60; i++)
    {
        float k = map(e + d * t);
        if(k < 0.005) break;
        t += k * 0.125;
    }
    glFragColor = vec4(t * .5) * main2((t * d + e).xz) + t * 0.1 * vec4(1,2,3,4) * 0.5 * map( (t * d + e) + 0.1 ) ;    
}
