#version 420

// original https://www.shadertoy.com/view/tscSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float p)
{
    return fract(sin(dot(vec2(p), vec2(12.9898, 78.233))) * 43758.5453);    
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float map(vec3 pos) {
    float d = sdOctahedron(pos, 0.5);
    
    vec3 centers[4] = vec3[4](
        vec3(0.4 + 0.2 * sin(2.0*time), 0.4 + 0.2 * sin(time), 0.0),
        vec3(-0.4 + 0.3 * cos(3.0*time), 0.4 + 0.2 * cos(1.5*time), 0.0),
        vec3(0.4 * cos(time), -0.4, 0.4 * sin(time)),
        vec3(-0.4, -0.4, 0.0)
    );
    
    for (int i = 0; i < 4; ++i)
    {
        float d2 = sdSphere(pos - centers[i], 0.2);
        d = min(d, d2);
    }
    
    return d;
}

vec3 calcNormal(vec3 pos)
{
    vec2 eps = vec2(0.0001, 0.0);
    float d = map(pos);
    return normalize(vec3(
        map(pos + eps.xyy) - d,
        map(pos + eps.yxy) - d,
        map(pos + eps.yyx) - d
    ));
}

float ambientOcclusion(vec3 pos, float fallout)
{
    const int nS = 12; // number of samples
    const float max_dist = 0.07;
    vec3 N = calcNormal(pos);
    
    float diff = 0.0;
    for (int i = 0; i < nS; ++i)
    {        
        float dist = max_dist * hash(float(i)); // rand len
        float s_dist = max(0.0, map(pos + dist * N)); // sample
        
        diff += (dist - s_dist) / max_dist;
    }
    
    float diff_norm = diff / float(nS);
    float ao = 1.0 - diff_norm/fallout;
    
    return clamp(ao, 0.0, 1.0);
}

void main(void)
{
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = vec3(0);
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.y;
    
    vec3 cam_pos = vec3(sin(3.0 * mouse.x), 
                        cos(3.0 * mouse.y),
                        cos(3.0 * mouse.x));
    
    vec3 cam_target = vec3(0,0,0);
    vec3 cam_ww = normalize(cam_target - cam_pos);
    vec3 cam_uu = normalize(cross(cam_ww, vec3(0,1,0)));
    vec3 cam_vv = normalize(cross(cam_uu, cam_ww));
    
    vec3 ro = cam_pos;
    vec3 rd = normalize(p.x * cam_uu + p.y * cam_vv + 2.0 * cam_ww);
    
    float t = 0.0;
       for (int i = 0; i < 64; ++i)
    {
        vec3 pos = ro + t * rd;
        float h = map(pos);
        if (h < 0.0001)
        {
            break;
        }
        t += h;
        if (t > 20.0)
        {
            break;
        }
    }
    
    if (t < 20.0)
    {
        vec3 pos = ro + t * rd;
        vec3 N = calcNormal(pos);
        float ao = ambientOcclusion(pos, 0.5);
        col = vec3(ao) * (0.5 * N + 0.5);
    }
    
    col = clamp(col, vec3(0.0), vec3(1.0));
    col = pow(col, vec3(0.4545));
    
    glFragColor = vec4(col,1.0);
}
