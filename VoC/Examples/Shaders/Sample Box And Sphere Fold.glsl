#version 420

// original https://www.shadertoy.com/view/XlcXRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    
    return mat2(c, s, -s, c);
}

void main(void) {
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    
    //p += 2.0*(-resolution.xy + 2.0*mouse*resolution.xy.xy)/resolution.y;
    
    vec2 c = p;
    
    vec3 col = vec3(1000.0);
    for(int i = 0; i < 4; i++) {
        p = 2.0*clamp(p, -1.0, 1.0) - p;
        p *= clamp(dot(p, p), 1.0, 1.0/0.89);
        p = 2.5*p;
        
        p *= rotate(0.5 + 0.1*time);
        
        
        col = min(col, vec3(abs(cos(p + time)), length(exp(p))));
    }
    
    glFragColor = vec4(col, 1);
}
