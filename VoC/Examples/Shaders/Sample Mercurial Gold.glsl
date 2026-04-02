#version 420

// original https://www.shadertoy.com/view/3tyBRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = 5.*(( gl_FragCoord.xy-.5* resolution.xy )/resolution.y)-.5 ;
    vec2 i = p;
    float c = 0.0;
    float r = length(p+vec2(sin(time),sin(time*.222+99.))*1.5);
    float d = length(p);
    float rot = d+time+p.x*.15; 
    for (float n = 0.0; n < 4.0; n++) {
        p *= mat2(cos(rot-sin(time/4.)), sin(rot), -sin(cos(rot)-time), cos(rot))*-0.15;
        float t = r-time/(n+1.5);
        i -= p + vec2(cos(t - i.x-r) + sin(t + i.y),sin(t - i.y) + cos(t + i.x)+r);
        c += 1.0/length(vec2((sin(i.x+t)/.15), (cos(i.y+t)/.15)));
    }
    c /= 4.0;
    glFragColor = vec4(vec3(c)*vec3(4.3, 3.4, 0.1)-0.35, .1);
}
