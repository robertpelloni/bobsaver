#version 420

// original https://www.shadertoy.com/view/fttXWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of https://www.shadertoy.com/view/fl3XDs

#define RATIO resolution.x / resolution.y
#define POINTS 10
#define FORCE 2. // the larger the smaller the swirl
#define ROTATION 2.

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

// swirl uv at random point
vec2 swirl (vec2 uv, float seed, inout float acc_frc, inout vec2 acc_rot)
{
    float tm = time * .3;
    
    // point
    float n = n21(vec2(seed));
    vec2 pnt = vec2(.5) + vec2(cos(tm + n * 423.1), sin(tm + n * 254.3) * .5);

    // rotate point
    vec2  dif = uv - pnt;
    float dis = length(dif);
    float frc = smoothstep(.0, 1., exp(dis * -FORCE) * (cos(dis * 10.) * .5 + .5));
    float swl = frc * sin(tm + n * 624.8) * ROTATION; 
    vec2  rot = dif * rotate(swl);

    // for normal map
    acc_frc += frc;
    acc_rot += rot * frc; 

    // rotated uv
    return rot + pnt;
}

vec3 offsetLights (vec2 uv, vec3 normals)
{
    float tm  = time * 1.;
    float off = .3; // offset
    float sth = .8; // strength
    float amb = .3; // ambient
    float rad = 1.; // radius
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
      
    // reclusively swirl th uv
    float acc_frc = .0;
    vec2  acc_rot = vec2(0.);
    vec2  sv = uv;
    for (int i = 0; i < POINTS; i++)
        sv = swirl(sv, fract(float(i+1) * 123.45), acc_frc, acc_rot);

    // normal map
    vec3 normal = normalize(vec3(acc_rot, acc_frc * .01));
    
    // light
    vec3 diffuse   = offsetLights(uv, normal);
    vec3 specular  = smoothstep(.85, .95, diffuse);
    vec3 light     = diffuse + specular;
    
    col = light;
    //col = normal;
    
    glFragColor = vec4(col,1.0);
}
