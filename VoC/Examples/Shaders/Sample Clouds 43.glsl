#version 420

// original https://www.shadertoy.com/view/ttjBzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All code taken from treize on his example 
// https://www.shadertoy.com/view/3lBfWR

void hash11(float p, out float Out)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    Out = fract(p);
}

mat2 r2(float r){
    return mat2(cos(r),sin(r),-sin(r),cos(r));
} //2d rotate function

float noise( in vec3 x )
{
    
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    
    float n = p.x + 317.0*p.y + 157.0*p.z;
    
    float a;
    hash11(n+0.0,a);
    float b; hash11(n+1.0,b);
    float c; hash11(n+317.0,c);
    float d; hash11(n+318.0,d);
    float e; hash11(n+157.0,e);
    float f; hash11(n+158.0,f);
    float g; hash11(n+474.0,g);
    float h; hash11(n+475.0,h);

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}

const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );

float fbm_4( in vec3 x )
{
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for( int i=0; i<4; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m3*x;
    }
    return a;
}

const float PI = 3.1415926;

float scene(vec3 p)
{    
    p.xy *= r2(time * .5);
    p.xz *= r2(time * .25);
    
    return .03-length(p)*.001+fbm_4(p*.17);
}
void main(void)
{
    
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 v = -1.0 + 2.0*q;
    v.x *= resolution.x/resolution.y;

    vec2 mo = vec2(0.0);

    vec3 org = 20.*normalize(acos(cos(abs(time*vec3(.3,.6,.1))) ));
    //vec3 org = 20.0*normalize(vec3(0.,0., 0.1));
    vec3 ta = vec3(0.0, 1.0, 0.0);
    vec3 ww = normalize( ta - org);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 dir = normalize( v.x*uu + v.y*vv + 1.5*ww );
    vec4 color=vec4(0.0);
    
    
    
    const int nbSample = 64;

    
    float zMax         = 40.;
    float step         = zMax/float(nbSample);
    float zMaxl         = 20.;
    vec3 p             = org;
    float T            = 1.;
    float absorption   = 100.;

    for(int i=0; i<nbSample; i++)
    {
        float density = scene(p);
        if(density>0.)
        {
            float tmp = density / float(nbSample);
            T *= 1. -tmp * absorption;
            if( T <= 0.01)
            {
                break;
            }

            color += vec4(1.)*50.*tmp*T +  vec4(.2,0.3,0.4,1.0)*90.0*tmp*T;
        }
        p += dir*step;
    }    

    glFragColor  = color;
}
