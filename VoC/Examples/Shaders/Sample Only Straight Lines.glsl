#version 420

// original https://www.shadertoy.com/view/flKyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: Lorenzo Fiestas

//-----------------------------------------------
//      UTILITIES

#define PI (3.141592)

float rand(vec2 st);

float rand(vec3 p);

float valueNoise(vec2 st);

float valueNoise(vec3 p);

float valueNoise(vec3 p, int octaves);

vec3 hsv2rgb(vec3 hsv);

vec3 rgb2hsv( in vec3 rgb );

mat2 rotate(float t);

//-----------------------------------------------

// Draw line trough p0 and p1
float line(vec2 st, vec2 p0, vec2 p1)
{
    float width = .15 + .125*(.5*valueNoise(2.*st + time) - .5);
    float dx = p1.x - p0.x;
    
    bool divBy0 = dx == 0.;
    if(divBy0)
        return smoothstep(width, -width, abs(st.x - p0.x));
    
    float m = (p1.y - p0.y)/dx;
    float b = p0.y - m*p0.x;
    float wFix = abs(cos(atan(m)));
    width /= wFix;
    
    return smoothstep(width, -width, abs(m*st.x + b - st.y));
}

// Functions to be used for transformations
float func(float x)
{    
    float t = .3*time;
    float ret = 0.;
    
    float func0 = 1./x;
    float func1 = exp(x) + x;
    float func2 = 1./x + x;
    float func3 = cos(x);
    
//#define SIN_CYCLING
#ifdef SIN_CYCLING
    #define SQR(x) ((x)*(x))
    ret += (SQR(max(0.,  sin(t))) + .01) * func0;
    ret += (SQR(max(0.,  cos(t))) + .01) * func1;
    ret += (SQR(max(0., -sin(t))) + .01) * func2;
    ret += (SQR(max(0., -cos(t))) + .01) * func3;
#else
    #define cycle(x) (smoothstep(0., 1., 1.-abs((x)-1.)))
    ret += (cycle(mod(t + 0., 4.)) +.01) * func0;
    ret += (cycle(mod(t + 1., 4.)) +.01) * func1;
    ret += (cycle(mod(t + 2., 4.)) +.01) * func2;
    ret += (cycle(mod(t + 3., 4.)) +.01) * func3;
#endif

    float twist = 2.*sin(.1*time) + 2.;
    return ret + twist;
}

void main(void)
{
    // Normalized pixel coordinates (from -1. to 1.)
    vec2 uv0 = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    const float ZOOM = 4.;
    vec2 uv  = uv0 * ZOOM * rotate(-.25*time);
    vec2 uvr = rotate(0.*PI/3.) * uv;
    vec2 uvg = rotate(2.*PI/3.) * uv;
    vec2 uvb = rotate(4.*PI/3.) * uv;

    // Time varying pixel color
    float mask = 0.;
    vec3 col = vec3(0.);
    const float RANGE = 5.;
    const float LINES = 100.;
    
    // Paint 2.*LINES lines for each color 
    for(float x = -RANGE; x <= RANGE; x += RANGE/LINES)
    {   
        #define PAINT_COLOR(C,UV) mask   = line(UV, vec2(x, 1.), vec2(func(x), -1.));  \
                                  col.C += /*max(0., cos(PI*x/RANGE)) * */ mask;
        
        PAINT_COLOR(r, uvr)
        PAINT_COLOR(g, uvg)
        PAINT_COLOR(b, uvb)
    }
    // Extra juice to colors
    col *= atan(length(col))/(length(col) + .001);
            
    // Smokify colours
    vec3 hsv = rgb2hsv(col);
#define PRONOUNCED_COLOR_BOUNDARIES
#ifdef PRONOUNCED_COLOR_BOUNDARIES
    // Change noise based on color to get more defined color sections
    hsv += .4*valueNoise(vec3(3.*uv0, 5.*(hsv[0] + hsv[1]) + time), 5);
#else
    hsv += .4*valueNoise(vec3(3.*uv0, time), 5);
#endif
    hsv[2] *= 1. - smoothstep(1., .5, hsv[1] + .5); // darken bg noise
    
    vec3 rgb = hsv2rgb(hsv); 
    glFragColor = vec4(rgb, 1.);
}

//-----------------------------------------------------------------------------------

float rand(vec2 st)
{
    return fract(6373.35391*st.x*sin(734.255*(st.y-st.x + 35.3)) +
                 344.872343*st.y*sin(5443.65*(st.y-st.x + 11.2)) + 395.47);
}

float rand(vec3 p)
{
    return fract(6373.35391*p.x*sin(734.255*(p.y-p.x-p.z + 35.3)) +
                 344.872343*p.y*sin(5443.65*(p.y-p.x-p.z + 11.2)) +
                 -42.349436*p.z*sin(-246.42*(p.y-p.x-p.z + 7.26)) +
                 395.47);
}

float valueNoise(vec2 st)
{
    float x0y0 = rand(floor(st + vec2(0., 0.)));
    float x0y1 = rand(floor(st + vec2(0., 1.)));
    float x1y0 = rand(floor(st + vec2(1., 0.)));
    float x1y1 = rand(floor(st + vec2(1., 1.)));
    
    float l = mix(x0y0, x0y1, fract(st.y));
    float r = mix(x1y0, x1y1, fract(st.y));
    return mix(l, r, fract(st.x));
}

float valueNoise(vec3 p)
{
    float x0y0z0 = rand(floor(p + vec3(0., 0., 0.)));
    float x0y1z0 = rand(floor(p + vec3(0., 1., 0.)));
    float x1y0z0 = rand(floor(p + vec3(1., 0., 0.)));
    float x1y1z0 = rand(floor(p + vec3(1., 1., 0.)));
    
    float x0y0z1 = rand(floor(p + vec3(0., 0., 1.)));
    float x0y1z1 = rand(floor(p + vec3(0., 1., 1.)));
    float x1y0z1 = rand(floor(p + vec3(1., 0., 1.)));
    float x1y1z1 = rand(floor(p + vec3(1., 1., 1.)));
    
    float l0 = mix(x0y0z0, x0y1z0, fract(p.y));
    float r0 = mix(x1y0z0, x1y1z0, fract(p.y));
    
    float l1 = mix(x0y0z1, x0y1z1, fract(p.y));
    float r1 = mix(x1y0z1, x1y1z1, fract(p.y));
    
    return mix(mix(l0, r0, fract(p.x)),
               mix(l1, r1, fract(p.x)), fract(p.z));
}

float valueNoise(vec3 p, int octaves)
{
    float k = 1.;
    float f = 1.;
    float ret = 0.;
    for(int i = 0; i < octaves; i++)
    {
        ret += k*valueNoise(f*p);
        k *= 1./sqrt(2.);
        f *= 2.;
    }
    return ret/(sqrt(float(octaves)));
}

vec3 hsv2rgb(vec3 hsv)
{
    vec3 rgb = clamp( abs(mod(hsv.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return hsv.z * mix( vec3(1.0), rgb, hsv.y);
}

vec3 rgb2hsv( in vec3 rgb )
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(rgb.bg, K.wz),
                 vec4(rgb.gb, K.xy),
                 step(rgb.b, rgb.g));
    vec4 q = mix(vec4(p.xyw, rgb.r),
                 vec4(rgb.r, p.yzx),
                 step(p.x, rgb.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

mat2 rotate(float t)
{
    return mat2(cos(t), -sin(t),
                sin(t), cos(t));
}
