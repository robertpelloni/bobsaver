#version 420

// original https://www.shadertoy.com/view/XscfR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define noz(v) normalize(v)
#define _dot(a, b) max(0.0, dot(a, b))
#define saturate(v) clamp(v, 0.0, 1.0)

float sdf(in vec3 p)
{
    p.xz = mod(p.xz, 6.0) - 3.0;
    p.y = mod(p.y, 5.0) - 2.5;
    
    float torus_r = 2.0;
    vec2 d = vec2(length(p.xz) - torus_r, p.y - 0.5);
    float torus_sdf = length(d) - 0.5;
    
    float cylinder_sdf = length(p.xz) - 0.8;
    
    return min(torus_sdf, cylinder_sdf);
}

vec3 sdf_gradient(in vec3 p)
{
    int matid;
    vec2 e = vec2(0, 0.001);
    return noz(vec3(sdf(p + e.yxx) - sdf(p),
                    sdf(p + e.xyx) - sdf(p),
                    sdf(p + e.xxy) - sdf(p)));
}

float shadow(in vec3 p, in vec3 l)
{
    return 1.0;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x /= resolution.y / resolution.x;
    
    vec3 ro = vec3(0, 4.8, -6.0 + 2.0*time);
    vec3 at = vec3(0, 4.0, 0.0 + 2.0*time);
    vec3 cam_z = noz(at - ro);
    vec3 cam_x = noz(cross(vec3(0,1,0), cam_z));
    vec3 cam_y = noz(cross(cam_z, cam_x));
    vec3 rd = noz(uv.x * cam_x + uv.y * cam_y + 1.79 * cam_z);
    
    float t = 0.001;
    float t_max = 50.0;
    int matid = -1;
    for (int i = 0; i < 200; ++i)
    {
        float d = sdf(ro + t*rd);
        if (d < 0.01)
        {
            matid = 0;
            break;
        }
        t += d;
    }
    
    vec3 col = vec3(1);
    //if (matid != -1) // NOTE(chen): for some reason uncommenting this out gives me whitescreen, wtf webgl?
    {
        vec3 p = ro + t*rd;
        vec3 n = sdf_gradient(p);
        vec3 l = -noz(vec3(0.5, -0.5, 0.5));
        
        vec3 mat = vec3(0.8);
 
        float lighting = 0.25*pow(1.0 + _dot(n, l), 2.0);
        //lighting = _dot(n, l);
        col = (0.15 + 0.85 * shadow(p, l) * lighting) * mat;
        col = mix(col, vec3(1), saturate(pow(clamp(t / t_max, 0.0, 1.0), 3.0)));
    }

    // Output to screen
    glFragColor = vec4(sqrt(col),1.0);
}
