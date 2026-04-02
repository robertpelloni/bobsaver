#version 420

// original https://www.shadertoy.com/view/wltSRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define amplitude .5
#define frequency 2.
#define speed 2.

vec3 DrawAxis(vec2 uv){
    vec3 axis = vec3(0);   
    
    vec2 uvs = fract(uv * 10. * 5.);    
    vec2 absUv = abs(uvs);
    if (absUv.x < .1 || absUv.x > .9) axis = vec3(.1);
    if (absUv.y < .1 || absUv.y > .9) axis = vec3(.1);
    
    vec2 uvm = fract(uv * 5.);
    absUv = abs(uvm);
    if (absUv.x < .01 || absUv.x > .99) axis = vec3(.5);
    if (absUv.y < .01 || absUv.y > .99) axis = vec3(.5);
    
    if (abs(uv.x) < .005) axis = vec3(1.);
    if (abs(uv.y) < .005) axis = vec3(1.);
   
    return axis;
}

float Line(float n, float pw, float a){
    return smoothstep(n - pw/resolution.x, n, a) - smoothstep(n, n  + pw/resolution.x, a);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy/resolution.xy) - .5;
    uv.x *= resolution.x/resolution.y;    
    
    vec3 col = vec3(.8,.95,1.);
    col += DrawAxis(uv);
    col *= .5;
    
    float y = uv.x;  
    
    float sine = sin(y * PI * frequency + time * speed) * amplitude;
    float sinCurve = Line(sine, 5., uv.y);
    
    float cosine = cos(y * PI * frequency + time * speed) * amplitude;
    float cosCurve = Line(cosine, 5., uv.y );
    
    col += vec3(sinCurve * .2, sinCurve * .35, sinCurve * .5);
    col += vec3(cosCurve * .5, cosCurve * .15, cosCurve * .2); 

    
    glFragColor = vec4(col,1.0);
}
