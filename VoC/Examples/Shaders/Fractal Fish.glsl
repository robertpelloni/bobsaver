#version 420

// original https://www.shadertoy.com/view/XdlGRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Logos (Robert Śmietana) on 03.04.2019 in Bielsko-Biała, Poland.

vec3 pixelColor(vec2 p)
{
    
    //--- calculate water (background) color ---//
    
    vec3 wc = vec3(0.0, 0.2 + 0.4*(0.5 - 0.5*p.y), 0.3 + 0.4*(0.5 - 0.5*p.y));
    wc += vec3(0.08*sin(p.y - p.x));
    
    
    //--- get main body of the fish ---//
    
    if (p.x < 3.968)
    {
        p = vec2(p.x, -p.y) / dot(p, p);
    }

    
    //--- carve tail of the fish ---//
    
    else
    {
        p.x -= 3.687;
        if (0.359 - 0.2*cos(5.0*p.y) < dot(p, p)) return wc;
    }

    
    //--- iterate mandelbrot and return pixel color ---//
    
    vec2 z = vec2(p);  
    for (int i = 1; i <= 100; i++)
    {  
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + p; 

        if (504.0 + 300.0*sin(4.1*time) < dot(z, z))
        {
            return z.y < 0.0 ? vec3(0.0) : vec3(1.0);
        }
    }

    
    //--- that was water :) ---//
    
    return wc;
    
}

void main(void)
{
    
    //--- calculate point coordinates ---//
    
    vec2 c = 2.1*(-2.0*gl_FragCoord.xy/resolution.xy + 0.9)*vec2(resolution.x/resolution.y, 1.0) - vec2(-2.0, 0.0);
    
    
    //--- animate fish movement ---//

    c.x += 0.3*sin(0.4*time);
    c.y += 0.15 - 0.3*sin(0.43*time) + 0.2*cos(c.x);
    
    
    //--- add tail swing ---//
    
    if (0.0 < c.x) c.x += 0.1*c.x*cos(2.0*time + sin(0.8*c.x));
    

    //--- calculate final pixel color ---//
    
    float a = 2.0;
    float e = 1.0/min(resolution.x, resolution.y);    
    vec3 col = vec3(0.0);
    
    for (float j = -a; j < a; j++)
        for (float i = -a; i < a; i++)
            col += pixelColor(c + 2.1*vec2(i, j) * (e/a)) / (4.0*a*a);

    glFragColor = vec4(col, 1.0);
    
}
