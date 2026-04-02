#version 420

// original https://www.shadertoy.com/view/3dfyRX

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

vec2 box(vec3 p, vec3 b, float matId)
{
    vec3 q = abs(p) - b;
    return vec2(length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.), matId);
}

vec3 kif1(vec3 p)
{
    float t = time + 35.;
    
    for(int i = 0; i < 6; i++)
    {
        p.xy *= rot(.063*t);
        
        p = abs(p) - vec3(.05*cos(t*.21) + .31,
                          .05*sin(t*.27) + .35,
                          .05*sin(t*.37) + .37);
        
        p.yz *= rot(.043*t);
    }
    
    return p;
}

vec2 add(vec2 m1, vec2 m2)
{
    return m1.x < m2.x ? m1 : m2;
}

vec2 map(vec3 p)
{   
    p = kif1(p);
    
    vec2 m1 = box(p, vec3(.08, .8, 1.), 1.);
    p.x -= .20;
    vec2 m2 = box(p, vec3(.06, .75, .85), 2.);
    p.x += .40;
    vec2 m3 = box(p, vec3(.06, .75, .85), 2.);
    vec2 m = add(m1, m2);
    m = add(m, m3);
    glo += .1 / (.1 + m1.x*m1.x*m1.x*2500.);
    return m;
}

vec2 tr(vec3 ro, vec3 rd)
{
    vec2 h,t= vec2(.01);
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
    vec3 ro = vec3(.5*cos(-.1*time),
                   .5*sin(-.1*time),
                   -7.);
    vec3 camTarget = vec3(0.);
    vec3 up = vec3(0., 1., 0.);
    vec3 camDir = normalize(camTarget - ro);
    vec3 camRight = normalize(cross(up, ro));
    vec3 camUp = normalize(cross(camDir, camRight));
    vec3 lightPos = vec3(.5, 1.5, -15.);
  
    vec2 screenPos = -1. + 2. * gl_FragCoord.xy / resolution.xy;
    screenPos.x *= resolution.x / resolution.y;

    vec2 eps = vec2(0., .001);
    vec3 rd = normalize(camRight*screenPos.x + camUp*screenPos.y + camDir);
  
    vec2 t = tr(ro, rd);

    vec3 colRot = vec3(sin(.317*(time + 44.)),
                       sin(.151*(time + 55.)),
                       sin(.227*(time + 79.))) + 1.25;

    if (t.x < 120.)
    {
        vec3 hit = ro + rd*t.x;
        vec3 lightDir = normalize(lightPos - hit);
        
        vec3 norm = normalize(map(hit).x - vec3(map(hit - eps.yxx).x,
                                                  map(hit - eps.xyx).x,
                                                  map(hit - eps.xxy).x));
        
        float diff = max(0., dot(lightDir, norm));
        float spec = pow(max(dot(rd, reflect(norm, lightDir)), 0.), 85.);
        float ao = clamp(map(t.x + norm*.5).x / .5, 0., 1.);

        vec3 col = .25 * colRot;
        if(t.y == 2.)
            colRot = vec3(.2);
        else if(t.y == 3.)
            colRot = vec3(.8);
        
        col *= .12 * ao;
        col += .5 * diff * colRot.yzx;
        col += 1. * spec * vec3(1., 1., 1.);
        col += glo*.0085*colRot;
        
        glFragColor = vec4(col, 1.);
    }
    else
        glFragColor = vec4(glo*.0085*colRot.zyx, 1.);
}
