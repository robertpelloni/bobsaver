#version 420

// original https://www.shadertoy.com/view/ltVBDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento 

void main(void) { //WARNING - variables void ( out vec4 c, in vec2 f ){ need changing to glFragColor and gl_FragCoord

    vec2 f = gl_FragCoord.xy;    

    f = f / resolution.xy - .5;
    
    vec2 b = ceil(vec2(f.x / max(abs(f.y), .1) + time, f.y * 8.)*2.);
    
    glFragColor = vec4((1.5) * vec3(mod(b.x - b.y, 2.)), 1.) * max(abs(f.y), .1);
   
}

