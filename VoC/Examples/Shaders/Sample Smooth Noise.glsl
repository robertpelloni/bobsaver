#version 420

// original https://www.shadertoy.com/view/3l3Xz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define smoothness 1.

float hash(float p)
{
    float n = mod(p/.46,94.7);
     return fract(cos(n)/.00341);
}

float value(float p)
{
    float f = fract(p);
     return  mix(hash(p-f),hash(p+1.-f),f);  
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float n = ceil(sin(time)*4.+4.);
    float h = 0.;
    for(float i =0.;i<n;i++)
    {
        h += value(uv.x*8.+i/n*smoothness+time);
    }
    float l = smoothstep(2./resolution.y,-2./resolution.y,h/n-uv.y);

    glFragColor = vec4(l,l,l,1.);
}
