#version 420

// original https://www.shadertoy.com/view/3sfSDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

void main(void) {
    vec2 R = resolution.xy;
    vec2 p = ( gl_FragCoord.xy - .5*R) / R.y;
    
    float t = PI/4.*(floor(time) + cubicInOut(fract(time)));
    
    float l = length(p);
    
    p *= mat2(cos(t), sin(t), -sin(t), cos(t));
    p *= 1.5 + 0.5*sin(t);

    
    vec3 c;
    for(int i=0;i<=2;i++) {
        t+=0.1;               
        vec2 a = p*5.0*(sin(t)+2.0);
        
        a = abs(fract(a)-0.5);
        
        float dist = length(p)*2.0;
      
        c[i]= smoothstep(0.0,0.25,abs(.25 - length(a)*dist));
    }
    glFragColor=vec4(c/l,1.0);
}
