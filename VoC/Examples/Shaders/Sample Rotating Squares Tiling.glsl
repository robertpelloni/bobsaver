#version 420

// original https://www.shadertoy.com/view/3tfGW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float pi = acos(-1.);
    float zoom = 5.;
    vec2 p = gl_FragCoord.xy / resolution.y * zoom;

    float th = mod(time * pi / 5., pi * 2.);
    float gridsize = (.5 + abs(sin(th * 2.)) * (sqrt(2.) / 2. - .5)) * 2.;

    bool flip = false;

    if(fract(th / pi + .25) > .5)
    {
        p -= .5;
        flip = true;
    }

    p *= gridsize;

    vec2 cp = floor(p / gridsize);

    p = mod(p, gridsize) - gridsize / 2.;

    p *= mod(cp, 2.) * 2. - 1.;

    p *= mat2(cos(th), sin(th), -sin(th), cos(th));

    float w = zoom / resolution.y * 1.5;
    
    float a = smoothstep(-w, +w, max(abs(p.x), abs(p.y)) - .5);

    if(flip)
        a = 1. - a;

    if(flip && a < .5 && (abs(p.x) - abs(p.y)) * sign(fract(th / pi) - .5) > 0.)
        a = .4;

    if(!flip && a < .5 && (mod(cp.x + cp.y, 2.) - .5) > 0.)
        a = .4;

    glFragColor.rgb = pow(vec3(a), vec3(1. / 2.2));
    glFragColor.a = 1.;
}

