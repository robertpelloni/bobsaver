#version 420

// original https://www.shadertoy.com/view/wt3cD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) //WARNING - variables void (out vec4 C, in vec2 p) need changing to glFragColor and gl_FragCoord.xy
{
    float i = time, s = sin(i), c = cos(i), n = 0.;
    mat2  R = mat2(c, s, -s, c);
    vec2  t = resolution.xy * .5;
    vec2  p;

    t = floor(p = R * (5. + 3. * s) * (gl_FragCoord.xy - t)/t.x);
    i = mod(t.x + t.y, 2.);
    t = p = 4. * (fract(p) - .5) * R * R - vec2(i * .5, 0);
    
    for(; n < (1. - s) * .5 && dot(t, t) < 4.; n += .02)
    t = vec2(t.x * t.x - t.y * t.y + i * (p.x - s) + s,
                    2. * t.x * t.y + i * (p.y - c) + c);
   
    glFragColor = vec4(i > 0. ? n : 1. - n);
}
