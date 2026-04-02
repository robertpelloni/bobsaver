#version 420

// original https://www.shadertoy.com/view/3dSXzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Logos (Robert Śmietana) - 30.12.2019, Bielsko-Biała, Poland.

//--- auxiliary functions ---//

vec2 cmul(vec2 z1, vec2 z2) { return vec2(z1.x * z2.x - z1.y * z2.y, z1.x * z2.y + z1.y * z2.x ); }
vec2 cdiv(vec2 z1, vec2 z2) { vec2 conj = vec2(z2.x, -z2.y); return cmul(z1, conj) / (length(z2) * length(z2)); }

vec2 ccos(vec2 z)            { return vec2(cos(z.x) * cosh(z.y), -sin(z.x) * sinh(z.y)); }
vec2 csin(vec2 z)            { return vec2(sin(z.x) * cosh(z.y),  cos(z.x) * sinh(z.y)); }

vec2 newton(vec2 z)            { return z - (1.35 - 0.35 * sin(0.3*time))*cdiv(csin(z), ccos(z)); }
vec2 rot(vec2 z, float a)    { return vec2(z.x*cos(a) - z.y*sin(a), z.y*cos(a) + z.x*sin(a)); }

//--- calculate pixel color ---//

vec3 calculateColor(vec2 z)
{
    
    //--- invert complex plane ---//
    
    z = vec2(z.x, -z.y) / dot(z, z);

    
    //--- iterate newton formula until small const (0.14) ---//
    
    for (int i = 0; i < 80; i++)
    {
        vec2 n = newton(z);
        if (length(z - n) < 0.14) break;
        
        z = rot(n, 0.401*sin(0.512*time));
    }
    
    
    //--- return color by binary decomposition ---//
    
    return z.x < 0.0 ? vec3(0.0) : vec3(1.0);
}

void main(void)
{
    
    //--- calculate point coordinates ---//
    
    float ZOOM = 1.8;
    vec2 z = ZOOM * (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    
    //--- calculate final pixel color ---//
    
    float a = 2.0;
    float e = 1.0/min(resolution.x, resolution.y);    
    vec3 col = vec3(0.0);
    
    for (float j = -a; j < a; j++)
        for (float i = -a; i < a; i++)
            col += calculateColor(z + ZOOM*vec2(i, j) * (e/a)) / (4.0*a*a);
        
    glFragColor = vec4(col, 1.0);  
    
}
