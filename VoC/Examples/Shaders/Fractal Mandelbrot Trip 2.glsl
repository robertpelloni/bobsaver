#version 420

// original https://www.shadertoy.com/view/wsVGWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS  200

float mandelbrot(vec2 c)
{
    int i = 0;
    vec2 z = vec2(0.0);
    
    float r = 20.0;
    float r2 = r * r;
    vec2 zp = vec2(0.0, 0.0);
    
    for (i = 0; i < MAX_STEPS; i++)
    {
        zp = z;
        z = vec2(
            z.x * z.x - z.y * z.y,
            2.1 * z.x * z.y);
        
        z += c;
        
        if (dot(z, zp) > r2) break;
    }
    
    float dist = length(z);
    float fractIter = (dist - r) / (r2 - r);
    fractIter = log(dist) / log(r) - 1.;
    float frac = float(i);
    
    float ret = frac / float(MAX_STEPS);
    
    ret *= smoothstep(4.0, 0.0, fractIter);
    ret = pow(ret, .6);
    
    return ret;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    float angularspeed = 8.4 * pow(length(uv * .4) * 0.5, 0.7) + sin(time * .7) * 2.0;
    float cas = cos(angularspeed);
    float sas = sin(angularspeed);
    uv = mat2(vec2(cas, -sas), vec2(sas, cas)) * (uv);
      uv = abs(uv);
    
    float bump = sin(length(uv) * 15. - time * 10.0) * .5 + .5;
    uv += uv * bump * .2;

    vec2 uv2 = vec2(-1.404899, 0.0001) + uv * (pow(4., -mod(time * 2.0, 20.0) * .5) * 80.);
    vec2 uv3 = vec2(-1.404899, 0.0001) + uv * (pow(4., -mod(time * 2.0 + 10., 20.0) * .5) * 80.);
    
    float m1 = mandelbrot(uv2);
    float m2 = mandelbrot(uv3);

    float fractal = max(
        mix(0., m1, sin(time * 6.0) * .4 + .6),
        mix(0., m2, sin(time * 6.0 + 3.0) * .4 + .6));
    
    vec3 col = vec3(
        sin(fractal * 2.5) * .5 + .5, 
        sin(fractal * 1.3) * .5 + .5, 
        sin(fractal * 6.1) * .5 + .5) * (1.1 - length(uv));
    
    glFragColor = vec4(col,1.0);
}
