#version 420

// original https://www.shadertoy.com/view/XlXSDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 Direction(vec2 tex, vec2 res, vec2 fov)
{
    return normalize(vec3((2.0 * vec2(tex.x, tex.y) - 1.0) * fov, 1));
}

vec2 Add(vec2 d1, vec2 d2)
{
    return (d1.x < d2.x) ? d1 : d2;
}
float Plane(vec3 p, vec4 n )
{
  return dot(p,normalize(n.xyz)) + n.w;
}
float Sphere(vec3 p, float r)
{
    return length(p) - r;
}

float Box(vec3 p, vec3 b)
{
  return length(max(abs(p)-b,0.0));
}

float RoundBox(vec3 p, vec3 b, float r)
{
  return length(max(abs(p)-b,0.0)) - r;
}

mat4 RotX(float th)
{
    return mat4(1.0,0.0,0.0,0.0,0.0,cos(th),-sin(th),0.0, 0.0, sin(th), cos(th), 0.0, 0.0, 0.0, 0.0, 1.0);
}

mat4 RotY(float th)
{
    return mat4(cos(th), 0.0, sin(th), 0.0, 0.0, 1.0, 0.0, 0.0, -sin(th), 0.0, cos(th), 0.0, 0.0, 0.0, 0.0, 0.0);
}

vec3 RotatingLight(float s)
{
    vec3 p = vec3(15,0,0);
    p = (RotY(s * time) * vec4(p,1)).xyz;
    p += vec3(0,6,0);
    return p; 
}

vec2 Scene(vec3 p)
{
    vec2 rb = vec2(RoundBox(p-vec3(0,0,0), vec3(3,3,3), 1.2), 0.0);
    vec2 sph = vec2(Sphere(p-vec3(-4,4,-4), 1.0), 0.0);
    vec2 sph1 = vec2(Sphere(p-vec3(-4,4,4), 1.0), 0.0);
    vec2 sph2 = vec2(Sphere(p-vec3(4,4,4), 1.0), 0.0);
    vec2 sph3 = vec2(Sphere(p-vec3(4,4,-4), 1.0), 0.0);
    vec2 sph4 = vec2(Sphere(p-vec3(0,4,0), 1.0), 0.0);
    vec2 sph5 = vec2(Sphere(p-RotatingLight(1.0), 0.25), 0.5);
    vec2 sph6 = vec2(Sphere(p-RotatingLight(2.0), 0.25), 0.5);
    vec2 sph7 = vec2(Sphere(p-RotatingLight(3.0), 0.25), 0.5);
    vec2 sph8 = vec2(Sphere(p-RotatingLight(4.0), 0.25), 0.5);
    vec2 pl = vec2(Plane(p, vec4(0,1,0,4)), 0.0);
    return Add(Add(Add(Add(Add(Add(Add(Add(Add(Add(rb, sph), sph1), sph2), sph3), sph4), sph5), sph6), sph7), sph8), pl);
}

vec2 March(vec3 o, vec3 d)
{
    float t = 1.0; // Near plane.
    float f = 100.0;
    float m = -1.0;

    for (int i=0; i < 256; ++i)
    {
        vec2 v = Scene(o + d * t);

        if (v.x <= .0002)
            break;

        t += v.x;
        m = v.y;
    }
    if (t>f)
        m = -1.0;
    return vec2(t, m); 
}
vec3 CalculateNormal(vec3 pos)
{
    vec3 e = vec3(0.001,0,0);
    vec3 n = vec3(
        Scene(pos+e.xyy).x - Scene(pos-e.xyy).x,
        Scene(pos+e.yxy).x - Scene(pos-e.yxy).x,
        Scene(pos+e.yyx).x - Scene(pos-e.yyx).x);
    return normalize(n);
}

vec4 Phong(vec3 p, vec3 lp, vec3 v, vec4 diff)
{
    vec3 l = normalize(lp - p);
    vec3 n = CalculateNormal(p);
    float ndl = clamp(dot(n,l), 0.0, 1.0);
    vec4 d = mix(vec4(0.0,0.0,0.0,0.0), diff, ndl);
    vec3 r = reflect(v, n);
    float rdl = pow(clamp(dot(r, l), 0.0, 1.0), 32.0);

    vec4 s = mix(vec4(0.0,0.0,0.0,0.0), vec4(1.0,1.0,1.0,1.0), rdl);

    return d + s;
}

vec4 RenderScene(vec3 ro, vec3 rd)
{
    vec2 res = March(ro, rd);
    vec4 c = vec4(0,0,0,1);

    // PHONG
    if (res.y == 0.0)
    {
        vec3 pos = ro + rd * res.x;
        vec3 lp = RotatingLight(1.0);        
        vec3 lp2 = RotatingLight(2.0);        
        vec3 lp3 = RotatingLight(3.0);        
        vec3 lp4 = RotatingLight(4.0);        
        
        c = Phong(pos, lp, rd, vec4(0.0,1.0,0.0,1.0));
        c += Phong(pos, lp2, rd, vec4(1.0,0.0,0.0,1.0));
        c += Phong(pos, lp3, rd, vec4(0.0,1.0,0.0,1.0));
        c += Phong(pos, lp4, rd, vec4(0.0,0.0,1.0,1.0));
    }
    else if (res.y == 0.5 )
    {
        c = vec4(1,1,1,1);
    }
    return c;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 ro = vec3(0,20,-20);
    float aspect = resolution.y / resolution.x;
    float hFOV = 3.1415/4.0;
    
    vec3 rd = Direction(uv, resolution.xy, vec2(hFOV, aspect * hFOV));
    rd = (RotX(-3.1415/4.0) * vec4(rd,1)).xyz;
    
    glFragColor = RenderScene(ro, rd);
}
