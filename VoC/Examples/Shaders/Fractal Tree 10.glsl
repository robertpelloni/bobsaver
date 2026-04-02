#version 420

// original https://www.shadertoy.com/view/ttGfzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fractal Tree 01 - by moranzcw - 2021
// Email: moranzcw@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159265359
#define MaxDepth 8
#define MaxStackSize MaxDepth+1
#define Attenuation 0.8

float rand(float seed)
{ 
    return fract(sin(seed*(91.3458)) * 47453.5453);
}

struct Branch
{
    vec2 origin;
    vec2 direction;
    float len;
    int depth;
    float id;
};

Branch stack[MaxStackSize];
int top = 0;
float id = 0.0;

bool push(Branch branch)
{
    if(top < MaxStackSize)
    {
        stack[top] = branch;
        top += 1;
        return true;
    }
    return false;
}

bool pop(out Branch branch)
{
    if(top > 0)
    {
        top -= 1;
        branch = stack[top];
        return true;
    }
    return false;
}

vec3 line(vec2 coord, vec2 p1, vec2 p2, float width, vec3 color)
{
    vec2 v1 = coord - p1;
    vec2 v2 = p2 - p1;
    float j1 = dot(v1, v2);
    
    vec2 v3 = coord - p2;
    vec2 v4 = p1 - p2;
    float j2 = dot(v3, v4);
    
    float len;
    if( j1 > 0.0 && j2 > 0.0)
    {
        vec2 nv2 = normalize(v2);
        len = length(v1 - dot(v1, nv2) * nv2);
    }
    else
    {
        len = min(length(v1),length(v3));
    }
    return color * step(len, width);
}

vec2 rotate(vec2 v, float theta)
{
    vec2 v1;
    v1.x = v.x * cos(theta) - v.y * sin(theta);
    v1.y = v.y * cos(theta) + v.x * sin(theta);
    return v1;
}

vec3 tree(vec2 coord, Branch branch)
{
    push(branch);
    Branch cur;
    vec3 color;
    while(true)
    {
        if(pop(cur))
        {
            vec2 p = cur.origin + cur.direction * cur.len;
            vec3 shade = vec3(dot(cur.direction, vec2(0.7071,0.7071)) / 8.0 + 0.25);
            shade = line(coord, cur.origin, p, 0.005*pow(0.91, float(cur.depth)), shade);
            color = step(0.001,shade) * shade + (1.0 - step(0.001,shade)) * color;
            
            if(cur.depth < MaxDepth)
            {
                vec2 dir1 = rotate(cur.direction, PI/10.0 + 0.2*rand(cur.id*0.15) + 0.08*sin(time+cur.id));
                vec2 dir2 = rotate(cur.direction, -PI/10.0 - 0.16*rand(cur.id*0.35) + 0.08*sin(time-cur.id));
                bool flag;
                flag = push(Branch(p, dir1, cur.len * (Attenuation - 0.05*rand(cur.id*0.36)), cur.depth+1,id++));
                flag = flag && push(Branch(p, dir2, cur.len * (Attenuation- 0.05*rand(cur.id*0.69)), cur.depth+1, id++));
                if(!flag)
                    break;
            }
            else
            {
                float ir = dot(cur.direction, vec2(0.7071,0.7071)) / 4.0 + 0.5;
                float t = 0.4 + (sin(5.0*time + cur.id)+1.0) * 0.3;
                color += smoothstep(0.03, 0.01, length(coord-p)) * vec3(0.6,0.4,0.4) * ir * t;
            }
        }
        else
            break;
    }
    return color;
}

void main(void)
{  
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 coord = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec3 color = vec3(0.43,0.4,0.4);
    Branch branch = Branch(vec2(0.0,-0.7), vec2(0.0, 1.0), 0.35, 0, id++);
    color += tree(coord, branch);
    glFragColor = vec4(color,1.0);
}
