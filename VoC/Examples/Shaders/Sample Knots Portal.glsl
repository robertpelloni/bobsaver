#version 420

// original https://www.shadertoy.com/view/cdsyRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float M_PI = 3.1415926535;
const vec3 LIGHT = normalize(vec3(0.0, 0.0, 1.0));

//Sources: https://gist.github.com/yiwenl/745bfea7f04c456e0101
// https://gist.github.com/sugi-cho/6a01cae436acddd72bdf
vec3 hsv2rgb(vec3 c){
    vec4 K=vec4(1.,2./3.,1./3.,3.);
    return c.z*mix(K.xxx,clamp(abs(fract(c.x+K.xyz)*6.-K.w)-K.x, 0., 1.),c.y);
}

vec3 point_on_curve(float t, int k, float phase, float stretch)
{
    float sn = sin(t + phase), 
          cs = cos(t + phase), 
          snk = sin(float(k) * (t + phase)) / float(k);
    return vec3(cs, t * stretch, snk);
}

float dist_to_point_on_curve_dt(vec3 p, float t, int k, float phase, float stretch)
{
    float sn = sin(t + phase), cs = cos(t + phase), snk = sin(float(k) * (t + phase)), csk = cos(float(k) * (t + phase));
    return 2.0 * (sn * (p.x - cs) - csk * (p.z - snk / float(k)) - stretch * (p.y - stretch * t));
}

float nearest_point_on_curve(vec3 p, int curve, float phase, float stretch)
{
    float t = p.y / stretch;
    for (int i = 0; i < 2;i++)
    {
        float dt = dist_to_point_on_curve_dt(p, t, curve, phase, stretch);
        t -= dt * 0.15;
    }
    return t;
}

float sd_curve(vec3 p, int k, float phase, float stretch, float radius)
{
    float t = nearest_point_on_curve(p, k, phase, stretch);
    return (length(point_on_curve(t, k, phase, stretch) - p) - radius) * 0.7;
}

float sd_curve_multi(vec3 p, int k, int n, float phase, float stretch, float radius)
{
    float res = 1000.0;
    for (float i = 0.0; i < float(n); i++)
    {
        res = min(res, sd_curve(p, k, M_PI * 2.0 * i / float(n) + phase, stretch, radius));
    }
    return res;
}

vec3 map_circle(vec3 p, float radius)
{
    return vec3(length(vec2(p.y, p.x)) - radius, atan(p.y, p.x) * radius, p.z);
}

float approximate_curve_length(float t, float phase, float stretch)
{
    // This tries to approximate curve length on the segment [0; t]
    // But this formula is very inprecise.
    return t * (pow(stretch * 2.2, 1.8) + 10.12)/10.0
           - sin((t + phase) * 2.0) * 0.1 * ((0.95 - cos(2.0 * (t + phase))) * 0.83)
           + sin(phase * 2.0) * 0.095;
}

vec3 map_curve(vec3 p, float phase, float stretch, float radius, float target_radius)
{
    float t = nearest_point_on_curve(p, 2, phase, stretch);
    float l = approximate_curve_length(t, phase, stretch);
    vec3 pp = point_on_curve(t, 2, phase, stretch);
    
    float sn = sin(t + phase);
    float cs = cos(t + phase);
    float csk = cos(3.0 * (t + phase));
    
    vec3 ny = normalize(vec3(-sn, stretch, csk));
    vec3 nz = normalize(vec3(0.0, 0.0, 1.0));
    vec3 nx = normalize(cross(ny, nz));
    nz = normalize(cross(nx, ny));
    
    float scale = (1.0 + target_radius) / radius;
    return vec3(dot(p - pp, nx), l, dot(p - pp, nz)) * scale;
}

vec4 op(vec4 a, vec4 b)
{
    return a.w < b.w ? a : b;
}

vec4 map(vec3 p)
{
    vec4 res = vec4(0.0, 0.0, 0.0, 1000.0);
    
    
    float scale = 1.0;
    float t = time * 0.4;
    
    // Apply partial transform to the first portal ring for seamless transition
    p.z -= 0.6 * fract(t);
    p /= pow(1.7, fract(t));
    scale *= pow(1.7, fract(t));
    
    for (int k = 0; k < 5; k++)
    {
        vec3 color = hsv2rgb(vec3((floor(t) + float(k)) * 0.1, 0.7, 0.8));
        float side = 1.0 - 2.0 * float((k + int(floor(t))) % 2);
        for (int i = 0; i < 3; i++)
        {
            vec3 pp = map_circle(p, 6.0);
            
            if (length(pp.xz) > 1.4)
            {
                res.w = min(res.w, scale * (length(pp.xz) - 1.1));
                continue;
            }
            
            pp = map_curve(pp, 2.0 * M_PI / 3.0 * float(i) + time * 0.5 * side, 2.0, 0.4, 0.4);
            res = op(res, vec4(color, scale * sd_curve_multi(pp, 3, 4, 0.0 + time * 4.0 + sin(time + float(i) * M_PI * 0.5) * 4.0, 1.0, 0.3)));
        }
        
        // Apply transform to the next portal ring
        scale /= 1.7;
        p *= 1.7;
        p.z += 0.6;
    }
    
    // Scale down sdf, because it is not really an sdf an we can miss surface.
    res.w *= 0.35;
    return res;
}

vec4 trace(vec3 origin, vec3 dir)
{
    float t = 0.;
    for (int i = 0; i < 24; i++)
    {
        vec4 h = map(origin);
        origin += dir * h.w;
        t += h.w;
        if (h.w < 0.01) return vec4(h.rgb, t);
        if (origin.z < -6.0) break;
    }

    return vec4(-1.0);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.02;
    return normalize(e.xyy*map(pos + e.xyy).w +
                     e.yyx*map(pos + e.yyx).w +
                     e.yxy*map(pos + e.yxy).w +
                     e.xxx*map(pos + e.xxx).w);   
}

void main(void)
{
    glFragColor = vec4(0);
    
    vec3   R = vec3(resolution.xy,1.0),
         dir = normalize(vec3( gl_FragCoord.xy - .5* R.xy , -R.y )),
      origin = vec3(0, 0, 8);
    
    vec4 res = trace(origin, dir);
    if (res.w > 0.)
    {
        vec3 n = calcNormal(origin + res.w * dir);
        float l = clamp(dot(LIGHT, n), 0., 1.) * 0.6 + 0.4;
        l *= clamp((dir.z * res.w + origin.z) + 0.7, 0.0, 1.0);
        glFragColor = vec4(res.rgb * l, 1);
    }
}