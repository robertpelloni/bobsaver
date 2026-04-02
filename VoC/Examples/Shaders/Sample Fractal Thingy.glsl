#version 420

// original https://www.shadertoy.com/view/Xd2Bzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    
    glFragColor -= glFragColor;
    vec2 p=gl_FragCoord.xy;
    p /= resolution.x;
    
    for (float i = .5 ; i < 9. ; i++) {
        
        // fractal formula and rotation
        vec2 v = sin(vec2(9.6, 8) + .01*time*i*i);
        p = abs(2.*fract(p-.5)-1.) * mat2(v, -v.y, v.x);
        
        // coloration
        glFragColor += exp(-abs(p.y)*5.) * (cos(vec4(2,3,1,0)*i)*.5+.5);
        
    }
    
    // palette
    glFragColor.gb *= .5;
    
}
