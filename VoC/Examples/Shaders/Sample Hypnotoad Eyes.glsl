#version 420

// original https://www.shadertoy.com/view/wsdXzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 3.14159;

float midpupil(vec2 uv, float time, float lr_split)
{
    // Time varying pixel color
    uv.y += sin(time*10.0+lr_split)*0.06;
    uv.y *= 1.1 + (cos(time*3.0)*0.25);
    uv.x += sin(time*4.0+(pi*lr_split))*0.03;
    float iris = smoothstep(0.0, 0.38, length(uv));
    uv.x *= 0.6;
    float sidemove = cos(time*3.33+uv.x*(lr_split-0.5))*0.12;
    uv.x -= sidemove;
    float liris = smoothstep(0.0, 0.17, length(uv));
    uv.x += sidemove*2.0;
    uv.y += sin(time*(11.0*(lr_split-0.5)))*0.022;
    float riris = smoothstep(0.0, 0.17, length(uv));
    return iris * liris * riris;
    
}

float roundeye(vec2 uv)
{
     return smoothstep(0.0, 0.7, length(uv));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float lr_split = step(uv.x, 0.5);
    uv.x *= (resolution.x/resolution.y);
    uv.x = fract(uv.x);
    uv -= 0.5;
    uv *= 2.0;
    uv.x += 0.2;
    
    vec3 skin = vec3(0.3, 0.25, 0.07);
    vec3 iris = vec3(0.6, 0.58, 0.03);
    vec3 yellow = vec3(1.0, 0.88, 0.1);
    vec3 red = vec3(1.0, 0.0, 0.0);
    
    float pupil = midpupil(uv, time, lr_split);
    float pupil_max = 1.0 - step(pupil, 0.9);
    float pupil_mid = 1.0 - step(pupil, 0.75);
    float pupil_min = 1.0 - step(pupil, 0.45);
    
    float eye = roundeye(uv);
    float eye_big_circle = 1.0 - step(eye, 0.99);
    float eye_small_circle = step(eye, 0.986);
    skin *= eye_big_circle;
    skin += iris * eye_small_circle * pupil_max;
    float flicker = 1.0 - ((sin(time*30.0) + (pi*0.5)) / (pi*2.0));
    skin += yellow * (1.0 - pupil_max) * flicker;
    skin *= pupil_mid;
    skin += red * (1.0 - pupil_mid) * flicker;
    skin *= pupil_min;

    // Output to screen
    glFragColor = vec4(skin, 1.0);
}
