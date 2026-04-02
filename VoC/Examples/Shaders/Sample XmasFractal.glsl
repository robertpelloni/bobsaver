#version 420

// original https://www.shadertoy.com/view/Xdj3Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    float t = .01 * time + .3;
    mat2 r = mat2(cos(t),sin(t),-sin(t),cos(t));
    vec4 p = abs(4.-8.*gl_FragCoord.xyxz / resolution.x), c=p*.0;
    p.yx *= r;
    for (float d=.2;d<2.;d+=.2) {
        p -= .5*d;
        for (int i=0;i<60;i++) p.xy=r*(p.xy+sign(p.yx)*vec2(-.2,.6));
        c += .03*p;
    }
    
    glFragColor = c;
}
