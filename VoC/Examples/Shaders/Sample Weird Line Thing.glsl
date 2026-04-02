#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3slyDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.141592653

const float PHI = 0.5*(sqrt(5.) + 1.); 

vec2 fibonacci_lattice(int i, int N)
{
    return vec2((float(i)+0.5)/float(N), mod(float(i)/PHI, 1.)); 
}

vec3 fibonacci_sphere(int i, int N)
{
    vec2 xy = fibonacci_lattice(i, N);
    vec2 pt = vec2(2.*M_PI*xy.y, acos(2.*xy.x - 1.) - M_PI*0.5);
    return vec3(cos(pt.x)*cos(pt.y), sin(pt.x)*cos(pt.y), sin(pt.y)); 
}

mat4 getPerspective(float fov, float aspect, float n, float f)
{   
    float scale = tan(fov * M_PI / 360.) * n; 
    float r = aspect * scale, l = -r; 
    float t = scale, b = -t; 

    
    return mat4(2. * n / (r - l), 0, 0, 0,
                0, 2. * n / (t - b), 0, 0,
                (r + l) / (r - l), (t + b) / (t - b), -(f + n) / (f - n), -1,
                0, 0, -2. * f * n / (f - n), 0);
}

mat4 getRot(vec2 a)
{
    
   mat4 theta_rot = mat4(1, 0, 0, 0,
                         0, cos(a.y), sin(a.y), 0,
                         0, -sin(a.y), cos(a.y), 0,
                         0, 0, 0, 1); 
        
   mat4 phi_rot = mat4(cos(a.x), sin(a.x), 0, 0,
                       -sin(a.x), cos(a.x), 0, 0,
                        0, 0, 1, 0,
                          0, 0, 0, 1); 
   return transpose(phi_rot*theta_rot);
}

mat4 getModel(vec3 dx)
{
   return transpose(mat4(1, 0, 0, dx.x,
               0, 1, 0, dx.y,
               0, 0, 1, dx.z,
               0, 0, 0, 1)); ;
}

vec3 toScreen(vec4 X)
{
    return vec3(resolution.xy*(0.5*X.xy/X.w + 0.5), X.z);
}

float POINT(vec2 pos, float R, vec4 X)
{
    R *= resolution.x;
    vec3 spos = toScreen(X);
    return exp(-distance(pos, spos.xy)*spos.z/R);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float interpolate(float val, vec2 p0, vec2 p1) 
{
    return mix(p0.y, p1.y, (val-p0.x)/(p1.x-p0.x));
}

float interpolate3(vec2 val, vec3 p0, vec3 p1) 
{
    return mix(p0.z, p1.z, clamp(dot(p1.xy - p0.xy, val - p0.xy)/dot(p1.xy - p0.xy,p1.xy - p0.xy), 0.,1.));
}

float LINE(vec2 pos, float R, vec4 X, vec4 Y)
{
    R *= resolution.x;
    vec3 spos0 = toScreen(X);
    vec3 spos1 = toScreen(Y);
    float d = sdSegment(pos, spos0.xy, spos1.xy)/R;
    float depth = interpolate3(pos, spos0, spos1);
    return exp(-d*depth);
}

//a rainbow colormap from Matlab

float base(float x) 
{
    if ( x <= -0.75 ) return 0.0;
    else if ( x <= -0.25 ) return interpolate( x, vec2(-0.75, 0.0), vec2(-0.25, 1.) );
    else if ( x <= 0.25 ) return 1.0;
    else if ( x <= 0.75 ) return interpolate( x, vec2(0.25, 1.0), vec2(0.75, 0.0) );
    else return 0.0;
}

vec3 jet_colormap(float v)
{
    return vec3(base(v - 0.5),base(v),base(v + 0.5));
}

vec3 jet_range(float v, float a, float b)
{
    return jet_colormap(2.*clamp((v-a)/(b-a),0.,1.) - 1.);
}

void main(void)
{
    vec2 pos=gl_FragCoord.xy;

     ivec2 p = ivec2(pos);
    
    int N = 96;
    glFragColor.xyz = vec3(0.);
    
    mat4 perspec = getPerspective(60., resolution.x/resolution.y, 0.001, 10.);
    vec2 angles = vec2(time, M_PI*0.5+0.5*sin(time));
    mat4 rot = getRot(angles);
    mat4 sh = getModel(vec3(0.,0.,-2.));
    int R = 32;
    int a = (R*(500/10))%N;
    vec4 pd = perspec*sh*rot*vec4(fibonacci_sphere(0, N), 1.);
    vec4 d;
    //rasterizer
    for(int i = 1; i < N; i++)
    {
        d = perspec*sh*rot*vec4(fibonacci_sphere(i, N), 1.);
        
        glFragColor.xyz += 2.*jet_range(sin(0.1*float(i)), -1.25, 1.25)*(LINE(pos, 0.002, d, pd)+POINT(pos, 0.005, d));     
        pd = d;
    }
}
