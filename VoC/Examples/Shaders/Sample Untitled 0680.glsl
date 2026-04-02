#version 420

// original https://www.shadertoy.com/view/ct23Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    
    // set position
    vec2 v = resolution.xy;
    vec2 p = (gl_FragCoord.xy-v*.5)*.4 / v.y;
    // breathing effect
    p += p * sin(dot(p, p)*20.-time) * .04;
    
    // accumulate color
    vec4 c = vec4(0.);
    for (float i = .4 ; i < 8. ; i++)
        
        // fractal formula and rotation
        p = abs(2.*fract(p-.5)-1.) * mat2(cos(.01*(time)*i*i + .78*vec4(1,7,3,1))),
        
        // coloration
        c += exp(-abs(p.y)*7.) * (cos(vec4(4,8,1,0)*i)*.5+.5);
        
    
    
    // palette
    c.gb *= .6;
    
	glFragColor = c;
}
