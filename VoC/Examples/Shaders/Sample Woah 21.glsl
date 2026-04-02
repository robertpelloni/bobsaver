#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hex(vec2 p) 
{
    p.x *= 0.57735*2.0;
    p.y += mod(floor(p.x), 2.0)*0.5;
    p = abs((fract(p) - 0.5));
    float par = 0.5;
    return abs(max(p.x*1.5 + p.y + par, p.y*2.0 + par) - 1.0);
}

float Koef(vec2 offset) 
{
    vec2 p = 30. * offset / resolution.x;
    float s = sin(dot(p, p) / -128. + time * 2.);
    s = pow(abs(s), 0.5) * sign(s);
    float  r = .1 + .25 * s;
    return smoothstep(r - 0.1, r + 0.1, hex(p + p * r + 0.5));
}

void main( void ) {

    vec2 pos = gl_FragCoord.xy - resolution / 2.;
    //vec2 mouseKoef = (mouse -.5);
    glFragColor = vec4(Koef(pos - pos / 128.), Koef(pos), Koef(pos + pos / 128.), 1.0);
}
