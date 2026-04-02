#version 420

// dashxdr was here 20151221
// Motion Induced Blindness
// Focus on the blinking blue dot in the center and notice how the purple dots vanish
// Inspired by https://www.youtube.com/watch?v=Hfrb94mKCJw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D bb;

void main( void ) {
vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 v = surfacePos;

    float r1 = .3;
    float size = .02;
    float d1 = 9999.0;
    for(int i=0;i<3;++i)
    {
        float a = (float(i)+.25)*3.1415927*2.0/3.0;
        float td = length(v - r1*vec2(cos(a), sin(a)));
        d1 = min(td, d1);
    }
    vec3 color = vec3(0.0);
    if(length(v) < size*.5 && fract(time) < .5) color = vec3(0.0, 0.0, 1.0);
    else if(d1<size) color = vec3(1.0, 0.0, 1.0);
    else
    {
        float a = time*2.0;
        float s = sin(a);
        float c = cos(a);
        v = mat2(c, s, -s, c)*v;
        float thick = .05;
        v = v*9.0;
        vec2 n = abs(v);
        vec2 av = fract(v + .25);
        v = fract(v + thick*.5);
        if(min(v.x, v.y) < thick && max(av.x, av.y) < .5 && max(n.x, n.y) < 3.5) color = vec3(0.0, 1.0, 0.0);
    }
    glFragColor = vec4(color, 1.0);
}
