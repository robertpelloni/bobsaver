#version 420

// original https://www.shadertoy.com/view/wsffRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 smoothU(vec2 a, vec2 b, float r)
{
    vec2 u = max(vec2(r - a.x, r - b.x), vec2(0.));
    return vec2(max(r, min (a.x, b.x)) - length(u), (a.y+b.y) / 2.);
}

vec3 rep(vec3 pos, float sp)
{
    return mod(pos, sp) - .5*sp;
}

vec2 cylX(vec3 p, vec3 c, float matId)
{
    float sdf = length(p.yx - c.zx) - c.x;
    return vec2(sdf, matId);
}

vec2 cylY(vec3 p, vec3 c, float matId)
{
    float sdf = length(p.xz - c.xy) - c.z;
    return vec2(sdf, matId);
}

vec2 cylZ(vec3 p, vec3 c, float matId)
{
    float sdf = length(p.yz - c.yx) - c.y;
    return vec2(sdf, matId);
}

mat2 rot(float rad)
{
    return mat2(cos(rad), sin(rad), -sin(rad), cos(rad));
}

vec3 kif(vec3 p)
{    
    float t = time*.05 + 42.;
    
    for(int i = 0; i < 6; i++)
    {
        p.xy *= rot(.021*t);
        
        p = abs(p) + vec3(.02*cos(t*.21) + .31,
                          .03*sin(t*.27) + 8.35,
                          .04*sin(t*.37) + 120.37);
        
        p.yz *= rot(.013*t);
    }
    
    return p;
}

vec2 crs(vec3 p, vec3 c, float matId)
{
    vec2 cylx = cylX(p, c, matId);
    vec2 cyly = cylY(p, c, matId + 1.);
    vec2 cylz = cylZ(p, c, matId + 2.);
 
    float soft = .015;
    vec2 sdf = smoothU(cylx, cyly, soft);
    return smoothU(sdf, cylz, soft);
}

vec2 map(vec3 p)
{   
    p = 250. * sin(p/dot(p,p));
    p = kif(p);
    
    float t = -time*.2 - 42.;
    p = rep(p + t, 1.3);
    
    vec2 m = crs(p, vec3(.05), 1.);
    return m;
}

vec2 tr(vec3 ro, vec3 rd)
{
    float far = 50.;
    vec2 h,t= vec2(.75);
    for(int i = 0; i < 256; i++)
    {
        h = map(ro + rd*t.x);
        if(h.x < .01 || t.x > far)
            break;
        t.x += h.x;
        t.y = h.y;
      }
    if(t.x > far)
        t.y = 0.;
    return t;
}

void main(void)
{   
    vec3 ro = vec3(3.*sin(time*.25), -5.*cos(time*.25), 32.);
    
    vec3 camTarget = vec3(0.);
    vec3 up = vec3(0., 1., 0.);
    vec3 camDir = normalize(camTarget - ro);
    vec3 camRight = normalize(cross(up, ro));
    vec3 camUp = normalize(cross(camDir, camRight));
    vec3 lightPos1 = ro;
    vec3 lightPos2 = ro + 10.;
  
    vec2 screenPos = -1. + 2. * gl_FragCoord.xy / resolution.xy;
    screenPos.x *= resolution.x / resolution.y;

    vec3 rd = normalize(camRight*screenPos.x + camUp*screenPos.y + camDir);
  
    vec2 t = tr(ro, rd);

    if (t.y > 0.)
    {
        vec3 hit = ro + rd*t.x;
        vec3 lightDir = normalize(lightPos1 - hit);

        vec2 eps = vec2(0., .05);
        vec3 norm = normalize(map(hit).x - vec3(map(hit - eps.yxx).x,
                                                  map(hit - eps.xyx).x,
                                                  map(hit - eps.xxy).x));
        
        float diff = max(0., dot(lightDir, norm));
        float spec = pow(max(dot(rd, reflect(norm, lightDir)), 0.), 45.);

        vec3 col = vec3(0.);
        col += .2 * diff;
        col += vec3(1.) * spec;
        
        glFragColor = vec4(col, 1.);
    }
    else
    {
        vec3 wh = vec3(1.);
        glFragColor = vec4(.85); 
    }
}
