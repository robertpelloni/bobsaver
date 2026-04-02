#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 textColor = vec3(1.0, 0.9, 0.8);
float sphere(vec3 pos, float size)
{
    return length(pos) - size;
}

float udRoundBox( vec3 p, vec3 b, float r )
{
    return length(max(abs(p)-b,0.0)) - r;
}

float dist(vec3 pos)
{
    return min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(
        min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(
        udRoundBox(pos - vec3(-4.59, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.),
        udRoundBox(pos - vec3(-3.60, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(3.51, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(4.48, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(4.77, -0.49, 0.00), vec3(0.32, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-4.30, -0.49, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-2.62, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(2.39, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(5.10, 0.00, 0.00), vec3(0.15, 0.36, 0.13), 0.)),
        udRoundBox(pos - vec3(-1.61, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(3.00, 0.14, 0.00), vec3(0.13, 0.31, 0.13), 0.)),
        udRoundBox(pos - vec3(4.77, 0.47, 0.00), vec3(0.32, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-0.15, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(1.91, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(0.33, -0.49, 0.00), vec3(0.53, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-0.99, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(2.84, -0.27, 0.00), vec3(0.13, 0.31, 0.13), 0.)),
        udRoundBox(pos - vec3(-2.32, -0.49, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-4.30, 0.00, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-1.32, 0.47, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(1.30, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(-4.30, 0.45, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-3.30, -0.49, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(0.77, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(2.68, -0.13, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(2.68, 0.47, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(0.30, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(1.59, 0.47, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(1.59, -0.49, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-1.32, -0.49, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(3.80, -0.49, 0.00), vec3(0.37, 0.12, 0.13), 0.)),
        udRoundBox(pos - vec3(-5.38, 0.00, 0.00), vec3(0.36, 0.16, 0.13), 0.)),
        udRoundBox(pos - vec3(-5.69, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.)),
        udRoundBox(pos - vec3(-5.09, 0.00, 0.00), vec3(0.13, 0.57, 0.13), 0.));
}

vec3 getNormal(vec3 p)
{
    float ep = 0.001;
    return normalize(vec3(
        dist(p + vec3(ep, 0, 0)) - dist(p - vec3(ep, 0, 0)),
        dist(p + vec3(0, ep, 0)) - dist(p - vec3(0, ep, 0)),
        dist(p + vec3(0, 0, ep)) - dist(p - vec3(0, 0, ep))
    ));
}

mat3 rotX(float angle)
{    float c=cos(angle),   s=sin(angle);
    return mat3(1.0,0.0,0.0, 0.0,c,-s, 0.0,s,c);   }

mat3 rotY(float angle)
{    float c=cos(angle),   s=sin(angle);
    return mat3(c,0.0,s, 0.0,1.0,0.0, -s,0.0,c);   }

mat3 rotZ(float angle)
{    float c=cos(angle),   s=sin(angle);
    return mat3(c,-s,0.0, s,c,0.0, 0.0,0.0,1.0);   }

void main(void) 
{
    vec2 tex = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.y;
    
    vec3 color = vec3(0, 0, 0);
    
    vec3 pos = vec3(0, 0, -12);  // camera
    pos.z += 2.0+sin(time);
    pos *= rotY(0.1*sin(time*2.0));
    pos *= rotX(0.3*sin(time));
    vec3 dir = normalize(vec3(tex, 1.0));
    
    for (int i = 0; i < 64; ++i)
    {
        float d = dist(pos);
        if (d < 0.001) 
        {
            vec3 normal = getNormal(pos);
            
            float light = max(0.1, dot(vec3(-0.5, 2.0, 0.0), normal));
            light += 0.5;
            color = light * textColor;
            break;
        }
        pos += dir * d;
    }
    glFragColor = vec4(color, 1.0);
}
