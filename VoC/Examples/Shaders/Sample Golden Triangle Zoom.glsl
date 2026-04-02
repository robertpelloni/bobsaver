#version 420

// original https://www.shadertoy.com/view/Wlcfz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://en.wikipedia.org/wiki/Golden_triangle_(mathematics)

const float pi = 3.14159265358979323;
const float phi = (sqrt(5.) + 1.) / 2.;
const float th = pi * 2. / 5.;

vec2 cMul(vec2 a, vec2 b)
{
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

vec2 cDiv( vec2 a, vec2 b)
{
    return cMul(a, vec2(b.x, -b.y)) / dot(b, b);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy *.5) / resolution.y * 40.;

    float t = time;// + texelFetch(iChannel0, ivec2(gl_FragCoord.xy) & 1023, 0).r / 60.;
    
    vec3 col = vec3(0);

    // Represent the following transformation with complex numbers:
    // mat3(rot(pi - th)) * mat3(vec3(phi, 0, 0), vec3(0, phi, 0), vec3(vec2(-cos(th), sin(th)), 1.)); 
    vec2 c0 = vec2(cos(pi - th), sin(pi - th)) * phi;
    vec2 c1 = vec2(cos(th), -sin(th)) / phi;
    
    // Solve (z - c1) * c0 - z = 0 to find the fixed point of the transformation.
    vec2 zc = cDiv(cMul(c1, c0), c0 - vec2(1, 0));
    
    uv += vec2(cos(t / 3.), sin(t / 2.)) * 8.;
    
    float a = t;
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    
    // Exponential scaling transform, for a seamless (self-similar) zooming animation.
    uv = m * uv * pow(pow(phi - 1., 10.), 1. + fract(t / 3.)) + zc;
    
    vec2 z = uv;
    
    for(int i = 0; i < 32; ++i)
    {
        if(dot(z, vec2(sin(th), cos(th))) > 0.)
        {
            float j = float(i) + floor(t / 3.) * 10.;
            col = sin(vec3(j, j * 2., j * 3.)) * .5 + .5;
            break;
        }
        z = cMul(z - c1, c0);
    }

    glFragColor = vec4(sqrt(col), 1.0);
}
