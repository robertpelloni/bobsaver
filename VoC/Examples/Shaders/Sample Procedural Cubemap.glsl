#version 420

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//#define USE_MOUSE
#define ANIMATE

#define PI            3.14159265359
#define RADIAN        180.0 / PI
#define CAMERA_FOV    60.4 * RADIAN

float hash(in vec3 p)
{
    return fract(sin(dot(p,vec3(127.1,311.7, 321.4)))*43758.5453123);
}

float noise(in vec3 p)
{
#ifdef ANIMATE
    p.z += time * 0.75;
#endif
    
    vec3 i = floor(p);
    vec3 f = fract(p); 
    f *= f * (3.0-2.0*f);

    return mix(
        mix(mix(hash(i + vec3(0.,0.,0.)), hash(i + vec3(1.,0.,0.)),f.x),
            mix(hash(i + vec3(0.,1.,0.)), hash(i + vec3(1.,1.,0.)),f.x),
            f.y),
        mix(mix(hash(i + vec3(0.,0.,1.)), hash(i + vec3(1.,0.,1.)),f.x),
            mix(hash(i + vec3(0.,1.,1.)), hash(i + vec3(1.,1.,1.)),f.x),
            f.y),
        f.z);
}

float fbm(in vec3 p)
{
    float f = 0.0;
    f += 0.50000 * noise(1.0 * p);
    f += 0.25000 * noise(2.0 * p);
    f += 0.12500 * noise(4.0 * p);
    f += 0.06250 * noise(8.0 * p);
    return f;
}

struct Camera    { vec3 p, t, u; };
struct Ray        { vec3 o, d; };

void generate_ray(Camera c, out Ray r)
{
    float ratio = resolution.x / resolution.y;

    vec2  uv = (2.0 * gl_FragCoord.xy / resolution.xy - 1.0)
             * vec2(ratio, 1.0);
    
    r.o = c.p;
    r.d = normalize(vec3(uv.x, uv.y, 1.0 / tan(CAMERA_FOV * 0.5)));
    
    vec3 cd = c.t - c.p;

    vec3 rx,ry,rz;
    rz = normalize(cd);
    rx = normalize(cross(rz, c.u));
    ry = normalize(cross(rx, rz));
    
    mat3 tmat = mat3(rx.x, rx.y, rx.z,
                       ry.x, ry.y, ry.z,
                     rz.x, rz.y, rz.z);

    r.d = normalize(tmat * r.d);
}

vec3 cubemap(vec3 d, vec3 c1, vec3 c2)
{
    return fbm(d) * mix(c1, c2, d * .5 + .5);
}

void main(void)
{
    Camera c;
    c.p = vec3(0.0, 0.0,  0.0);
    c.u = vec3(0.0, 1.0,  0.0);

#ifdef USE_MOUSE
    c.t = vec3(mouse.x / resolution.x * 20.0 - 10.0, 
               1.0 + 30.0 * mouse.y / resolution.y, -15.0);
#else
    c.t = vec3( 26.0 * sin(mod(time * 0.64, 2.0 * PI)),
                28.0 * cos(mod(time * 0.43, 2.0 * PI)),
               -25.0 * cos(mod(time * 0.20, 2.0 * PI)));
#endif        

    Ray r;
    generate_ray(c, r);
    
    glFragColor = vec4(smoothstep(0.001, 3.5, time) *
        1.7 * cubemap(r.d,vec3(.5,.9,.1), vec3(.1,.1,.9)),1.0);
}
