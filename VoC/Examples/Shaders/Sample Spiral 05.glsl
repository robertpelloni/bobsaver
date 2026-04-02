#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358
#define PI2 (PI*2.)

// http://glsl.heroku.com/e#7109.0 simplified by logos7@o2.pl

void main(void)
{
    vec2 position = 100.0 * ((2.0 * gl_FragCoord.xy - resolution) / resolution.x);

    float r = length(position) * 2.;
    float a = atan(position.y, position.x);
    float d = r - a + PI2;
    float n = PI2 * float(int(d / PI2));
    float k = a + n;
    float s = 15.;
    float rand = tan(floor(0.025 * k * k + -time * s));
    float rand2 = tan(floor(0.025 * k * k + -(time-((3./s)/PI)) * s));
    vec3 c = fract(rand*vec3(2, 7., 3));
    c = mix(c,fract(rand2*vec3(2, 7., 3)),fract(0.025 * k * k + -time * s)*clamp(1./(length(position)/80.),0.,1.));
    glFragColor.rgba = vec4(c * 2. - 0.6, 1.);
}
