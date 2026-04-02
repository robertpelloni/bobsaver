#version 420

// original https://www.shadertoy.com/view/3dfcz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = acos(-1.);
float glo = 0.;

mat2 rot (float rad)
{
    return mat2(cos(rad), sin(rad), -sin(rad), cos(rad));
}

vec2 hexPris(vec3 p, vec2 h, float matId)
{
    const vec3 k = vec3(-.8660254, .5, .57735);
    p = abs(p);
    p.xy -= 2.*min(dot(k.xy, p.xy), 0.)*k.xy;
    vec2 d = vec2(length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x), p.z - h.y);
    return vec2(min(max(d.x,d.y), 0.) + length(max(d, 0.)), matId);
}

vec3 kif(vec3 p)
{
    for(int i = 0; i < 6; i++)
    {
        p = abs(p) - vec3(.05*cos((time + 69.)*.41) + .4,
                          .05*sin((time + 280.)*.43) + .45,
                          .05*sin((time + 143.)*.45) + .4);
        p.xz *= rot(.06*(time - 490.));
        p.zy *= rot(.05*(time + 978.));
        p.xy *= rot(.04*(time + 108.));
    }
    
    return p;
}

vec2 map(vec3 p)
{   
    p = kif(p);
    vec2 m1 = hexPris(p, vec2(.03, 7.), 1.);
    p.x -= .04;
    vec2 m2 = hexPris(p, vec2(.01, 7.), 2.);
    vec2 m = m1.x < m2.x ? m1 : m2;
    glo += .1 / (.1 + m.x*m.x*m.x*2500.);
    return m;
}

vec2 tr(vec3 ro, vec3 rd)
{
    vec2 h,t= vec2(.001);
    for(int i = 0; i < 384; i++)
    {
        h = map(ro + rd*t.x);
        if(h.x < .000001 || t.x > 40.)
            break;
        t.x += h.x;
        t.y = h.y;
      }
    if(t.x > 40.)
        t.y = 0.;
    return t;
}

void main(void)
{
    vec3 ro = vec3(1.5*cos(-.3*time),
                   1.5*sin(-.3*time),
                   -3.5);
    vec3 camTarget = vec3(0.);
    vec3 up = vec3(0., 1., 0.);
    vec3 camDir = normalize(camTarget - ro);
    vec3 camRight = normalize(cross(up, ro));
    vec3 camUp = normalize(cross(camDir, camRight));
    vec3 lightPos = vec3(2., 2., -15.);
  
    vec2 screenPos = -1. + 2. * gl_FragCoord.xy / resolution.xy;
    screenPos.x *= resolution.x / resolution.y;

    vec2 eps = vec2(0., .05);
    vec3 rd = normalize(camRight*screenPos.x + camUp*screenPos.y + camDir);
  
    vec2 t = tr(ro, rd);

    vec3 colRot = vec3(sin(.317*(time + 44.)),
                       sin(.151*(time + 55.)),
                       sin(.227*(time + 79.))) + 1.3;

    if (t.x < 120.)
    {
        vec3 hit = ro + rd*t.x;
        vec3 lightDir = normalize(lightPos - hit);
        
        vec3 norm = normalize(map(hit).x - vec3(map(hit - eps.yxx).x,
                              map(hit - eps.xyx).x,
                              map(hit - eps.xxy).x));
        
        float diff = max(0., dot(lightDir, norm));
        float spec = pow(max(dot(rd, reflect(norm, lightDir)), 0.), 75.);
        float ao = clamp(map(t.x + norm*.5).x / .5, 0., 1.);

        vec3 col = .4 * colRot;
        col *= .1 * ao;
        col += .4 * diff * colRot.yzx;
        col += .8 * spec * vec3(1., 1., 1.);

        col += glo*.008*colRot.yxz;
        if(t.y == 2.)
            glFragColor = vec4(.95*col.zxy, 1.);
        else
            glFragColor = vec4(.95*col, 1.);
    }
    else
        glFragColor = vec4(glo*.008*colRot.zyx, 1.);
}
