#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//------------------------------------------------------
// FOV_Test.glsl
//
// original   https://www.shadertoy.com/view/XtVGzw
//
// Just testing a new lookAt function I came up with.
//
// Move your mouse to set camera speed.
//
// Tags: fov, lookat, shittyterrain
//
// Many thanks to:
//   https://www.shadertoy.com/view/4djSRW
//   https://www.shadertoy.com/view/4slGD4
//   http://www.iquilezles.org/www/articles/fog/fog.htm
//------------------------------------------------------

#define P 0.001  // Precision
#define D 450.   // Distance
#define S 32     // Marching steps
#define R 1.     // Marching substeps
#define K 16.    // Shadow softness
#define A 5.     // AO steps

#define speed time
#define PI  3.14159265359
#define TAU 6.28318530718

// here you can change the horizontal and vertical field of view
#define FOV vec2(122,166)

struct sHit {
    vec3  pos; // position
    float t; // distance travelled
    float d; // distance to object
    float s; // steps required
};

struct sRay {
    vec3 ori; // origin
    vec3 dir; // direction
} ray;

struct sCamera {
    vec3 pos; // position
    vec3 dir; // direction
    vec3 up;  // up vector
    vec2 fov; // fov
} cam;

const int _num_objects = 3;
float _obj[_num_objects], _d;
int _ignore_object = -1;

vec2 _uv;

// gets changed during marching
bool _shadowMarch = false;
bool _normalMarch = true;
bool _ambientOccMarch = false;
bool _highresTerrain = false;

float _water_level = 70.;

/* ================= */
/* === Utilities === */
/* ================= */

mat2 rot(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);
}

mat3 rot(vec3 n, float a)
{
    float s = sin(a), c = cos(a), k = 1.0 - c;
    
    return mat3(n.x*n.x*k + c    , n.y*n.x*k - s*n.z, n.z*n.x*k + s*n.y,
                n.x*n.y*k + s*n.z, n.y*n.y*k + c    , n.z*n.y*k - s*n.x,
                n.x*n.z*k - s*n.y, n.y*n.z*k + s*n.x, n.z*n.z*k + c    );
}

float smax( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( a, b, h ) + k*h*(1.0-h);
}

float hash11(float n)
{
    return fract(sin(dot(vec2(n),vec2(12.9898,78.233)))*43758.5453);
}

float hash21(vec2 p)
{
    p = floor(p/2.)*2.;
    p = fract(p/vec2(3.07965,7.4235));
    p += dot(p.xy,p.yx+19.19);
    return fract(p.x*p.y);
}

float noise(vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    vec2 e = vec2(1,0);
    
    f = smoothstep(0.,1.,f);

    return mix(
        mix(hash21(p),hash21(p+e.xy),f.x),
        mix(hash21(p+e.yx),hash21(p+e.xx),f.x),
        f.y
    );
}

float terrain(vec3 x)
{
    float f = 0.;
    float a = 0.;
    vec2 p = x.xz*.5;
    
    for(float i = 0.; i < 5.; i++)
    {
        float h = pow(i+2.,2.);

        f += noise(p/h)*h;
        a += h;
        
        p *= rot(a);
    }
    
    if (_highresTerrain == true)
    {
        for(float i = 0.; i < 5.; i++)
        {
            float h = pow(i+P,2.);

            f += mix(noise(p*h)/h,noise(p/h)*h,hash11(a)*.5);
            a += h;
            
            p *= rot(a);
        }   
    }
    
    return smax(f/a*200.,_water_level-.1,10.);
}

/* ============ */
/* === Scene=== */
/* ============ */

float scene(vec3 p)
{
    float d = 1e10;
    
    // skybox
    _obj[0] = _shadowMarch == true || _ambientOccMarch == true 
        ? 1e10 : abs(length(p-cam.pos)-D)-P;
    
    // terrain
    _obj[1] = p.y-terrain(p);
    
    _obj[2] = p.y-_water_level;
    
    if (_normalMarch == true)
    {
        _obj[2] -= noise(p.xz*vec2(1,2))*.05;
    }

    for(int i = 0; i < _num_objects; i++)
    {
        if (_ignore_object == i) continue;
        d = min(d,_obj[i]);
    }
    
    _d = d;

    return d;
}

/* ================ */
/* === Marching === */
/* ================ */

sHit march(sRay r)
{
    vec3 p;
    float t = 0., d, s;
    
    for(int i = 0; i < S; i++)
    {
        d = scene(p = r.ori + r.dir*t);

        if (d < P || t > D)
        {
            s = float(i);
            break;
        }

        t += d/max(R+1.,1.);
    }

    return sHit(p, t, d, s);
}

// get camera position and looking direction
sRay lookAt(sCamera c, vec2 uv, float aspect)
{   
    vec3 r = normalize(cross(c.dir, c.up));
    vec3 u = cross(r, c.dir);
    
    uv.y /= aspect;
    
    float a = c.fov.x / 360. * uv.x * PI;
    float b = c.fov.y/360. * uv.y * PI;
    
    c.dir *= rot(u,a);

    r = normalize(cross(c.dir,u));

    c.dir *= rot(r,b);
    
    return sRay(c.pos, c.dir);
}

vec3 getNormal(vec3 p)
{
    _normalMarch = true;
    
    vec2 e = vec2(P,0.);

    vec3 n = normalize(vec3(
        scene(p+e.xyy)-scene(p-e.xyy),
        scene(p+e.yxy)-scene(p-e.yxy),
        scene(p+e.yyx)-scene(p-e.yyx)
    ));
    
    _normalMarch = false;
    
    return n;
}

/* =============== */
/* === Shading === */
/* =============== */

float getAmbientOcclusion(sHit h) 
{    
    _ambientOccMarch = true;
    
    float t = 0., a = 0.;
    
    for(float i = 0.; i < A; i++)
    {
        float d = scene(h.pos - ray.dir*i*5.);
        t += d/max(R+1.,1.);
    }
    
    _ambientOccMarch = false;

    return clamp(t/A*50./D,0.,1.);
}

float getShadow(vec3 origin, vec3 sunDir)
{
    _shadowMarch = true;
    _highresTerrain = false;

    float t = 0., s = 1.0;

    for(int i = 0; i < S/2; i++)
    {
        float d = scene(origin + sunDir * t);
       
          if (t > D) break;
        
        t += d;
        s = min(s,d/t*K);
    }
    
    _highresTerrain = true;
    _shadowMarch = false;

    return clamp(s,0.5,1.);
}

vec3 applyFog(vec3 col, vec3 colFog, vec3 colSun, sHit h, vec3 sunDir)
{
    float d = pow(length(h.pos - cam.pos)/D,2.);
    float s = pow(max(dot(ray.dir,sunDir),0.),10.*d);
    
    return mix(col, mix(colFog * min(sunDir.y+.5,1.), colSun, s), d);
}

vec3 getColor(sHit h)
{    
    _highresTerrain = true;
 
    sHit _h = h;
    vec3 n = getNormal(h.pos);
    
    vec3 col = vec3(0),c;
    vec3 col_sky = vec3(1,1.7,2)*.2;;
    vec3 col_sun = vec3(2,1.5,1);
    
    vec3 sunDir = normalize(vec3(0.5,0.3,1));
    
    float lastRef = 0.0;
    float ref = 0.0;

    for(int i = 0; i < 2; i++)
    {           
        float diff = max(dot(n, sunDir),.2);
        float spec = pow(max(dot(reflect(-sunDir,n),normalize(cam.pos-h.pos)),0.),20.);

        if (_d == _obj[0])
        {    
            c = col_sky;
        }
        else if(_d == _obj[1])
        {
            vec2 e = vec2(2,0);
            vec3 p = h.pos;
            
            float dh = 1.-min(mix(
                abs(terrain(p+e.xyy)-terrain(p-e.xyy)),
                abs(terrain(p+e.yyx)-terrain(p-e.yyx)),
            .5),1.);
                    
            c = mix(vec3(.5,.25,0),vec3(.25,.5,0),dh) * getShadow(h.pos, sunDir) * getAmbientOcclusion(h) * diff;
        }
        else if(_d == _obj[2])
        {
            c = vec3(0) + spec * getShadow(_h.pos, sunDir);
            ref = .3;
        }
        
        c = applyFog(c, col_sky, col_sun, h, sunDir) ;
        col = i == 0 ? c : mix(c,col,1.-lastRef);
    
        if (ref > 0.0)
        {
            sRay r;
            r.dir = normalize(reflect(h.pos - cam.pos,n));
            r.ori = h.pos + r.dir;
        
            h = march(r);
            n = getNormal(h.pos);

            lastRef = ref;
            ref = 0.0;
        }
        else { break; }
    }
    return col;
}

/* ============ */
/* === Main === */
/* ============ */

void main( void )
{   
    float aspect = resolution.x / resolution.y;
    vec2 uv = (gl_FragCoord.xy / resolution.xy -0.5) * 2.0;
    //vec2 mp =     (mouse.xy / resolution.xy -0.5) * 2.0;
    vec2 mp = vec2 (0.1, 1.0) * resolution.xy;
    
    if (mouse.x < 10. && mouse.y < 10.)
    {
        mp = vec2(cos(time*.5)*.5,sin(time)*.25+.75);
    }
    
    cam = sCamera(
        vec3(0,0,0),   // position
        vec3(0,-1,0),  // direction
        vec3(0,0,1),   // up vector
        FOV);
    
    cam.dir.yz *= rot(mp.y*cos(mp.x)*PI/2.);
    cam.dir.yx *= rot(mp.x*cos(mp.y)*PI/2.);
    cam.pos.z += speed * (1.0*222.+0.5);
    
    float h = terrain(cam.pos);
    cam.pos.y = pow(h,.7) + _water_level + 100. + sin(time*.5) * 40.;

    ray = lookAt(cam, uv, aspect);
                  
    vec3 col = getColor(march(ray));

    glFragColor = vec4(col,1);
}
