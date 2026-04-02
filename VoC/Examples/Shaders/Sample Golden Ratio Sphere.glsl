#version 420

// original https://www.shadertoy.com/view/wtByz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_SAMPLES 256.0
#define USE_GOLDEN_RATIO

float circle(in vec2 uv, in vec2 p, in float rad)
{
    vec2 puv = uv - p;
    float rsquare = rad*rad;
    return smoothstep(rsquare + 0.000005, rsquare - 0.000005, dot(puv, puv));
}

mat3 rotateAroundY(float a)
{
    float cs = cos(a);
    float sn = sin(a);
    return
        mat3( cs, 0.0, -sn,
              sn, 0.0,  cs,
             0.0, 1.0, 0.0);
}

void main(void)
{
    float pi = radians(180.0);
    float aspect = resolution.y / resolution.x;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.y *= aspect;

    vec3 col = vec3(.5, .5, .5);
    
    mat3 rot = rotateAroundY(time / 3.0);
    
    for(float i = 0.0; i < NUM_SAMPLES; i += 1.0) {
        float phi = acos(1.0 - 2.0 * (i + 0.5) / NUM_SAMPLES);
        #ifdef USE_GOLDEN_RATIO
            float theta = pi * (1.0 + sqrt(5.0)) * i;
        #else
            float theta = pi / 0.931 * i; // some interesting random ratio
        #endif
        float sphi = sin(phi);
        vec3 p = vec3(
            sphi * cos(theta), 
            sphi * sin(theta),
            cos(phi)
        );
        p = rot * p;
        p *= aspect / 2.0;
        vec3 clr = vec3(1.0, 1.0, 1.0) * (1.0 - (p.z + 0.5) * 0.5);
        p += vec3(0.5, 0.5 * aspect, 0.5);
        float plot = circle(uv, p.xy, 0.0025);
        col = mix(col, clr, plot * 0.75);
    }
    
    glFragColor = vec4(col,1.0);
}
