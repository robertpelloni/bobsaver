#version 420

// original https://www.shadertoy.com/view/lddGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1415926535897932384626433832
#define in_ring 0.1  //Inner radius
#define out_ring 0.5 //Outer radius

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5) / resolution.y;
    
    float ang = fract(atan(-uv.y,-uv.x)/atan(1.0)*0.125+0.5)+time*0.1;
    float len = length(uv);
    vec3 col1 = vec3(0.0);
    for(float i = 0.0;i<11.0;i+=1.0)
    {
        float tang = (ang+i)*pi*2.0;
        float tlen = (cos((ang+i)*8.0)*0.5+0.5)*(out_ring-in_ring)+in_ring;
        vec2 pos = normalize(uv)*tlen;
        col1 += smoothstep(0.005,0.0,distance(uv,pos)*pow(length(uv),0.25))
            *(cos(tang+vec3(0.0,2.0*pi,4.0*pi)/3.0)*0.5+0.5);
    }
    glFragColor = vec4(col1,1.0);
}
