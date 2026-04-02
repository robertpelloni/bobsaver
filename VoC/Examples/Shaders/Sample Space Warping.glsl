#version 420

// original https://www.shadertoy.com/view/3dfyzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sp(vec4 pos)
{
    float r = 1.0;
    
    for (int i = 0 ; i < 3; ++i)
        r *= ((clamp(length(pos)*0.25 / float(i) - 0.25 / float(i), 0., 1.) - .03)) * 20.;
    
    return r;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x /= resolution.y / resolution.x;
    
    vec4 pos = vec4(uv.x, uv.y, 0., 1.);
    pos.z = length(pos.xy) * sin(time);
    
    pos.xy /= sp(pos);
    pos.z = length(pos.xy);
    
    vec3 col = vec3(0.5);
    vec3 cb = mod(pos.yxy*sin(time) + time, 5.0) * 0.3;
    cb.x = 0.;
    
    col = cb / exp(pos.z * 0.07);
    
    glFragColor = vec4(col,1.0);
}
