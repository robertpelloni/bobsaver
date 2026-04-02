#version 420

// original https://www.shadertoy.com/view/Ml3XW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time

void main(void)
{
    vec2 p = (gl_FragCoord.xy - .5*resolution.xy);
    p = 2.*p/resolution.y;
    vec3 c = vec3(.1, .1, .1);
    vec3 axis = vec3(1, 1, 1);
    
    //p += .25*vec2(-sin(t), cos(t));
    
    float a = atan(p.y, p.x);
    float r = smoothstep(0.025, 2., length(p));
    for (float i = 1.; i < 10.; ++i) {
        float f = sin((i*log(r) - 6.*t) + a);
        c = c*.85 - i/10.*vec3(.25, .25, .25) + 4.*vec3(r) * vec3(.5*i*cos(t), .5+.5*sin(t) + .5, .5 + .5 * cos(log(r+t))) * vec3(smoothstep(.75, 1., f));
    }
    
    
    //c *= axis * smoothstep(.005, .011, abs(p.y));
    //c *= axis * smoothstep(.005, .011, abs(p.x));
       

    glFragColor = vec4(c, 1);
}
