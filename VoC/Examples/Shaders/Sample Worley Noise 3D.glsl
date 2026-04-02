#version 420

// original https://www.shadertoy.com/view/WdSfDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

float GetIntegerNoise(vec2 p)  // replace this by something better, p is essentially ivec2
{
    p  = 53.7 * fract( (p*0.3183099) + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) );
}

float Hash(float f)
{
    return fract(sin(f)*43758.5453);
}

float Hash21(vec2 v)
{
    return Hash(dot(v, vec2(253.14, 453.74)));
}

vec3 Random3D( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1,311.7,217.3)),dot(p,vec3(269.5,183.3,431.1)), dot(p,vec3(365.6,749.9,323.7))))*437158.5453);
}

vec2 Rotate2D(vec2 v, float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    
    mat2 rotMat = mat2(c,s,-s,c);
    return rotMat * v;
}

float GetWorleyNoise3D(vec3 uvw)
{
    float noise = 0.0;
    
    vec3 p = floor(uvw);
    vec3 f = fract(uvw);
    
    float minDist = 99.0;
    for(int x = -1; x <=1; ++x)
    {
        for(int y = -1; y <=1; ++y)
        {
            for(int z = -1; z <=1; ++z)
            {
                vec3 ngp = p + vec3(x, y, z);    //ngp: neighbouring grid point

                vec3 v = Random3D(ngp);
                //v = (v + 1.0) * 0.5;

                //v.xy = Rotate2D(v.xy * 0.25, Hash21(v.xy) * time * 0.25 * PI);

                float d = distance(ngp + v, uvw);
                minDist = min(minDist, d);
            }
        }
    }

    return 1.0-minDist;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv *= 8.0;
    vec3 uvw = vec3(uv, time * 0.1);
    
    //uv *= 0.5*(sin(time * 2.0) + 5.0) * 2.40;

    float noise = GetWorleyNoise3D(uvw);
    //noise += GetWorleyNoise3D(uvw * 2.0) * 0.5;

    vec3 color = noise * vec3(1.0);
    glFragColor = vec4(color, 1.0);
}

