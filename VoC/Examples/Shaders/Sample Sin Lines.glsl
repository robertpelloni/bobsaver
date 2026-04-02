#version 420

// original https://www.shadertoy.com/view/stSGWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv.x -= 1.;
    
    vec3 color = vec3(0.);
    
    for( float i = 1.; i < 15.; ++i )
    {
        float t = time;
        uv.y += sin(uv.x*i + t+i/2.) * .2;
        float fTemp = abs(1. / uv.y / 100.);
        color += vec3(fTemp*(10.-i)/10., fTemp/10., vec2(fTemp)*1.5);
    }
    
    glFragColor = vec4(color, 1.0);
}
