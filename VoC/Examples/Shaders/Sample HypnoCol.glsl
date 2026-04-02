#version 420

// original https://www.shadertoy.com/view/MsVcWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a, b, t) smoothstep(a, b, t)

struct ray
{
    vec3 origin;
    vec3 direction;
};

ray GetRay(vec2 uv, vec3 campos, vec3 lookat, float zoom)
{
    ray a;
    a.origin = campos;
    vec3 forward = normalize(lookat-campos);
    vec3 right = cross(vec3(0.,1.,0.), forward);
    vec3 up = cross(forward, right);
    vec3 center = a.origin + forward * zoom;
    vec3 intersectionPoint = center + uv.x * right + uv.y * up;
    
    a.direction = normalize(intersectionPoint-a.origin);
    
    return a;
}

vec3 ClosestPoint(ray r, vec3 p)
{
    return r.origin + max(0., dot(p-r.origin, r.direction))*r.direction;
}

float DistRay(ray r, vec3 p)
{
    return length(p-ClosestPoint(r, p));
}

float Ring(ray r, vec3 p, float size, float blur)
{
    
    float d = DistRay(r, p);
    
    float c = S(size, size*(1.-blur), d);
    c *= S(size*.8, size*.99, d);
    return c;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;    
    uv.x *= resolution.x/resolution.y;
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse -= 0.5;
    
    vec3 camPos = vec3(0, .2, 0);
    vec3 lookat = vec3(0, .2, 1.);
    
    float circleMoveSize = 0.02;
    float circleMoveSpeed = time * 2.0;
    
    lookat.x += sin(circleMoveSpeed) * circleMoveSize;
    lookat.y += cos(circleMoveSpeed) * circleMoveSize;
    
    camPos.x += cos(time) * .2;
    camPos.y += cos(time + 5.) * .1;

    float speed = .05;
    float t = time * speed;
    float s = 1./100.;
    ray r = GetRay(uv, camPos, lookat, 2.);
    float m = 0.;
    
    for(float i=0.; i<1.; i+=s)
    {    
        float ti = fract(t+i);
        float z = 100.-ti*100.;
        float fade =  ti * ti * ti * ti;
        float focus = S(.8, 1., ti);
        vec3 p = vec3(mouse.x, mouse.y, z);    
        float size = mix(1.5, 10., focus * .02);         
        m += Ring(r, p, size, .05) * fade;                    
    }
    
    float bgRing = S(0.95, .01, length(uv));     
    vec3 bg = vec3(1., .9, .9) * bgRing;        
    vec3 mask = (bg * .2) + m;
        
    vec3 col = 0.5 + 0.5 * sin(time-uv.xyx+vec3(2,4,0));
    vec3 col2 = vec3(0.8, .85, .86);    
    col = mix(col, col2, mask);
    col *= mask;
    
    glFragColor = vec4(col, 1.);
}
