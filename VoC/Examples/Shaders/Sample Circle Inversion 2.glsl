#version 420

// original https://www.shadertoy.com/view/tssfzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 gradient(in float r) {        
    vec3 rainbow = 0.5 + 0.5 * cos((0.2 * r + vec3(0.2, 0.45, 0.8)*6.));   
    return rainbow;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    uv *= 2.;
    
    
    float r = length(uv);
    uv /= (r * r);
    
    float t = 0.05 * time;
    uv.x -= 15. * sin(t);
    uv.y -= 10. * cos(t);
    
    float theta = 1.2 * t;
    uv = vec2(    
        uv.x * cos(theta) - uv.y * sin(theta),
        uv.y * cos(theta) + uv.x * sin(theta)
    );
    
        
    
    float thickness = 0.02 / r;
    
    vec3 col;
    
    
    uv.y +=  2. * (0.5 + 0.5 * cos(10. * (t - 0.2 * floor(uv.x)))) * mod(floor(uv.x), 2.);
  
        
    col += 1. - smoothstep(
        0., thickness,
        length(fract(uv) - 0.5) - 0.5);
    col *= gradient(floor(uv.x) + 3.2 * floor(uv.y));
    
    glFragColor = vec4(vec3(col), 1.0);
}
