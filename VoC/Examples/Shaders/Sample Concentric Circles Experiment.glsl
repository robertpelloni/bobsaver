#version 420

// original https://www.shadertoy.com/view/wdyfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 coord, vec2 center, float radius) {
    float d = length((coord - center) / resolution.y);
 
    return smoothstep(radius,radius - 1.5/resolution.y, d) ;
}

void main(void)
{ 
    float col = .0;
    
    for (float i = 0.; i<15.; i++) {
        vec2 center = (vec2(.5,.5)* resolution.xy);
        center.x += sin(.5*time+i)*resolution.x*.02;
        center.y += cos(.5*time+i)*resolution.x*.02;

        // how to smooth inner circle edges too?
        col += circle(gl_FragCoord.xy, center, 0.1+0.08*i+0.03*sin(time+cos(i)));
    }
    
    col = mod(col, 2.);
    if (col > 1.) col = 2. - col;
    
    // add rays from the center as well
    
    glFragColor = vec4(vec3(col),1.0);
}
