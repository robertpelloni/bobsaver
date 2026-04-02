#version 420

// original https://www.shadertoy.com/view/WllXzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float r2D(vec2 p)
{
    return fract(sin(dot(p, vec2(32.91, 54.28)))*96516.4172);
}

float pattern(vec2 p, float s)
{
    vec2 i = floor(p*s);
    return r2D(i);
}

vec3 normals(vec2 p, float s, float h)
{
    float pixel = 1./resolution.y;
    vec2 e = vec2(pixel, 0.);
    return normalize(
        vec3(
            (pattern(p-e.xy, s)-h)/e.x,
            (pattern(p-e.yx, s)-h)/e.x,
            1.));
}

#define samples 16
#define num_steps 6
#define PI 3.141592
#define radius 12.

float ambient_occlusion(vec2 p, float h, vec3 n, float s)
{
    float ao = 0.;
    float pixel = 1./resolution.y;
    vec3 origin = vec3(p, h);
    for (int i = 0; i < samples; i++)
    {
        float angle = float(i)*PI/float(samples);
        vec2 dir = vec2(cos(angle), sin(angle));
        for (int j = 1; j <= num_steps; j++)
        {
            vec2 point = p+float(j)*pixel*dir*radius;
            float r = pattern(point, s);
            vec3 current = vec3(point, r);
            vec3 dir_curr = current - origin;
            float dir = dot(normalize(dir_curr), n);
            if (dir < 0.)
                break;
            if (dir > 0.)
            {
                ao += length(dir_curr)/float(j);
                break;
            }
        }
    }
    ao /= float(samples);
    return ao;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    float s = 6.;
    float h = pattern(uv, s);
    vec3 n = normals(uv, s, h);
    float ao = 1.-ambient_occlusion(uv, h, n, s);
       
    float t = time;
    vec3 ld = normalize(vec3(cos(t), sin(t), 1.)*3.-vec3(uv, h));
    float diff = max(dot(n, ld), 0.);
    float l = diff*ao;
    
    vec3 col = vec3(0.);
    col += l*mix(vec3(1.), vec3(0.0, .6, .8), h);

    glFragColor = vec4(col,1.0);
}
