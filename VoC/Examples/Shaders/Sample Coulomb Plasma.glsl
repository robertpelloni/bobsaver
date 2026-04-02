#version 420

// original https://www.shadertoy.com/view/WltBD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;

float hash11(float x) {
    return fract(sin(x*543.543)*1364.34);
}

float potential(vec2 uv) {
    float charge = 1.;
    float pot = 0.;
    const int charges = 8;
    for (int n = 0; n < charges; n += 1) {
        float t = (float(n) * 2. * pi / float(charges)) + time * 0.5 + hash11(float(n)) * time;
        pot += charge / length(uv - vec2(cos(t), sin(t) * float(n) / float(charges)));
        charge = -charge;
    }
    return pot;
}

vec2 gradient(vec2 x)
{
    vec2 h = vec2( 0.01, 0.0 );
    return vec2( potential(x+h.xy) - potential(x-h.xy),
                 potential(x+h.yx) - potential(x-h.yx) )/(2.0*h.x);
}

// from https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    glFragColor.a = 1.;
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    uv *= 3.;

    float pot = potential(uv);
    vec2 f = gradient(uv);
    float rate = length(f);
    float dir = atan(f.y, f.x);
    glFragColor.rgb = hsv2rgb(vec3(fract((dir/pi+1.)*0.5), 1., 1.));

}
