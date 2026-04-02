#version 420

// original https://www.shadertoy.com/view/4llXDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define time time

float arc(in float R, in float angle, in float start, in float end, in float motionBlur){
    float e = 0.0025;
    float ea = 0.0015 * (1. + motionBlur);

    float f = smoothstep(start-e, start+e, R) * (1.-smoothstep(end-e, end+e, R));
    f *= smoothstep(0.25-ea, 0.25+ea, angle);
    f *= 1. - smoothstep(0.75-ea, 0.75+ea, angle);
    return 1. - f;
}

void rot(inout vec2 r, in float theta){
    mat2 rot = mat2(
        cos(theta), -sin(theta), 
        sin(theta), cos(theta)
    );
    r *= rot;
}

void main(void)
{
    glFragColor = vec4(vec3(1.0), 1.);
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec2 r = uv - vec2(.5);
    r.x *= resolution.x/resolution.y;
    rot(r, -PI*.5);
   
    const float width = 0.02;
    const float gap = 0.003;
    const float count = 20.0;
    const float motionBlurStrength = 0.005;
    const float chromaticAbberationX = 0.01;
    
    float speed = 0.25;
    float v = sin(time*speed + PI)*0.8;
    float v2 = cos(time*speed + PI*1.0)*.5 + .5;
    float theta = time*speed + v;
    
    for(int c = 0; c < 3; c++){
        
        vec2 r2 = r;
        r2.y += float(c - 1) * chromaticAbberationX * length(r);
        
        for(float i = 0.0; i < count; i++){
            float j = i * (width+gap);
            rot(r2, theta + float(c-1)*i*0.00035*v2);
            float angle = (atan(r2.y, r2.x) + PI)/(2.*PI);
               float R = length(r2);
            R += sin(angle*30.0) * 0.01;
            float f = arc(R, angle, 0.0 + j, width + j, i*i*i*motionBlurStrength*v2);
            glFragColor[c] *= f;
        }
        
    }
    
    
}
