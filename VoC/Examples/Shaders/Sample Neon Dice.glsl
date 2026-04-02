#version 420

// original https://www.shadertoy.com/view/MsVyWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DL(vec3 ro, vec3 rd, vec3 p) 
{
    return length(cross(p - ro, rd)) / length(rd);
}

float DP(vec3 ro, vec3 rd, vec3 p)
{
    float d = DL(ro, rd, p);
    d = smoothstep(.06, .05, d);
    return d;
}

float s(vec3 ro, vec3 rd, vec3 p, float a, float b)
{
    float d = DL(ro, rd, p);
    d = smoothstep(a, b, d);
    return d;
}

void main(void)
{
    float t = time;
    
    vec2 uv = (gl_FragCoord.xy -.5 * resolution.xy) / resolution.y;
    
    vec3 ro = vec3(3. * sin(t), 2., -3. * cos(t));
    
    vec3 lookat = vec3(.5);
    
    float zoom = 1.;
    
    vec3 f = normalize(lookat - ro);
    vec3 r = cross(vec3(0., 1., 0.), f);
    vec3 u = cross(f, r);
    
    vec3 c = ro + f * zoom;
    vec3 i = c + uv.x * r + uv.y * u;
    vec3 rd = i - ro;

    float d = 0.;
            
    for(float i = 1.; i <= 9.; i++)
    {
        float k = i / 10.;
    
        d += DP(ro, rd, vec3(0., 0.,  k));
        d += DP(ro, rd, vec3(0.,  k, 0.));
        d += DP(ro, rd, vec3(0.,  k, 1.));
        d += DP(ro, rd, vec3(0., 1.,  k));
        d += DP(ro, rd, vec3( k, 0., 0.));
        d += DP(ro, rd, vec3( k, 0., 1.));
        d += DP(ro, rd, vec3( k, 1., 0.));
        d += DP(ro, rd, vec3( k, 1., 1.));
        d += DP(ro, rd, vec3(1., 0.,  k));
        d += DP(ro, rd, vec3(1.,  k, 0.));
        d += DP(ro, rd, vec3(1.,  k, 1.));
        d += DP(ro, rd, vec3(1., 1.,  k));
    }
    
    for(int i = 0; i <= 1; i++)
    {        
        for (int k = 0; k <= 1; k++)
        {        
            for(int m = 0; m <= 1; m++)
            {
                d += DP(ro, rd, vec3( i, k, m));    
            }
        }        
    }
        
    float a = .075;
    float b = .070;
    
    // 1
    d += s(ro, rd, vec3(.5, .5, .0), a, b);
    
    // 2
    d += s(ro, rd, vec3(.0, .7, .7), a, b);
    d += s(ro, rd, vec3(.0, .3, .3), a, b);
    
    // 3
    d += s(ro, rd, vec3(.7, 0., .7), a, b);
    d += s(ro, rd, vec3(.3, 0., .3), a, b);
    d += s(ro, rd, vec3(.5, 0., .5), a, b);
    
    // 4
    d += s(ro, rd, vec3(.7, 1., .7), a, b);
    d += s(ro, rd, vec3(.3, 1., .3), a, b);
    d += s(ro, rd, vec3(.3, 1., .7), a, b);
    d += s(ro, rd, vec3(.7, 1., .3), a, b);
    
    // 5
    d += s(ro, rd, vec3(1., .5, .5), a, b);
    d += s(ro, rd, vec3(1., .7, .7), a, b);
    d += s(ro, rd, vec3(1., .3, .7), a, b);
    d += s(ro, rd, vec3(1., .7, .3), a, b);
    d += s(ro, rd, vec3(1., .3, .3), a, b);
    
    // 6
    d += s(ro, rd, vec3(.3, .3, 1.), a, b);
    d += s(ro, rd, vec3(.3, .5, 1.), a, b);
    d += s(ro, rd, vec3(.3, .7, 1.), a, b);
    d += s(ro, rd, vec3(.7, .3, 1.), a, b);
    d += s(ro, rd, vec3(.7, .5, 1.), a, b);
    d += s(ro, rd, vec3(.7, .7, 1.), a, b);
       
    glFragColor = vec4(d) * vec4(.5, 0., 1., 1.);
}
