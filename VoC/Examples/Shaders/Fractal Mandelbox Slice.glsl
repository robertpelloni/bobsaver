#version 420

// original https://www.shadertoy.com/view/MdVcWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int iterations = 5;
const float scale = 3.0;
const float scape = 3.8;
const float eps = 0.003;

vec3 BoxFold(vec3 vec)
{
    vec3 o = vec3(0.,0.,0.);
    for (int k = 0; k < 3; k++)
    {
        float axis = vec[k];
        if (axis > 1.0)
        {
            axis = 2.0 - axis;
        }
        else if (axis < -1.0)
        {
            axis = -2.0 - axis;
        }
        o[k] = axis;
    }
    return o;
}

vec3 SphereFold(vec3 vec)
{
    float mag = length(vec);
    if (mag < .5)
    {
        vec = vec * 4.0;
    }
    else if (mag < 1.0)
    {
        vec = vec / (mag * mag);
    }
    return vec;
}

float Iteration(vec3 vec)
{
    for (int i = 0; i < iterations; i++)
    {
        vec = BoxFold(vec);
        vec = SphereFold(vec);
        vec = vec * scale;
    }
    float mag = length(vec);
    if(mag < scape){
        float amt = mag / scape;
        return amt;
    }
    return 1.0/mag;
    
}

float AAIteration(vec3 v){
    float aa = Iteration(v);

    aa += Iteration(vec3(v.x + eps, v.y, v.z));
    aa += Iteration(vec3(v.x - eps, v.y, v.z));
    aa += Iteration(vec3(v.x, v.y + eps, v.z));
    aa += Iteration(vec3(v.x, v.y - eps, v.z));
    aa /= 5.0;
    
    return aa;
}

void main(void)
{
    float aspect = resolution.x / resolution.y;
    vec2 mouse = (mouse*resolution.xy.xy / resolution.xy) * 2.0 - 1.0;
    vec2 ncs = (gl_FragCoord.xy/resolution.xy)*2.0-1.0;
    ncs.x *= aspect;
    ncs.y *= -1.0;
    
      vec3 v = vec3(ncs.x + cos(time/10.1),ncs.y+cos(time/10.7),cos(time/25.0)*.9);
       
    float mag = AAIteration(v);
    
      // vignette from https://www.shadertoy.com/view/lsKSWR by Ippokratis 
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv *=  1.0 - uv.yx;   
    float vig = uv.x*uv.y * 15.0; 
    vig = pow(vig, 0.25); 
    
  
    mag *= vig;
    glFragColor = vec4(mag,mag,mag,1.0);
 
      
      
}
