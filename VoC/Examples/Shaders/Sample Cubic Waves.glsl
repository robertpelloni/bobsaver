#version 420

// original https://www.shadertoy.com/view/fdd3Wj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float f)
{
    float c = cos(f), s = sin(f);
    return mat2(c ,-s,s,c);
}

float box(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q,0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}
float scene(vec3 p) 
{
    float oz = p.z;
    
    p.z = mod(p.z + 1., 1.) - 1.;
    float res = 1000.;
    
    for(int i = 0; i < 20; i++)
    {
        float offset = time +  float(i) + oz ;
        vec3 rotp = p;
        rotp.xy *= rot(time*0.5 + float(i) - oz );
        //rotp.xz *= rot (time + oz) * 0.001;
        res  = min( res, box(rotp - vec3(sin(offset) , cos(offset), 0),vec3(0.45 *abs(sin(time - sin(float(i) * 0.05) * 2.) + cos(time *0.55) *0.5)))); 
    }
    return res;
}

vec4 ray(vec3 ro, vec3 rd)
{
    float dist = 0., closest = 255.;
    for(int i = 0; i < 255; i ++)
    {
        vec3 pos = ro + rd * dist;
        float len = scene(pos);
        
        dist += len;
        closest = min(len, closest);
        
        if ( len < 0.001 || dist > 100.)
            break;
    }
    return vec4(ro + rd * dist, dist);
}

vec3 norm(vec3 p)
{
    vec2 eps = vec2(0.01, 0);
    return normalize(scene(p) - vec3(scene(p - eps.xyy) , scene(p - eps.yxy), scene(p - eps.yyx)));
}

vec4 color(vec4 res, vec3 lp, vec2 u)
{
    vec3 n = norm(res.xyz), p = res.xyz;
    vec3 ldir = lp - p, nldir = normalize(ldir);

    vec3 amb = vec3(0, .5, 1) * u.x;
        
    if(res.w > 12.) 
     return vec4(amb , 1.);
     
    vec3 diff = vec3(0.7, .4, 1) * dot(nldir, n);
    
    vec3 glow = vec3(0, .3, 0) * (1.- res.w/10.);
    vec3 color = clamp(diff, 0.,1.) + clamp(amb,0.,1.) * 0.1;
    
    color = mix(color, amb, res.w/10.);
    return vec4(color , 1); //vec4(dot(n, normalize(ldir))) * (1/(1 + dot(ldir, ldir)));
}

void main(void)
{
    vec2 r = resolution.xy, u = (2. *  gl_FragCoord.xy - r)/r.y; 
    
    vec3 ro = vec3(0, 0, -10. + time * 0.2), rd = normalize(vec3(u, 2.));
    
    glFragColor = color(ray(ro,rd), ro, u + 2.);
}
