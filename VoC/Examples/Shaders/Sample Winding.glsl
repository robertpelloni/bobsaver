#version 420

// original https://www.shadertoy.com/view/4sS3Rc

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;
 
vec4 quaternion(vec3 p, float a)
{
    return vec4(p*sin(a/2.0), cos(a/2.0));
}

vec3 qtransform(vec4 q, vec3 p)
{
    return p+2.0*cross(cross(p, q.xyz)-q.w*p, q.xyz);
}

vec2 hash2(float n)
{
    vec2 p = vec2(dot(vec2(n+11.22), vec2(127.1, 311.7)),
                  dot(vec2(n+33.44), vec2(269.5, 183.3)));
    return (2.0*fract(sin(p)*43758.5453)-1.0);
}

vec3 hash(float n)
{
    return vec3(8.0*hash2(n), n*20.0);
}

float sp(float p0, float p1, float p2, float p3, float t)
{
    return 0.5*(2.0*p1+(-p0+p2)*t+
        (2.0*p0-5.0*p1+4.0*p2-p3)*t*t+
        (-p0+3.0*p1-3.0*p2+p3)*t*t*t);
}

vec3 sp3(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t)
{
    return vec3(
        sp(p0.x, p1.x, p2.x, p3.x, t),
        sp(p0.y, p1.y, p2.y, p3.y, t),    
        sp(p0.z, p1.z, p2.z, p3.z, t));    
}

vec3 co(float t)
{
    float i = floor(t);
    vec3 p0 = hash(i-1.0);
    vec3 p1 = hash(i);
    vec3 p2 = hash(i+1.0);
    vec3 p3 = hash(i+2.0);
    return sp3(p0, p1, p2, p3, fract(t));    
}

float helix(vec3 p)
{
    float a = atan(p.y,p.x)*0.1;
    float b = mod(p.z,0.6283)-0.314159;
    a = abs(a-b);
    if (a>0.314159) a = 0.6283-a;
    return length(vec2(length(p.xy)-0.3, a))-0.2;
}

float helixBall(vec3 p)
{
    float a = atan(p.y,p.x)*0.1;
    float b = mod(p.z,0.6283)-0.314159;
    a = abs(a-b);
    if (a>0.314159) a = 0.6283-a;
    return length(vec2(length(p)-1.8, a))-0.15;
}

float de(vec3 p)
{
    p = mod(p-vec3(5.0),20.0)-10.0;
    vec4 q = quaternion(vec3(1.0,0.1,0.0), -time);
    p = qtransform(q, p);
    return helixBall(p);
}

float de2(vec3 p)
{
    vec3 p0 = p;
    p0.x = mod(p0.x,10.0)-5.0;
    p0.z = mod(p0.z,50.0)-10.0;
    vec3 p1 = p;
    p1.y = mod(p1.y,10.0)-5.0;
    p1.z = mod(p1.z,50.0)-10.0;
    return min(helix(p0.xzy), helix(p1.yzx));
}

vec2 map(vec3 p)    
{
    float d0 = de(p);
    float d1 = de2(p);
    float c = 0.0;
    if (d0 < d1) c = 1.0;
    float d = min(d0, d1);
    return vec2(d, c);    
}

vec3 calcNormal(vec3 p)
{
    vec3 eps = vec3(0.0001, 0.0, 0.0);
    vec3 nor = vec3(
        map(p+eps.xyy).x-map(p-eps.xyy).x,
        map(p+eps.yxy).x-map(p-eps.yxy).x,
        map(p+eps.yyx).x-map(p-eps.yyx).x);
    return normalize(nor);    
}

vec3 render(vec3 ro, vec3 rd)
{
    float t = 0.0;
    vec2 d;
    vec3 p = ro;
    for(int i = 0; i < 32; ++i)
    {
        d = map(p);
        t += d.x;
        p = ro+t*rd;
    }
    if(abs(d.x) < 0.001)
    {
        vec3 col = vec3(0.8, 1.0, 0.6);
        if (d.y < 1.0) col = vec3(1.0, 1.0, 0.0);
        vec3 nor = calcNormal(p);
        float c = dot(vec3(1.0), nor);
        return c*col;
    }else{
        return vec3(0.0,0.0,0.2);
    }
}

void main(void)
{
    float time2 = -0.5*time;
    vec2 p = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    vec3 rd = normalize(vec3(p, -1.5));
    vec3 ro = co(time2);
    vec3 target = co(time2-0.001);
    vec3 forward = vec3(0.0, 0.0, -1.0);
    vec3 diff = normalize(target-ro);
    vec3 axis = cross(forward, diff);
    float angle = acos(dot(forward, diff));
    vec4 q = quaternion(axis, angle);
    rd = qtransform(q, rd);
    glFragColor=vec4(render(ro, rd), 1.0);
}
