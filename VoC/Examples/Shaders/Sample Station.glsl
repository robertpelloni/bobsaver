#version 420

// original https://neort.io/art/bq85h1c3p9f6qoqnm3k0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define line 28

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy-0.5;
    uv.x *= resolution.x/resolution.y;
    uv *= 3.0; 

    float vignet = length(uv);
    uv /=1.0 - vignet * 2.5;
    
    //http://glslsandbox.com/e#63048.1
    float t = (1024.0 + time) * 0.03;
    vec2 a = vec2(0.0);
    vec2 b = vec2(0.0);
    float p = 0.0;
    float ap = 0.0;
    float bp = 0.0;
    
    for (int i = 16; i <= line + 16; i++)
    {
        a = vec2(sin(t * fract(cos(float(i)) * 234.1342)), cos(t * 0.04 * float(i)));
        b = vec2(sin(t * fract(sin(float(i)) * 397.6848)), cos(t * 0.03 * float(i)));
        ap += 0.005/distance(uv,a);
        bp += 0.005/distance(uv,b);
        vec2 ua = uv-a;
        vec2 ba = b-a;
        float k = clamp(dot(ua,ba)/dot(ba,ba),-3.0,3.0);
        float o = clamp(dot(ua,ba)/dot(ua,ba),-3.0,3.0);
        p += 0.001/length(ua-ba*k);
    }
    
    vec3 col = pow(vec3(ap,0.0,bp)+p,vec3(3.0));
    col = pow(col,vec3(1.0,0.7,0.8));
    col *= 1.5;
    
    float l = 0.015 /length(uv);
    col += vec3(l);
    
    vec2 viguv = gl_FragCoord.xy / resolution.xy;
    viguv *=  1.0 - viguv.yx;
    float vig = viguv.x*viguv.y * 20.0;
    vig = pow(vig, 3.0);
    col *= vig;
    
    glFragColor = vec4(col, 1.0);
}
