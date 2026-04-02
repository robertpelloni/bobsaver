#version 420

// original https://www.shadertoy.com/view/ss3XzH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 o=gl_FragCoord.xy;
    int f = frames;
    o.y-=resolution.y*0.5;o.x-=resolution.x*0.5;
    int a = abs(int(mod(o.x,float(f))));
    int b = abs(int(mod(o.x*0.5+o.y*sqrt(2.0)/2.0,float(f))));
    int c = abs(int(mod(o.x*0.5-o.y*sqrt(5.0)/2.0,float(f))));
    glFragColor = vec4(a&b&c /*&abs(int(mod(sqrt(o.x*o.x+o.y*o.y),float(f))))*/ );
}
