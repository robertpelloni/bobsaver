#version 420

// original https://www.shadertoy.com/view/4tc3R2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592;

const vec2 range = vec2(60, 10);
const float lineThickness = 3.;
const float gridThickness = 1.;

const float speed = 2. * PI / 5.;

vec3 plot(float fy, vec2 uv, vec3 color)
{
    return color * step(abs(fy - uv.y) * resolution.y, lineThickness * range.y);
}

float f1(float x)
{
    x -= time * speed;
    return sin(x);
}

float f2(float x)
{
    return sin(x * 1.2);
}

float rand(float x) { return fract(sin(4798.103853 * x)); }

float noise(float x)
{
    float i = floor(x);
    float f = fract(x);    
    float u = f*f*(3.0-2.0*f);
    return mix(rand(i), rand(i+1.), u);
}

vec3 plotFunctions(vec2 uv)
{
    vec3 c = vec3(0,0,0);
    
    c += plot(f1(uv.x), uv, vec3(0,0.5,0.8));
    c += plot(f2(uv.x), uv, vec3(0.7,0.5,0));
    c += plot(f1(uv.x) + f2(uv.x), uv, vec3(0,1,0));
    c += plot(f1(uv.x) * f2(uv.x), uv, vec3(0.5,0,0.8));
    
    float y=0.;
    for (float i=0.; i<6.; i++)
    {
        float offset = time * speed / (i+1.);
        offset *= fract(i * 0.5)*4. - 1.;
        float freq = 0.5*i+1.;
        float amp = 1. / (i+1.);
        y += sin((uv.x + offset)*freq) * amp;
    }
    c += plot(y * 0.4 + 3., uv, vec3(1,1,1));
    
    c += plot(0.5 * noise(2.*uv.x + time * speed) - 3., uv, vec3(1,1,1));
        
    return c;
}

void main(void)
{
    glFragColor=vec4(0.0);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    
    // grid
    glFragColor.r = step(abs(uv.x) * resolution.x, gridThickness) +
        step(abs(uv.y) * resolution.y, gridThickness);
    
    // plotFunctions
    glFragColor.rgb += plotFunctions(uv * range);
    glFragColor.a = 1.;
}
