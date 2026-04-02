#version 420

// original https://www.shadertoy.com/view/3dc3Wr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(x) mat2(cos(x), sin(x), -sin(x), cos(x))

float circle(vec2 uv, float i) {  
    uv *= rot(i*3.14-.4*time);
    uv += .03*sin(vec2(40, 70)*uv.yx);
    float d = length(uv);
    return smoothstep(1., -1., abs(d-.12)/fwidth(d)-.05);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    float col = 0.;
    
    for(float i=.02; i<=1.; i+=.02) {       
        float z = fract(i-.1*time);
        float fade = smoothstep(1., .9, z);
        col += circle(uv*z, i)*(.5/z)*fade;
    }
    
    col = sqrt(col);

    glFragColor = vec4(vec3(col), 1.);
}
