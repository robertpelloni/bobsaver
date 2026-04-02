#version 420

// original https://www.shadertoy.com/view/flVXRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    
	vec4 c=gl_FragColor;
	vec2 p = gl_FragCoord.xy;

    // set position
    vec2 v = resolution.xy;
    p = (p-v*.5)*.5 / v.y;
    
    // breathing effect
    p += p * sin(dot(p, p)*20.-time) * .04;
    
    // color
    c *= 0.;
    for (float i = .5 ; i < 8. ; i++)
        
        // fractal formula and rotation
        p = abs(2.*fract(p-.5)-1.) * mat2(cos(.01*(time+mouse.x*resolution.xy.x*.1)*i*i + .85*vec4(1,8,3,1))),
        
        // coloration
        c += exp(-abs(p.y)*5.) * (cos(vec4(2,3,1,0)*i)*.5+.5);
        
    
    
    // palette
    c.gb *= .5;
    
	glFragColor=c;
}
