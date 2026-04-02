#version 420

// original https://www.shadertoy.com/view/3t2Szz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on - https://www.shadertoy.com/view/MtXSzH

float noise3D(vec3 p)
{
    return fract(sin(dot(p ,vec3(12.9898,78.233,126.7235))) * 43758.5453);
}

float worley3D(vec3 p)
{                                          
    float r = 3.0;
    vec3 f = floor(p);
    vec3 x = fract(p);
    for(int i = -1; i<=1; i++)
    {
        for(int j = -1; j<=1; j++)
        {
            for(int k = -1; k<=1; k++)
            {
                vec3 q = vec3(float(i),float(j),float(k));
                vec3 v = q + vec3(noise3D((q+f)*1.11), noise3D((q+f)*1.14), noise3D((q+f)*1.17)) - x;
                float d = dot(v, v);
                r = min(r, d);
            }
        }
    }
    return sqrt(r);
}    

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = uv*2.0-1.0;
    p.x*=resolution.x/resolution.y;
    p *= 50.0;
    p.y -= time;
       
    float f = worley3D(vec3(p,time * 0.5));
    
    vec3 col = vec3(1.0-smoothstep(0.3, 0.6, f));
    glFragColor = vec4(col,1.0);
}
