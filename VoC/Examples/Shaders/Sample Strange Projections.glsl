#version 420

// original https://www.shadertoy.com/view/ttGBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 mul(vec2 a, vec2 b)
{
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    uv *= 1.2;

    uv = mul(uv, uv) + vec2(.5, .9);
    uv = mul(uv, uv) + vec2(cos(radians(30.) * time), sin(radians(35.) * time));
    uv = mul(uv, uv) + vec2(10., -2.);
    uv = mix(uv, normalize(uv), 1.5);
    uv.x = abs(uv.x) - 5.;
    uv.y = abs(uv.y) - 3.;
    uv = mul(uv, uv) + 0. * time;

    uv = mix(uv, 3. * uv / normalize(uv), sin(radians(15.) * time));

    vec3 col = 0.5 + 0.5*cos(radians(360.) * time+uv.xyx+vec3(0,2,4));
    glFragColor = vec4(col,1.0);
}
