#version 420

// original https://www.shadertoy.com/view/Mt2fRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITERATIONS 128

#define RAY_T_MAX 1.e30
#define RAY_T_MIN .01
#define SPEED .5
#define TIME time*SPEED
#define PI 3.1415927
#define EPSILON .006
#define GAMMA 2.2

#define MOUSE (mouse*resolution.xy.xy/resolution.xy)*2.-1.
#define MODE 1

#if (MODE == 0)
    #define C MOUSE
#elif (MODE == 1)
    #define CR -.181
    #define CI .667
    #define C vec2(CR, CI)
#endif

// Polynomial smooth minimum by iq
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

mat4 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(c, 0, s, 0),
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1)
    );
}

int julia (vec2 uv, vec2 c, float n, int maxIter)
{   
    int i = 0;
    float a = uv.x, b = uv.y;
    while(i<maxIter && a*a+b*b<4.)
    {   
        float tmpa = pow((a*a+b*b),(n/2.))*cos(n*atan(b, a)) + c.x;
        b = pow((a*a+b*b),(n/2.))*sin(n*atan(b, a)) + c.y;
        a = tmpa;
        i++;
    }
    return i;
}

struct camera
{
    vec3 center, forward, up, right;
    float w, h, fov, aspect;
};

void initCamera(inout camera cam, in vec3 center, in vec3 forward, in vec3 up, in float fov, in float aspect) 
{
    cam.center = center;
    cam.forward = forward;
    cam.up = up;
    cam.right = cross(cam.forward, cam.up);
    cam.fov = fov;
    cam.aspect = aspect;
    cam.w = tan(cam.fov);
    cam.h = cam.w * cam.aspect;
}

struct material
{
    vec3 ambiant, diffuse, specular;
    float shininess; // a >> 1.
};
  
struct light
{
    vec3 center;
    float power;    
};

vec3 blinn_phong (vec3 L, vec3 N, vec3 V, light l, float dist, material m)
{
    vec3 ambiant = m.ambiant;
    vec3 diffuse = m.diffuse*dot(L, N);
    vec3 H = normalize(L + V);
    float specAngle = max(dot(N, H), 0.);
    vec3 specular = m.specular*pow(specAngle, m.shininess);
    float power = l.power/dist;
    return ambiant*power + diffuse*power + specular*power;
    
}

struct sphere
{
    vec3 center;
    float radius;
};

float sphereSDF(vec3 p, sphere s)
{
    return distance(p, s.center)-s.radius;
}
    
struct cylinder
{
    vec3 base;
       float height;
};

float cylinderSDF(vec3 p, float h)
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float opScaleCylinder(vec3 p, float s, cylinder c)
{
    return cylinderSDF(p/s, c.height)*s;
}

float opU(float d0, float d1)
{
    return min(d0, d1);
}

struct point
{
    material m;
    float r;
};

point sceneSDF(vec3 p, bool mcalc)
{
    sphere s = sphere(vec3(0,-.25,0), 1.5);
    cylinder c = cylinder(vec3(0,s.radius,0)+s.center, .2);

    float scl = .4;
    float amp = .015;
    vec2 offset = vec2(.4, -.1);
    float j = float(julia(scl*s.center.xy-(scl*p.xy)+offset, C, 2., 128))/float(128);
    
    float d0 = 0.;
    vec3 cyPoint = p-c.base;
    float cyScale = 1.5;
    cyPoint.y -= c.height;
    
    //d0 = mix(0., 1., cyPoint.y);  
    
    material m;
    if (mcalc)
    {
        material m0 = material(vec3(.3,0,0), vec3(.7,0,0), vec3(1,.7,.7), 10.);
        material m1 = material(vec3(.4), vec3(.7), vec3(1.), 5.);
        material m2 = material(vec3(.05, .05,.09), vec3(.39,.36,.5), vec3(0.9, 0.9, .97), .7);
        m.ambiant = mix( mix(m0.ambiant, m1.ambiant, d0), m2.ambiant, j );
        m.diffuse = mix( mix(m0.diffuse, m1.diffuse, d0), m2.diffuse, j);
        m.specular = mix( mix(m0.specular, m1.specular, d0), m2.specular, j);
        m.shininess = mix( mix(m0.shininess, m1.shininess, d0), m2.shininess, j);
    }
     
    float d1 = smin(sphereSDF(p, s), cyScale*cylinderSDF(cyPoint/cyScale, c.height) - d0*.2, .2);
    float d2 = amp*j;
    float d = d1 - d2;
    return point(m, d);
}

vec3 estimateNormal(vec3 p)
{
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z), false).r - sceneSDF(vec3(p.x - EPSILON, p.y, p.z), false).r,
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z), false).r - sceneSDF(vec3(p.x, p.y - EPSILON, p.z), false).r,
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON), false).r - sceneSDF(vec3(p.x, p.y, p.z - EPSILON), false).r
    ));
}

float trace(vec3 p, vec3 d)
{
    float t = RAY_T_MIN;
    int i = 0;
    while(t<RAY_T_MAX && i<MAX_ITERATIONS)
    {
        float r = sceneSDF(p + d*t, false).r;
        if (r<RAY_T_MIN)
        {
            break;
        }
        t += r;
        i++;
    }
    if (i==MAX_ITERATIONS || t>RAY_T_MAX)
    {
           return RAY_T_MAX;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = uv*2.-1.;
    camera cam;
    initCamera(cam, vec3(0,0,4.), vec3(0,0,-1), vec3(0,1,0), PI/4., resolution.y/resolution.x);
    
    vec3 lightPos = vec3(inverse(rotateY(sin(TIME))) * vec4(vec3(0,1.5,cam.center.z), 1.));
    light l = light(lightPos, 2.2);
    
    // d => ray direction, P => point of intersection
    vec3 d = normalize(cam.forward + p.x * cam.w * cam.right + p.y * cam.h * cam.up);
    float t = trace(cam.center, d);
    
    vec3 col = vec3(1);
    if (t < RAY_T_MAX)
    {
        vec3 P = cam.center + (d*t);
        vec3 L = l.center - P;
        float dist = length(L);
        L = normalize(L);
        vec3 N = estimateNormal(P);
        
        //vec3 col = vec3(1./t);
        //vec3 col = texture(iChannel0, uv).xyz;
        //col+=vec3(N/2. + .5);
        col = blinn_phong(L, N, -d, l, dist, sceneSDF(P, true).m);
        col *= pow(col,vec3(1./GAMMA));
    }
    
    
    glFragColor = vec4(col, 1.);
    //glFragColor = texture(iChannel0, uv);
}
