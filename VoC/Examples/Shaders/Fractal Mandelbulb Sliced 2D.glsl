#version 420

// original https://www.shadertoy.com/view/4dSSWd

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

// First shader-toy test: render slice of the mandelbulb-fractal
// written 2014 by Jakob Thomsen (jakobthomsen@gmx.de)

//#define MaxIter 128
#define MaxIter 16
const vec3 Center = vec3(0.0, 0.0, 0.0);
const float Scale = 0.5;
const float n = 8.0;

const vec4 InsideColor = vec4(0,0,0,1);
const vec4 OutsideColor1 = vec4(0,0,1,1);
const vec4 OutsideColor2 = vec4(0,1,0,1);

vec4 mandelbulb_slice(vec3 Pos)
{
    float R;
    
    float x = Pos.x / Scale - Center.x;
    float y = Pos.y / Scale - Center.y;
    float z = Pos.z / Scale - Center.z;

    int Iter2 = 0;
    for(int Iter = 0; Iter < MaxIter; ++Iter)
    {
        // source of formula: skytopia.com mandelbulb
        // also see: fractalforums.com
        float r = sqrt(x * x + y * y + z * z);
        float theta = atan(sqrt(x * x + y * y), z);
        float phi = atan(y, x);

        if(r > 2.0)
        {
            R = r;
            Iter2 = Iter;
            break;
        }

        float r_pow_n = pow(r, n);

        float newx = x + r_pow_n * sin(theta * n) * cos(phi * n);
        float newy = y + r_pow_n * sin(theta * n) * sin(phi * n);
        float newz = z + r_pow_n * cos(theta * n);
        x = newx;
        y = newy;
        z = newz;
    }

    vec4 OutsideColor = mix(OutsideColor1, OutsideColor2, fract(float(Iter2) * 0.05));
    vec4 Color = mix(InsideColor, OutsideColor, step(2.0, R));

    return Color;
}

#define PI 3.1415926

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / min(resolution.x, resolution.y);

    glFragColor = mandelbulb_slice(vec3(uv, 0.5 * sin(2.0 * PI * time / 10.0)));
}
