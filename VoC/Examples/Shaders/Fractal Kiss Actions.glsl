#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlG3WK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 24.01.2020, Bielsko-Biała, Poland.

//--- program parameters ---//

const int    K            = 100;            // inversion count

const float    SPEED        = 1.0;            // speed of circles animation
const float ZOOM_SPEED    = 0.35;            // speed of zoom pulse

//--- constants ---//

const float IK        = 1.0 / float(K);

const float    PI        = 3.14159265358979323846;
const float    HALF_PI    = 1.57079632679489661923;

//--- aux functions ---//       
        
vec2 circleInverse(vec2 p, vec3 circle)
{
    vec2 d = p - circle.xy;
    
    return d * (circle.z / dot(d, d)) + circle.xy;
}

//--- calculate pixel color ---//

vec3 calculateColor(vec2 p, float r, float r_squared, float ct, float st)
{
    
    //--- calculate fractal in unit circle only ---//

    float q = dot(p, p);

    if (q > 1.0) return vec3(1.0 / q);

    
    //--- 6 circles encoded by vec3(center_x, center_y, radius^2) pattern ---//
    
    vec3 circles[6] = vec3[6]
    (
        vec3( 1.0,  1.0, 1.0),
        vec3( 1.0, -1.0, 1.0),
        vec3(-1.0, -1.0, 1.0),
        vec3(-1.0,  1.0, 1.0),
        vec3( ct,   st,  r_squared),
        vec3(-ct,  -st,  r_squared)
    );

    
    //--- do K inversions of this circles ---//
            
    int k = 0;
    for (; k < K; k++)
    {
        bool inversion_is_present = false;

        for (int i = 0; i < 6; i++)
        {
            vec2 d = p - circles[i].xy;
            
            if (dot(d, d) < circles[i].z)
            {
                p.xy = circleInverse(p, circles[i]);
                inversion_is_present = true;
                
                break;
            }
        }

        if (false == inversion_is_present) break;
    }

    
    //--- return color by iteration count ---//
    
    float f = 1.0 - float(k)*IK;

    return k%2 == 1? vec3(f) : vec3(0.0, 0.5*f, f);
    
}

void main(void)
{
    
    //--- calculate point coordinates ---//
    
    float    ZOOM = 1.1 + sin(ZOOM_SPEED*time);
    vec2    p    = ZOOM * (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    
    //--- calculate some helpers ---//
    
    float time = SPEED * time;
    
    float r = 0.5 / (1.0 + abs(cos(time)) + abs(sin(time)));
    float r_squared = r*r;

    float ct = r*cos(time);
    float st = r*sin(time);

    
    //--- set final antialiased pixel color by accumulating samples ---//
    
    float a  = 2.0;
    float o  = 1.0 / (4.0*a*a);
    float e  = 0.5 / min(resolution.x, resolution.y);    
    float ea =   e / a;
    
    vec3 col = vec3(0.0);
    
    for (float j = -a; j < a; j++)
        for (float i = -a; i < a; i++)

            col += o*calculateColor(p + ea*ZOOM*vec2(i, j), r, r_squared, ct, st);

        
    glFragColor = vec4(col, 1.0);  
    
}
