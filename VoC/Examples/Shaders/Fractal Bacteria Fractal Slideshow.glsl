#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WtG3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 26.01.2020, Bielsko-Biała, Poland.

//--- program parameters ---//

const int    K    = 100;            // inversion count

//--- structs ---//

struct State
{
    vec4 r2s;        // squared radiuses of 4 base spheres
    vec3 a;            // factors of 5th sphere
    vec3 b;            // factors of 6th sphere
    vec3 color;        // color of fractal
};

    
//--- functions ---//
 
State getStateByIndex(int a_index)
{
    State s;
    
    switch (a_index)
    {
        
        case 0:
        {
            s.a = vec3(-3.7183, 6.226, 50.5677);
            s.b = vec3(4.7127, -5.1258, 50.5677);
            s.color = vec3(0.6, 0.7, 0.35);
            s.r2s = vec4(1.2, 1.1, 1.3, 0.4);
            
            break;
        }

        case 1:
        {
            s.a = vec3(1.3039, -2.099, 6.8178);
            s.b = vec3(-1.1738, 2.3323, 6.8178);
            s.color = vec3(0.15, 0.5, 0.5);
            s.r2s = vec4(1.2, 1.0, 0.9, 1.0);
            
            break;
        }

        case 2:
        {
            s.a = vec3(0.424, -16.9482, 256.7489);
            s.b = vec3(-0.5817, 14.2999, 233.4081);
            s.color = vec3(0.45, 0.245, 0.7);
            s.r2s = vec4(1.2, 1.1, 0.9, 1.1);
            
            break;
        }

        case 3:
        {
            s.a = vec3(-3.925, -12.7205, 207.8383);
            s.b = vec3(3.92, 15.0619, 207.8383);
            s.color = vec3(0.75, 0.25, 0.075);
            s.r2s = vec4(1.1, 1.1, 1.0, 0.94);
            
            break;
        }

        case 4:
        {
            s.a = vec3(3.0318, 7.2577, 57.8171);
            s.b = vec3(-3.4763, -5.9808, 52.561);
            s.color = vec3(0.4, 0.6, 0.5);
            s.r2s = vec4(1.2, 1.1, 1.3, 1.4);
            
            break;
        }

        case 5:
        {
            s.a = vec3(2.1508, -20.2580, 371.9627);
            s.b = vec3(-2.4984, 17.0729, 338.1479);
            s.color = vec3(0.5, 0.5, 0.9);
            s.r2s = vec4(1.2, 1.1, 0.3, 1.1);
            
            break;
        }

        case 6:
        {
            s.a = vec3(-2.1332, -3.1201, 16.2223);
            s.b = vec3(2.0859, 3.5435, 16.2223);
            s.color = vec3(0.05, 0.25, 0.75);
            s.r2s = vec4(1.1, 1.1, 1.0, 0.94);
            
            break;
        }

    }

    return s;
}

State mixState(State s1, State s2, float f)
{
    State s;
    
    s.a = mix(s1.a, s2.a, vec3(f));
    s.b = mix(s1.b, s2.b, vec3(f));
    s.color = mix(s1.color, s2.color, vec3(f));
    s.r2s = mix(s1.r2s, s2.r2s, vec4(f));
    
    return s;
}

vec2 rotate(vec2 v, float angle)
{
    float ca = cos(angle);
    float sa = sin(angle);
    
    return v*mat2(+ca, -sa, +sa, +ca);
}

//--- constants ---//

const float IK    = 1.0 / float(K);

//--- aux functions ---//       
        
vec2 circleInverse(vec2 p, vec3 circle)
{
    vec2 d = p - circle.xy;
    
    return d * (circle.z / dot(d, d)) + circle.xy;
}

//--- calculate pixel color ---//

vec3 calculateColor(vec2 p, State s)
{
    
    //--- set 6 circles ---//
    
    vec3 circles[6] = vec3[6]
    (
        vec3( 1.0,  1.0, s.r2s.x),
        vec3( 1.0, -1.0, s.r2s.y),
        vec3(-1.0, -1.0, s.r2s.z),
        vec3(-1.0,  1.0, s.r2s.w),
        
        vec3(s.a), vec3(s.b)
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
    
    return k%2 == 1? vec3(f) : f*s.color; 
}

void main(void)
{
    
    //--- calculate point coordinates ---//
    
    float    ZOOM = 2.3;
    vec2    p    = ZOOM * (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    p = rotate(p, 0.06*time);
    
    
    //--- set current parameters ---//
    
    float time = 0.2*time;
    float t = fract(time);
    
    int index = int(floor(mod(time, 7.0)));
    int next_index = (index + 1) % 7;

    State s;
    
    if (t < 0.8)
    {
        s = getStateByIndex(index);
    }
    else
    {
        State s1 = getStateByIndex(index);
        State s2 = getStateByIndex(next_index);
        
        s = mixState(s1, s2, 5.0*(t - 0.8));
    }

    
    //--- fractal animation ---//
    
    s.a[0] += 0.06*t;
    s.b[1] -= 0.02*t;
    
    
    //--- set final antialiased pixel color by accumulating samples ---//
    
    float a  = 3.0;
    float o  = 1.0 / (4.0*a*a);
    float e  = 0.5 / min(resolution.x, resolution.y);    
    float ea =   e / a;
    
    vec3 fc = vec3(0.0);
    
    for (float j = -a; j < a; j++)
        for (float i = -a; i < a; i++)

            fc += o*calculateColor(p + ea*ZOOM*vec2(i, j), s);

        
    //--- vignetting taken from https://www.shadertoy.com/view/lsKSWR ---//
        
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv *=  1.0 - uv.yx;
    float vig = uv.x*uv.y * 70.0;
    vig = pow(vig, 0.20);
        
    glFragColor = vec4(vig*fc, 1.0);  
    
}
