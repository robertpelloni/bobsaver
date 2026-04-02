#version 420

// original https://www.shadertoy.com/view/ts3fD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void quasicrystal(vec2 UV,vec2 Scale,float Time,int num,out float Value,out float Value2,out float Line,out float Line2)
{
    vec2 p=UV*Scale;
    float value=0.0;
    float pi = acos(-1.);
    for(int i=0;i<num;i++)
    {
        float angle = pi / float(num) * float(i);
        float w = p.x * sin(angle) + p.y * cos(angle);
        value += sin(w + Time);
    }
    Value=value;
    Value2=1.0+sin(value * pi / 2.0);
    Line=mix(1.0, 0.0, smoothstep(value, 0.0, 0.15 ));
    Line2=mix(1.0, 0.0, smoothstep(Value2, 0.0, 0.02 ));
}
void main(void)
{
    vec2 uv =  ( 2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;
    float  t = time * acos(-1.),value,value2,value3,value4;
    quasicrystal(uv,vec2(18.0),t,7,value,value2,value3,value4);
    glFragColor = vec4(value2);
    glFragColor.b+=value4;
}
