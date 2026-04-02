#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XsjfRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor = vec4(0);
    float t = time/2.;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= .5;
    
    uv.y /= resolution.x/resolution.y;
    uv *= 2.*sin(t/5.)+3.;
    
    float s = sin(t/3.), c = cos(t/3.);
    uv *= mat2(s,c,c,-s);
    
    uv = abs(fract(abs(uv))-.5);
    
    s = sin(t-uv.x*4.), c = cos(t+uv.y*4.);
    uv *= mat2(s,c,c,-s);
    
    uv = fract(uv);
    uv *= sin(t/10.)*50.+60.;
    uv = fract(uv/32.)*64.;
    
    uv *= mat2(s,c,c,-s);
    
    for(float i = -4.; i < 4.; i ++)
    {
        t+=.1;
        uv += 32.*sin(i*2.);
        glFragColor += float((int(uv.x) ^ int(uv.y)) < int( abs(fract(t/4.)-.5)*126. ));
    }
    
    glFragColor = vec4(abs(sin(.15*glFragColor.xyz*vec3(.4,.8,1.6)+2.*(t+uv.x/64.))),0.);
}
