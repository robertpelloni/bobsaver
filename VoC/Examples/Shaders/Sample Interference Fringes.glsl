#version 420

// original https://www.shadertoy.com/view/3dVSzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_SOURCES 6.
#define RADIUS .1
#define FREQUENCY 10.
#define TIME_SCALE 4.
#define PI 3.14159265
#define ANGLE_PER_SOURCE (2. * PI / NUM_SOURCES)

float circle(vec2 uv)
{
    float d = length(uv);
    return smoothstep(1., 0.9, d);
}

float wave_source(vec2 uv, float offset)
{
    float d = length(uv);
    float amplitude = cos(FREQUENCY * d - time * TIME_SCALE);// + offset);
    return amplitude;
}

vec3 hsb2rgb( in vec3 c )
{
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5)/(resolution.xy - 1.);
    uv *= 2.;
    uv -= 1.;
    uv.x *= resolution.x/resolution.y;

    vec3 col = vec3(0.);
    float mask = 0.;

    for(float i = 0.; i < NUM_SOURCES; ++i)
    {
        float angle = i * ANGLE_PER_SOURCE;
        vec2 pos = vec2(cos(angle), sin(angle));
        // float scale = 1. / RADIUS;
        // vec2 circle_uv = scale * (uv - pos);
        vec2 circle_uv = uv - pos;
        mask += wave_source(circle_uv, i * time);
//        col = mix(col, vec3(sin(angle), cos(angle), 1.), mask);
    }
    //col = mix(col, vec3(0., 0., 1.), mask);
    vec3 wave_col = hsb2rgb(vec3(mask, 1., mask));
    col = mix(col, wave_col, mask);

    glFragColor = vec4(col,1.0);
}
