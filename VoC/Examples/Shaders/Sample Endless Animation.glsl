#version 420

// original https://www.shadertoy.com/view/tdyBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1.
#define R resolution.xy
#define T time
#define Pi 3.141592

//#define BLEED

#define color vec3(.5, .7, 1)

struct mat
{
    float z; // depth
    vec3 c;  // color
    float a; // ao
    vec3 i;  // IL
};

vec3 camera(in vec2 p, in vec3 o, in vec3 t)
{
    vec3 w = normalize(o - t);
    vec3 u = normalize(cross(vec3(0, 1, 0), w));
    vec3 v = cross(w, u);
    return p.x * u + p.y * v - w;
}

float box(in vec3 p, in vec3 s, in float k)
{
    p = abs(p) - (s - k);
    return length(max(vec3(0), p)) - k;
}

mat2 rotate(in float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

float map(in float i , in float c, in float l, in float q)
{
    return 1. - 1. / (c + l * i + q * i * i);
}

// Cheap AO https://www.shadertoy.com/view/ttXfWX
// Cheap IL 1 bounce fake https://www.shadertoy.com/view/WtSfzh
mat Uop(in mat a, in mat b)
{
    float s = max(a.z, b.z);
    float ao = map(s, 1., 44.8, 115.2);
    return mat
        (
            min(a.z, b.z),
            a.z < b.z ? a.c : b.c, 
            clamp(a.a * ao, 0., 1.),
            a.i * mix(a.z > b.z ? a.c : b.c, vec3(1.), map(s, 1., 22.4, 57.6))
        );
}

#define STEPS 99
#define MIN_S .01
#define MAX_S 99.

mat scene(in vec3 p)
{
    // Inclined cubes
    vec3 q = p;
    float subSpace = sqrt(2.);
    float offsetZ = floor(q.x / subSpace) * 1.;
    q.x = mod(q.x, subSpace) - subSpace * .5;
    q.xy *= rotate(45. * Pi / 180.);
    q.z += offsetZ;
    
    mat b0 = mat(box(q, vec3(.5), .02), color, 1., vec3(1));

    q = p;
    q.x -= sqrt(2.) - .05;
    q.z -= .1;
    float offsetZ2 = floor(q.x / subSpace) * 1.;
    q.x = mod(q.x, subSpace) - subSpace * .5;
    float bA = box(q - vec3(-sqrt(2.)*.5+.1, -.05, -offsetZ2), vec3(.05, .05, .55), .0);
    
    q = p;
    q.x -= 1.52;
    float offsetZ3 = floor(q.x / subSpace) * 1.;
    q.x = mod(q.x, subSpace) - subSpace * .5;
    float bB = box(q - vec3(0, -.05, -offsetZ3 + sqrt(2.) * .5 - 1.1), vec3(sqrt(2.), .05, .05), .01);
    
    mat bAB = mat(min(bA, bB), vec3(1.5), 1., vec3(1));
    
    // Cube animation
    q = p;
    float time = T;
    float loop = mod(time, 1.);
    float rotateBox = pow(loop, 3.) * floor(mod(time + 1., 2.)); 
    float moveBoxX = floor((time + 1.) * .5);
      float z = floor(mod(T, 2.)) * loop;
    float moveBoxZ = floor(T * .5) + pow(z, 4.);
    float angle = rotateBox * Pi;
    q.xy -= vec2(sqrt(2.) * moveBoxX - subSpace * .5, sqrt(2.) * .5);
    q.z -= 1. - moveBoxZ;
    q.xy *= rotate(-angle);
    q.x += sqrt(2.) * .5;
    q.xy *= rotate(45. * Pi / 180.);
     
    mat b1 = mat(box(q, vec3(.5), .0), vec3(1.5), 1., vec3(1));
    
    // Ground
    q = p;
    mat f = mat(q.y + .02, color, 1., vec3(1));
    
    mat r = Uop(b0, b1);
    r = Uop(r, bAB);
    r = Uop(r, f);
    
    // I guess still missing white edges computation for AO and IL
    // That's why the discontinuity in the white cube
    if (r.z < MIN_S)
    {
        q = p;
        q.x = mod(q.x, subSpace) - subSpace * .5;
        q.x -= sqrt(2.);
        q.z += 1.;
        q.xy *= rotate(45. * Pi / 180.);
        q.z += offsetZ;

        mat bL = mat(box(q, vec3(.5), .0), color, 1., vec3(1));
        
        q = p;
        q.x = mod(q.x, subSpace) - subSpace * .5;
        q.x += sqrt(2.);
        q.z -= 1.;
        q.xy *= rotate(45. * Pi / 180.);
        q.z += offsetZ;

        mat bR = mat(box(q, vec3(.5), .0), color, 1., vec3(1));
        
        r = Uop(r, bL);
        r = Uop(r, bR);
    }
    
    return r;
}

vec3 normal(in vec3 p)
{
    vec2 e = vec2(.01, 0);
    return normalize(scene(p).z - vec3(scene(p - e.xyy).z, scene(p - e.yxy).z, scene(p - e.yyx).z));
}

mat marcher(in vec3 o, in vec3 d)
{
    float t = 0.;
    for (int i = 0; i < STEPS; i++)
    {
        mat s = scene(o + d * t);
        t += s.z * .9;
        if (s.z < MIN_S)
            return mat(t, s.c, s.a, s.i);
        if (t > MAX_S)
            return mat(t, vec3(-1), -1., vec3(-1));
    }
    return mat(t, vec3(-1), -1., vec3(-1));
}

void main(void)
{
    vec2 st = gl_FragCoord.xy;
    vec4 O = vec4(0,0,0,1);
    for (float y = 0.; y < AA; y++)
    {
        for (float x = 0.; x < AA; x++)
        {
            vec2 n = vec2(x, y) / AA - .5;
            vec2 uv = (st + n - R * .5) / R.y;

            float aX = -1. + T * sqrt(2.) * .5;
            float aZ = 5. - T * .5;
            vec3 o = vec3(aX, 1.5, aZ);
            vec3 d = camera(uv * .7, o, vec3(aX, .5, aZ-5.));

            mat m = marcher(o, d);
            if (m.a != -1.)
            {
                vec3 p = o + d * m.z;
                vec3 n = normal(p);

                vec3 light_pos = vec3(aX, 255., aZ);
                vec3 light_dir = normalize(light_pos - p);

                float diff = max(dot(n, light_dir), 0.);

                #ifdef BLEED
                    O.rgb += (diff + m.a * m.i) / 2. * m.c;
                #else
                    O.rgb += (diff + m.a) / 2. * m.c;
                #endif
            }
            else
                O.rgb += color;
        }
    }

    O.rgb = sqrt(O.rgb / (AA * AA));
    glFragColor = O;
}
