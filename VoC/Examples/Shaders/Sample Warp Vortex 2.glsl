#version 420

// original https://www.shadertoy.com/view/MtsfD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi  3.14159

// from iq
float expStep( float x, float k, float n ){
    return exp( -k*pow(x,n) );
}

mat2 rot(float rads)
{
    return mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
}

void main(void)
{
    vec2 p = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    p = rot(time * 1.25) * p;
    p = vec2(p.x, -p.y) + .15;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    a += 2. * sin(a);
    float coord = fract(a / pi + expStep(r, 1., .5) * 8. + 1.6 * time);
    vec3 col = mix(vec3(.17, 0., .25), vec3(.3, 0., .5), step(.6, coord));
    
    col *= pow(r, .65) * 1.75;
    glFragColor.rgb = col;
}
