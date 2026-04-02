#version 420

// original https://www.shadertoy.com/view/NttXWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Inspired by wnu's 'chocolate swirl': https://www.shadertoy.com/view/NtcSDs
    and combined with: https://www.shadertoy.com/view/fl3XDs
*/

#define RATIO resolution.x / resolution.y
#define POINTS 15
#define FORCE 3. // the larger the smaller the swirl
#define ROTATION 9.

#define PI 3.141592653589793

float n21 (vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 n22 (vec2 p)
{
    float n = n21(p);
    return vec2(n, n21(p+n));
}

mat2 rotate (float a) 
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 diffuseLight (vec2 uv, vec3 normals, vec3 pos, vec3 col)
{
    vec3 dif = pos - vec3(uv, 0.); // point light
    //vec3 dif = pos; // directional light
    vec3 dir = normalize(dif);
    float intensity = 1. / length(dif); // inverse square law
    float diffuse   = dot(normals, dir) * intensity;
    return col * diffuse;
}

vec3 getHeight (vec2 uv, inout float acc_frc, inout vec2 acc_rot)
{
    float tm = time * .1;
        
    for (int i = 0; i < POINTS; i++)
    {
        float n = n21(vec2(i + 1));
        vec2 pnt = vec2(.5) + vec2(cos(tm + n * 423.1) * .6, sin(tm + n * 254.3) * .3);

        vec2  loc = uv - pnt;
        float len = length(loc);
        float frc = exp(len * -FORCE);
        float swl = frc * ROTATION * sin(tm + n * 624.8); 
        vec2  rot = loc * rotate(swl);
        
        uv = rot + pnt;
        
        acc_frc += frc;
        acc_rot += rot * frc; 
    } 
    
    float h = cos(uv.x + uv.y + 1.) * .5 + .5;
    
    return vec3(uv, h);
}

vec3 getNormal (vec2 p)
{
    float f = .0;
    vec2  r = vec2(0.);
    
    vec2 eps = -vec2(1. / resolution.y, .0);

    vec3 n;
    n.x = getHeight(p + eps.xy, f, r).z - getHeight(p - eps.xy, f, r).z;
    n.y = getHeight(p + eps.yx, f, r).z - getHeight(p - eps.yx, f, r).z;
    n.z = eps.x + .003;

    return normalize(n);
}

vec3 offsetLights (vec2 uv, vec3 normals)
{
    float tm  = time * 1.;
    float off = .2; // offset
    float sth = .7;  // strength
    float amb = .2;  // ambient
    float rad = 1.;  // radius
    vec3 pos  = vec3(.5, .5, 1.);
    
    float o2 = 1. * off;
    float o3 = 2. * off;
    
    vec3 p1 = vec3(pos.x + cos(tm) * rad, pos.y + sin(tm + 0.) * rad, pos.z);
    vec3 p2 = vec3(pos.x + cos(tm + o2) * rad, pos.y + sin(tm + o2) * rad, pos.z);
    vec3 p3 = vec3(pos.x + cos(tm + o3) * rad, pos.y + sin(tm + o3) * rad, pos.z);
    
    vec3 l1 = diffuseLight(uv, normals, p1, vec3(sth, 0., 0.));
    vec3 l2 = diffuseLight(uv, normals, p2, vec3(0., sth, 0.));
    vec3 l3 = diffuseLight(uv, normals, p3, vec3(0., 0., sth));
    
    return l1 + l2 + l3 + amb;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy - .5) * vec2(RATIO, 1.) + .5;
    vec3 col = vec3(0.);
    float tm = time;
    
    float acc_frc = .0;
    vec2  acc_rot = vec2(0.);
    
    vec3 height    = getHeight(uv, acc_frc, acc_rot);
    vec3 normal1   = normalize(vec3(acc_rot, acc_frc * .01)).yxz;
    vec3 normal2   = getNormal(uv);
    vec3 normal    = normal1 + normal2 * 1.5;
    
    vec3 diffuse   = offsetLights(uv, normal);
    vec3 specular  = smoothstep(.8, .95, diffuse);
    vec3 material  = vec3(.2, .15, .05);
    vec3 light     = diffuse + specular + material;
    
    //col = light;
    //col = normal;
    col = light + sin(light * PI) - light; // To make it a bit more interesting
    
    glFragColor = vec4(col, 1.0);
}
