#version 420

// original https://www.shadertoy.com/view/ldsBDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p)
{    
    vec3 q = fract(p * 0.5) * 2.0 - 1.0;
    q.y = q.x * 0.5;
    
    return length(q) - 0.3;
}

float trace(vec3 origin, vec3 ray) 
{    
    float t = 0.0;
    for (int i = 0; i < 18; i++) {
        vec3 p = origin + ray * t;
        float d = map(p);
        t += d * 0.5;
    }
    return t;
}

void main(void)
{    
    vec2 uv = gl_FragCoord.xy / resolution.xy;    
    uv = uv * 2.0 - 1.0;
    
    // Aspect ratio.
    uv.x *= resolution.x / resolution.y;                        
    
    // RGB
    vec3 c;
    
    float s1 = sin(time * 0.5);
    
    // Compute RGB separately.
    for (int i = 0; i < 3; i++) {
        
        // Move origin.
        vec3 origin = vec3(0.0, 0.0, time);
        
        // Some kind of chromatic aberration.
        uv.x *= 0.97;
        uv.y *= 0.97;
        
        vec3 ray = normalize(vec3(uv, 0.5));
        
        // Spiral rotation (XY).
        float the = time + length(uv) * s1;
        ray.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
        
        // Normal rotation (XZ).
        the = time * 0.1;
        ray.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
                
        float t = trace(origin, ray);
        
        // Visualize depth.
        c[i] = 1.0 / (1.0 + t * t * 0.07);
    }    
       
        
    glFragColor = vec4(c, 1.0);
}
