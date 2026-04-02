#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    float t=.001;
    vec3 v = vec3(0.);
    for (float s=.1; s<2.; s+=.01) {
        vec3 p=s*(gl_FragCoord.xyz-vec3(resolution*.5,.0))*t+vec3(0.,0.,fract(s+floor(time*100.)*.01));
        for (int i=0; i<8; i++) p=abs(p)/dot(p,p)-vec3(mouse,.8);
        v+=p*p*t*(2.-s);
    }
    glFragColor=vec4(v*5.0, 1.0);
}
