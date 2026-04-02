#version 420

// original https://www.shadertoy.com/view/7lGGzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float t = (time + 50.4)/ 14.;
    float p = 0.4;
    float c = 0.7;
    float radius = 0.15;

    // inside out
    vec2 xy = gl_FragCoord.xy/min(resolution.xy.x, resolution.xy.y) - 0.5;
    xy = 1. * (xy - 0.3 * vec2(cos(t*5.), sin(t*5.)));
    vec2 uv = vec2(sqrt(xy.x * xy.x + xy.y * xy.y), atan(xy.y, xy.x));
    float r = uv.x;
    float inside = float(r < radius);
    uv.x  = (1. -inside) * (r-radius) + (inside) * (radius / r - 1.);
    uv.y  = (1. -inside) * uv.y + (inside) * -uv.y;
    
    // fold it
    for (int i=0; i < 3; i++) {
        uv = uv + t * 5. + cos(sin(t*7.) * uv.x * uv.y);
        uv = 3. * cos(uv) * cos(uv);
    }
 
    // glow it
    uv = p * floor(c * uv) / c + (1.- p) * uv * r;
    glFragColor = vec4(0.5 * cos(uv) + 0.5, 0.5 * sin(uv.x) + 0.5, 1.0);

    float b = max((1. - inside) * cos(r/1.5),  0.);
    b = b + exp(-20. * abs(r - radius));
    glFragColor = glFragColor * vec4(b, b, b, 1.);
    
}
