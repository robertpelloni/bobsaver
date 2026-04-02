#version 420

// original https://www.shadertoy.com/view/WlBcRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Free for any use, just let my name appears or a link to this shader

//animation 0 or 1
#define ANIM                1

#define RADIUS                4.
#define GRAV_CONST            6.674
#define THICK                2.
#define DISTORSION            6.67
#define    MASS                .1
    
#define ALPHA                 20.
#define COLOR                1   

#define DISPERSION_VELOCITY    .2

//Set High definition to 1 for more details (sort of LOD) else 0 :
#define HIGH_DEF            1
//----> in HIGH_DEF mode, you can
//choose the nathure of noise ADDITIVE 1 = additive noise || 0 = multiplicative
    #define ADDITIVE         0

//Stretch or not the colored volume
#define STRETCH                 1

//////////////////////////////////////////////////////////////////

#define f(x) (.5+.5*cos(x))
#define Pnoise(p) (2.* (clamp( noise(p)/.122 +.5 ,0.,1.)) )
#define Psnoise(p) ( 2.*( exp( snoise(p)) ) )

#define  rnd(v)  fract(sin( v * vec2(12.9898, 78.233) ) * 43758.5453)
#define srnd(v) ( 2.* rnd(v) - 1. )

#define PI                     3.1415926

//most of "noise stuff" comes from iq

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

vec3 hash( vec3 p ) // replace this by something better
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

/* 3d simplex noise */
float snoise(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}

float noise( in vec3 p )
{
    vec3 i = floor( p );
    vec3 f = fract( p );
    
    vec3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}
/////////////////////

//Transformations

//translation

mat4 translate(vec3 k)
{
    mat4 mat = mat4(
        vec4(1., vec3(0.)),
        vec4(0., 1., vec2(0.)), 
        vec4(vec2(0.), 1., 0.),
        vec4(k, 1.) );
    
    return mat;
}

mat2 rot2(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2( c, -s, s, c);
}

//rotation around the x axis
mat3 rotateX(float degree)
{
    float rad = PI*degree/180.;
     mat3 rot = mat3(1., 0., 0.,
                    0., cos(rad), -sin(rad),
                    0., sin(rad), cos(rad));
    return rot;
}

//rotation axis-angle
mat4 rotation_matrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

/////////////////////
struct Ray
{
    vec3 origin; //origin
    vec3 dir; //direction of the ray
};

// Sphere intersection
float intersect_sphere( Ray r, vec3 sphere, float rad )
{
    vec3 oc = r.origin - sphere;
    float b = dot( oc, r.dir );
    float c = dot( oc, oc ) - rad*rad;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    return -b - sqrt( h );
}
///////////////////////////

struct Camera
{
     vec3 pos; //position
    vec3 target; //focal point = target point
    vec3 forward;
    vec3 right;
    vec3 up;
    
    mat4 view;
};

struct Matter
{
    vec3 pos; //position
    float radius; //accretion disk
    float mass;
};

///////////////////////////////////////////////
Matter m;
Camera cam;
///////////////////////////////////////////////

vec3 I = vec3(1., 0., 0.);     //x axis
vec3 J = vec3(0., 1., 0.);    //y axis
vec3 K = vec3(0., 0., 1.);    // z axis

#define Bnoise(x) abs(noise(x))

vec3 stretching  = vec3( 1. , 1.,  1./4. ); 

float fbm_add( vec3 p ) { // in [-1,1]
    
    float f;
    vec3 s = vec3(2.);
    #if STRETCH
       p *= stretching*  vec3( 1. , 1.,  1./4. );
       s = 2./pow(stretching,vec3(1./4.));
    #endif
    
    f = noise(p); p = p*s;

    #if HIGH_DEF
    f += 0.5000*noise( p ); p = p*s;
    f += 0.2500*noise( p ); p = p*s;
    f += 0.1250*noise( p ); p = p*s;
    f += 0.0625*noise( p );   
    #endif
    return f;
}

float fbm_mul( vec3 p ) { // in [-1,1]
    
    float f;
    vec3 s = vec3(2.);
    #if STRETCH
       p *= stretching*  vec3( 1. , 1.,  .6 );
       s = 2./pow(stretching,vec3(1./4.));
    #endif

    
            float anim = 0.;
            #if ANIM
            anim = time/2.;
            #endif
    
    f = Psnoise(p+anim); p = p*s;

    #if HIGH_DEF
    f *=  Psnoise( p ); p = p*s;
    f *=  Psnoise( p ); p = p*s;
    f *=  Psnoise( p ); p = p*s;
    f *=  Psnoise( p ); 
    #endif
    return f;
}

float fbm(vec3 p)
{
 
    #if ADDITIVE
    return fbm_add(p);
    #else
       return fbm_mul(p);
    #endif
    
}

/* Transparency */
float current_transparency(float dist, float material_coef, float density)
{
   return exp(-dist*material_coef*density); 
}

float current_opacity(float t)
{
     return 1.-t;   
}

vec3 current_opacity(vec3 rgb_o)
{
     return 1.-rgb_o; 
}

#define transp current_transparency

#define ROT rotation_matrix

//end of rotation

vec3 ray_interpolation(Ray r, float t) 
{
     return (r.origin + r.dir*t);   
}

void set_matter(vec3 pos, 
                float mass,
                float radius)
{
     m = Matter(pos, radius, mass);
}

float sdf_sphere(vec3 pXp0, float radius)
{
    return (length(pXp0) - (radius));
}

void init_matter(void)
{
     set_matter(vec3(0., 0., 0.), MASS, RADIUS);
}

void set_camera(vec3 pos, vec3 target)
{
    cam.pos = pos;
    cam.target = target;
    cam.forward = normalize(pos-target);
    cam.right = cross(normalize(vec3(0., 1., 0.)), cam.forward);
    cam.up = cross(cam.forward, cam.right);
        
    cam.view = mat4(vec4(cam.right, 0.), vec4(cam.up, 0.), vec4(cam.forward, 0.), vec4(1.) );
    
}

void init_camera(void)
{
    init_matter();
    set_camera(vec3(0., 0., 4.), m.pos); 
}

void ray_march_scene(Ray r, float k, inout vec3 c)
{
    float uniform_step = k;
    int fbm_weight = 0;
    float jit = 1.;
    //jit = 50.*fract(1e4*sin(1e4*dot(r.dir, vec3(1., 7.1, 13.3))));
   
    float t_gen = 1.;

    float param_t = intersect_sphere(r, m.pos, RADIUS);
    if(param_t <= -1.)
        return;
    vec3 p = ray_interpolation(r, k*jit);        
     
    //rgb transparency               
    
    vec3 t_acc = vec3(1.);    // accumulated parameters for transparency
    float t_loc = transp(uniform_step, 14., ( clamp(smoothstep(.2, 3.*RADIUS, (RADIUS-length(p))) - abs( 2.*(fbm(p/8.)) ), 0., 1.)  ) );
    int s = 0;
    
    for(s; s <90; s++)
    {               
        vec3 dU = vec3(0.);

        float dist_dist = dot(p-cam.pos, p-cam.pos);
        float dist_center = length(m.pos-cam.pos);
        vec3 center = p-m.pos;

        //if too far, then big step        
        float d = length(center)-RADIUS-.5-jit*k;

        if(length(center)-RADIUS < 0.)
        {
            
            #if COLOR           
            
            float rad_bubl = RADIUS/5.; //radius of bubble, also control the opening of the bubble
            vec3 pB = vec3(0,0,rad_bubl);//RADIUS/2.);
            float r_p = length(p-pB)/2.*RADIUS;
            float d = 1. +6.*( length(p-pB) / (rad_bubl) -1.);
            
            vec3 dp = vec3(0.);
            dp += d*(p-pB);             
            
            float dispersion_rate = (fbm((p/2.))); //local dispersion rate

            float velocity = 1.60*(DISPERSION_VELOCITY*dispersion_rate); //modify it to tune the local velocity, 1.60 is precalculated value
            //velocity
            #define VT    velocity            
           
            //energy
            float energy = .5*(VT*VT*VT)/rad_bubl; //energy transfer rate
#define SQR(x) ( (x)*(x) ) 
            float l = exp(-.5*SQR(d/2.));
            float n = 0.;
            
            //if(r_p < 1.)
            //if(energy > 8.)
                n = ( 1.-Psnoise( (p-pB+dp)*l) + energy)*(max(0.,d)*l);

            float mask = smoothstep(0.,
                                    4.*RADIUS,
                                      (RADIUS-length(center)));// * .06*n ;

            
            //Optical density/depth : dens for density
            float dens = ( clamp( mask,
                                     0.,
                                  1.) *n );
            //How colors (rgb) are absorbed at point p in the current iteration
            //k is the step size          
             vec3 rgb_t = exp(-vec3(
                        k * 1. * dens, 
                          k * 2. * dens,
                            k * 2. * dens));    
            
            t_acc *= (rgb_t);           
    
            //blending
               c += t_acc*vec3(1.)*(1.-rgb_t);
            
            #else
            t_gen *= t_loc;
            t_loc = transp(uniform_step, 14., ( clamp(smoothstep(.2, 3.*RADIUS+anim_coef, (RADIUS-length(p))) - abs( 2.*(fbm(p/8.*anim_coef)) ), 0., 1.)  ) );
            #endif
        }

        //if it will never be in the shape anymore, return;
        
        if(length(p-cam.pos) >(dist_center+m.radius) || 
           (t_acc.x+t_acc.y+t_acc.z < 0.001 && t_acc.x+t_acc.y+t_acc.z > 40. ))
        {
             break;
        }
        
        p += r.dir*k;

        k = uniform_step;
    }
    

    //c =float(s)/vec3(50,150,20); return;

    #if COLOR

    #else
    c = vec3(t_gen); return;
    #endif
}
    
void main(void)
{
    init_camera();
    
    vec2 uv = (2.0*(gl_FragCoord.xy)-resolution.xy)/resolution.y;
        
    float degree = 0.0;//2.*PI * mouse.x*resolution.xy.x/resolution.x - PI;
    float degree2 = 0.0;//2.*PI * mouse.y*resolution.xy.y/resolution.y - PI;
    
    vec3 color = vec3(0.);
    vec3 ray_dir = vec3(uv, -1.);

    m.pos = normalize(vec3(-10, 20., m.pos.z));
    
    vec2 m = vec2(0.0);//2.*PI * mouse*resolution.xy.xy/resolution.xy - PI;
    vec3 C = cam.pos, R = normalize(ray_dir);
    C.xz *= rot2(m.x); C.yz *= rot2(m.y);
    R.xz *= rot2(m.x); R.yz *= rot2(m.y);
    
    cam.pos = C;
    ray_march_scene(Ray(C, normalize(R)), .1, color);  
        
    glFragColor = vec4(color, 1.);
}
