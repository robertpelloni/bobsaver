#version 420

// TwistedTorus.GLSL

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EDGES 6.0
#define VERTICES 5.0

#define MIN_DIST 0.001
#define MAX_STEPS 88
#define NORMAL_OFFS 0.003

#define ISOMETRIC 0
#define PERSPECTIVE 1
#define PROJECTION_MODE PERSPECTIVE

float tau = atan(1.0) * 8.0;
float vertexAngle = tau / VERTICES;
float edgeAngle   = tau / EDGES;

vec3 baseColor = vec3(2.0, 2.0, 1.6);

struct MarchInfo
{
    int id;
    vec3 position;
    vec3 normal;
    float depth;
    float steps;
};

struct Camera
{
    vec3 position;
    vec3 angles;
};
    
struct Ray
{
    vec3 origin;
    vec3 direction;    
};

mat3 Rotate(vec3 angles)
{
    vec3 c = cos(angles);
    vec3 s = sin(angles);
    
    mat3 rotX = mat3( 1.0, 0.0, 0.0, 0.0,c.x,s.x, 0.0,-s.x, c.x);
    mat3 rotY = mat3( c.y, 0.0,-s.y, 0.0,1.0,0.0, s.y, 0.0, c.y);
    mat3 rotZ = mat3( c.z, s.z, 0.0,-s.z,c.z,0.0, 0.0, 0.0, 1.0);

    return rotX * rotY * rotZ;
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

vec2 opS( vec2 d1, vec2 d2 )
{
    return (-d1.x > d2.x) ? d1*vec2(-1,1) : d2;
}

vec2 opI( vec2 d1, vec2 d2 )
{
    return (d1.x > d2.x) ? d1 : d2;
}

vec2 opRep(vec2 p,vec2 r)
{
    return mod(p + r,2.0 * r) - r;    
}

vec3 opRep(vec3 p,vec3 r)
{
    return mod(p + r,2.0 * r) - r;    
}

vec2 opN( vec2 d )
{
    return d * vec2(-1,1);
}

vec3 opAngRep( vec3 p, float a, float off)
{
    vec2 polar = vec2(atan(p.y, p.x), length(p.xy));
    polar.x = mod(polar.x + a / 2.0 + off, a) - a / 2.0;
    
    return vec3(polar.y * vec2(cos(polar.x),sin(polar.x)), p.z);
}

vec2 sdSphere(int id, vec3 p, float r)
{
    return vec2(length(p)-r, id);
}

vec2 sdPlane(int id, vec3 p, vec4 n)
{
  return vec2(dot(p, normalize(n.xyz)) + n.w, id);
}

vec2 Scene(vec3 p)
{
    vec2 ground = sdPlane(2, p, vec4(0,0,1.,0.5));
    vec3 dp = vec3(opRep(p.xy,vec2(.04)), p.z*.4);
    ground = opS(sdSphere(2, dp, 0.24),ground);
    
    float mr = sin(time)*0.1+0.25;
    vec3 arep = opAngRep(p, vertexAngle, 0.0);    
    arep = opAngRep(arep.xzy - vec3(mr,0,0), edgeAngle, time*-0.8 + atan(p.y,p.x));
    vec2 d = sdPlane(1, arep, vec4(1.0, 0.0, 0.0, -0.05));

    d = opU(d, ground);
    return d;
}

vec3 Normal(vec3 p)
{
    vec3 off = vec3(NORMAL_OFFS, 0, 0);
    return normalize( 
        vec3(Scene(p + off.xyz).x - Scene(p - off.xyz).x,
             Scene(p + off.zxy).x - Scene(p - off.zxy).x,
             Scene(p + off.yzx).x - Scene(p - off.yzx).x));
}

Ray CameraRay(Camera cam, vec2 uv, vec2 res)
{
    uv -= res/2.0;
    Ray r;
    mat3 rot = mat3(0);
    #if PROJECTION_MODE == PERSPECTIVE
      rot = Rotate(cam.angles);
      r.origin = cam.position;
      r.direction = normalize(vec3(uv.x, 1.0, uv.y)) * rot;
    #else
      rot = Rotate(vec3(atan(1.0,sqrt(2.0)), 0.0, cam.angles.z));
      r.origin = cam.position + vec3(uv.x,0.0,uv.y) * rot;
      r.direction = normalize(vec3(0.0, 1.0, 0.0)) * rot;
    #endif
    return r;
}

MarchInfo MarchRay(Ray r)
{    
    float dist = 0.0;
    float steps = 0.0;
    vec2 sc = vec2(0.0);
    for(int i = 0; i < MAX_STEPS; i++)
    {
        sc = Scene(r.origin + r.direction * dist);
        dist += sc.x;
        steps++;
        if(sc.x < MIN_DIST) break;
    }
    MarchInfo info;
    info.id = int(sc.y);
    info.position = r.origin + r.direction * dist;
    info.normal = Normal(info.position);
    info.depth = dist;
    info.steps = steps;
    return info;
}

vec3 Shade(MarchInfo info, Camera cam, Ray ray)
{
    vec3 col = vec3(0.2);
    
    if(info.id == 1) col = info.normal * 0.5 + 0.5;
    else if(info.id == 2) col = vec3(step(0.0, cos(info.position.x*tau*2.0) * cos(info.position.y*tau*2.0)) * 0.25 + 0.5);
    col *= 1.0 -(info.steps / float(MAX_STEPS));
    
    float falloff = 0.5 / pow(length(cam.position - info.position),2.0);
    float ambient = 0.0;
    float diffuse  = max(0.0, dot(info.normal,  normalize(cam.position - info.position)));
    float specular = max(0.0,-dot(reflect(ray.direction, info.normal), ray.direction));
    
    col *= baseColor * (ambient + (diffuse + 1.8*pow(specular,8.0)) * falloff);
    return col;
}

void main( void ) 
{
    vec2 aspect = resolution / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.y;
    vec3 angles = vec3(atan(1.0), 0.0, time * 0.25);
    Camera cam;
    cam.position = vec3(0,-1,0) * Rotate(angles);
    cam.angles = angles;
    
    Ray ray = CameraRay(cam, uv, aspect);
    MarchInfo info = MarchRay(ray);
    
    vec3 color = Shade(info, cam, ray);
    glFragColor = vec4( vec3( color ), 1.0 );
}
