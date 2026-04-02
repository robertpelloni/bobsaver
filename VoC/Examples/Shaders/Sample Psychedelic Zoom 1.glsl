#version 420

// original https://www.shadertoy.com/view/DsscWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) { //WARNING - variables void ( out vec4 c, vec2 p ) { need changing to glFragColor and gl_FragCoord.xy
    vec2 p = gl_FragCoord.xy;
    vec4 c = vec4(0.0);
    
    vec2 v = resolution.xy;
    float zoom = -5. + abs(sin(time * 0.05)) * 4.;  // oscillates zoom
    p = ((p-v*.5)*.4 / v.y) / zoom; // Apply zoom
    p += p * sin(dot(p, p)*20.-time) * .04;
    c *= 0.;
    for (float i = .5 ; i < 8. ; i++)
        p = abs(2.*fract(p-.5)-1.) * mat2(cos(.01*(time+resolution.xy.x*.1)*i*i + .78*vec4(1,7,3,1))),
        c += exp(-abs(p.y)*5.) * (cos(vec4(1,2,3,0)*i)*.3+.2);  // Reduced values for darker colors
    c -= vec4(0.3, 0.3, 0.3, 0);  // Subtract base color for contrast
    c = clamp(c, 0.0, 1.0); // Ensure colors stay within valid range
    
    glFragColor=c;
}