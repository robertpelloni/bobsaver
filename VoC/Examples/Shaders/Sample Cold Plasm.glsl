#version 420

// original https://www.shadertoy.com/view/MltXWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor.rgb = vec3(0.0);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float time = (time+42.0)+(mouse.x*resolution.x/resolution.x*10.0);
    for( int i=0; i<512; i++ )
    {
        float r1 = fract(sin(float(i)*64.19)*420.82);
        float r2 = fract(sin(float(i)*38.57)*560.21);
        float val = 0.8*pow((1.0-length(uv-vec2(uv.x+(cos((uv.x)*r1*r2*100.0
            -atan(uv.y-sin(time*0.3), uv.x+0.2)*42.0*r1+time*r2)*cos(uv.x+r1-time*0.5)*0.5*r1)
            , sin((uv.x)*r2*2.0+time*r2)*(sin(uv.x+r2-time*0.5)*0.5*r2)+0.5)))
            , 8.0+r2*420.0);
        glFragColor.rgb += vec3(r1, r2, r2+0.1)*val;
    }
}
