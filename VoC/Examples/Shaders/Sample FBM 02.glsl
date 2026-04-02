#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define noise(p1,p2) 0.2*sin(p1 * 2.0 + p2) * cos(0.5 -p1 * 7.0)

float fbm(vec2 n)
    {
    float total = -0.5, amplitude = 8.0;
    for (int i = 0; i < 3; i++)
        {
            
        total += noise(n.x, n.y) * amplitude;
        n += n;
        amplitude *= 0.3;
        }
    return total;
    }

void main( void ) 
    {
    
    const vec3 c1 = vec3(0.8, 0.5, 1.0);
    const vec3 c3 = vec3(0.8, 0.5, 0.4);
    const vec3 c5 = vec3(0);
    vec2 p = gl_FragCoord.xy * 12.0 /resolution.xy;
    float q = fbm(p*p/60.0 - vec2(1.0, time * 0.2));
    vec2 r = vec2(fbm(p + 2.0* q + time * 0.7 - p.x - p.y), fbm(p + q - vec2(0.5, time * 0.94)));
    vec3 c = mix(c1, c3, fbm(p + r * 0.7)) + mix(c3, c5, r.x) - mix(c1, c5, r.y);
    c=pow(c* cos(1.57 * gl_FragCoord.y / 600.0), vec3(1.0));    
    glFragColor = vec4(c, 0);
    }
