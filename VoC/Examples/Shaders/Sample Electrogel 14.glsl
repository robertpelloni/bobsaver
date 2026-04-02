#version 420

// original https://www.shadertoy.com/view/WsfcWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = acos(-1.);
float glo = 0.;

float smAdd(float m1, float m2, float k)
{
    float h = clamp(.5 + .5*(m2 - m1)/k, 0., 1.);
    return mix(m2, m1, h) - k*h*(1. - h);
}

float bump(vec3 p, float offs)
{
    return .25*sin(p.x*3.4 + (time + offs)*.73) *
               cos(p.y*3.7 + (time + offs)*.81) *
              (sin(p.z*4.0 + (time + offs)*.83) + cos(p.z*2.9 + (time + offs)*.57));
}

vec2 sph(vec3 p, float s, float offs, float matId)
{
    return vec2(length(p + bump(p, offs)) - s, matId);
}

vec2 map(vec3 p)
{   
    float dist = 1.1*sin(time*.7) + 3.;
    vec2 m1 = sph(vec3(p.x + dist/2., p.y, p.z), 1.5, 133., 0.);
    vec2 m2 = sph(vec3(p.x - dist/2., p.y, p.z), 1.5, 0., 1.);
    float matmix = mix(0., 1., abs(m2.x - m1.x));
    vec2 m = vec2(smAdd(m1.x, m2.x, .6), matmix);
    glo += .1 / (1.5 + m.x*m.x*5000.);
    return m;
}

float sss(vec3 p, vec3 l, float d)
{
    return smoothstep(0., 1., map(p + l*d).x/d);
}

vec2 tr(vec3 ro, vec3 rd)
{
    float far = 10.;
    vec2 h,t= vec2(.01);
    for(int i = 0; i < 256; i++)
    {
        h = map(ro + rd*t.x);
        if(h.x < .0001 || t.x > far)
            break;
        t.x += h.x * .2;
        t.y = h.y;
      }
    if(t.x > far)
        t.y = -1.;
    return t;
}

void main(void)
{
    vec3 ro = vec3(cos(.15*time),
                   sin(-.15*time),
                   -3.5);
    vec3 camTarget = vec3(0.);
    vec3 up = vec3(0., 1., 0.);
    vec3 camDir = normalize(camTarget - ro);
    vec3 camRight = normalize(cross(up, ro));
    vec3 camUp = normalize(cross(camDir, camRight));
    vec3 lightPos = vec3(.07, .07, -10.);
  
    vec2 screenPos = -1. + 2. * gl_FragCoord.xy / resolution.xy;
    screenPos.x *= resolution.x / resolution.y;

    vec2 eps = vec2(0., .02);
    vec3 rd = normalize(camRight*screenPos.x + camUp*screenPos.y + camDir);
  
    vec2 t = tr(ro, rd);

    vec3 colRot = .7 * vec3(sin(.151*((time+180.) + 44.)),
                               sin(.227*((time+180.) + 55.)),
                               sin(.317*((time+180.) + 79.))) + 1.2;

    if (t.y > -1.)
    {
        vec3 hit = ro + rd*t.x;
        vec3 lightDir = normalize(lightPos - hit);
        
        vec3 norm = normalize(map(hit).x - vec3(map(hit - eps.yxx).x,
                                                  map(hit - eps.xyx).x,
                                                  map(hit - eps.xxy).x));

        vec3 l = -lightDir;
        float sub = 0.;
        float steps = 20.;

        for(float i = 1.; i < steps; i++)
        {
            float dist = i*5. / steps;
            sub += sss(hit, l, dist);
        }
        
        float diff = max(0., dot(lightDir, norm));
        float spec = pow(max(dot(rd, reflect(norm, lightDir)), 0.), 100.);
        float ao = clamp(map(t.x + norm*.5).x / .5, 0., 1.);

        vec3 col = .3 * colRot * (t.y + .3);
        col += sub * colRot.zxy * .35;
        col *= .15 * ao;
        col += .4 * diff * (colRot.yzx/(t.y*6.));
        col += .9 * spec * vec3(1., 1., 1.);
        
        col += glo*.01*colRot.xzy*(t.y);
        
        glFragColor = vec4(col, 1.);
    }
    else
        glFragColor = vec4(glo*.01*colRot.yzx*t.y, 1.);
}
