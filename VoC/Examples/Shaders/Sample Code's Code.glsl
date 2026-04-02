#version 420

// original https://www.shadertoy.com/view/wtlfWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define EPS .001

#define MAX_DIM (max(resolution.x,resolution.y))
#define time ((saw(float(__LINE__)/GR)+1.0)*(time/E+1234.4321)/E)
#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)

float cross2d( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

float saw(float x)
{
    float f = mod(floor(abs(x)), 2.0);
    float m = mod(abs(x), 1.0);
    return f*(1.0-m)+(1.0-f)*m;
}
vec2 saw(vec2 x)
{
    return vec2(saw(x.x), saw(x.y));
}

vec3 saw(vec3 x)
{
    return vec3(saw(x.x), saw(x.y), saw(x.z));
}
vec2 invBilinear( in vec2 p, in vec2 a, in vec2 b, in vec2 c, in vec2 d )
{
    vec2 res = vec2(-1.0);

    vec2 e = b-a;
    vec2 f = d-a;
    vec2 g = a-b+c-d;
    vec2 h = p-a;
        
    float k2 = cross2d( g, f );
    float k1 = cross2d( e, f ) + cross2d( h, g );
    float k0 = cross2d( h, e );
    
    // if edges are parallel, this is a linear equation. Do not this test here though, do
    // it in the user code
    if( abs(k2)<0.001 )
    {
        float v = -k0/k1;
        float u  = (h.x*k1+f.x*k0) / (e.x*k1-g.x*k0);
        //if( v>0.0 && v<1.0 && u>0.0 && u<1.0 ) 
            res = vec2( u, v );
    }
    else
    {
        // otherwise, it's a quadratic
        float w = k1*k1 - 4.0*k0*k2;
        //if( w<0.0 ) return vec2(-1.0);
        w = sqrt( w );

        float ik2 = 0.5/k2;
        float v = (-k1 - w)*ik2;// if( v<0.0 || v>1.0 ) v = (-k1 + w)*ik2;
        float u = (h.x - f.x*v)/(e.x + g.x*v);
        //if( u<0.0 || u>1.0 || v<0.0 || v>1.0 ) return vec2(-1.0);
        res = vec2( u, v );
    }
    return (res);
}

mat2 rotate(float x) { return mat2(cos(x), sin(x), sin(x), -cos(x)); }

float smooth_floor(float x)
{
    return floor(x)+smoothstep(.75, 1., fract(x));
}

vec2 tree(vec2 uv)
{
    
    vec2 p = uv*2.-1.;
    
    
        float angle = smooth_floor((time))*PI/12.;

        vec2 a = vec2(1., 1.);
        vec2 b = vec2(0., 1.);
        vec2 c = vec2(0., 0.);
        vec2 d = vec2(1., 1./MAX_DIM);
        
        
        vec2 s = vec2(.75);
        vec2 o = vec2(smooth_floor(time/PI)/500., 0.);
        mat2 m = rotate(angle);
        
        a = a*2.-1.; b = b*2.-1.; c = c*2.-1.; d = d*2.-1.;
        
        a = a*m; b = b*m; c = c*m; d = d*m;
        a *= s; b *= s; c *= s; d *= s;
        a += o; b += o; c += o; d += o;

        
        /*
        //= a*.5+.5; b = b*.5+.5; c = c*.5+.5; d = d*.5+.5;
        a = a*2.-1.; b = b*2.-1.; c = c*2.-1.; d = d*2.-1.;
        */

        vec2 a2 = a*vec2(-1., 1.);
        vec2 b2 = b*vec2(-1., 1.);
        vec2 c2 = c*vec2(-1., 1.);
        vec2 d2 = d*vec2(-1., 1.);
        if(p.x > 0.)
            p = (invBilinear( p, a, b, c, d ));
        else
            p = (invBilinear( p, a2, b2, c2, d2 ));
    return p;
}

vec2 flower(vec2 p)
{
    p *= rotate(time);
    float rots = smooth_floor(3.+6.*saw(time/E))+1./MAX_DIM;
    float angle = atan(-p.y, -p.x);
    float radius = length(p);
    angle = floor(((angle/PI)*.5+.5)*rots);

    vec2 a = vec2(1., 0.);
    vec2 b = vec2(1., 1./MAX_DIM);
    vec2 c = vec2(0., 1./MAX_DIM);
    vec2 d = vec2(0., -1./MAX_DIM);
    
    b *= rotate(angle/rots*2.*PI);
    angle += 1.;
    a *= rotate(angle/rots*2.*PI);
    
    return (invBilinear( p, a, b, c, d ));
}

float square(vec2 uv, vec2 uv0)
{
    return abs(saw(uv.y+uv0.x-uv0.y+time)-uv.x);
}

vec2 spiral(vec2 uv)
{
    float r = log(length(uv)+1.)/2.;
    float theta = atan(uv.y, uv.x)/PI-r*sin(time/E/PI/GR)/PI;
    return vec2(saw(r+time/E/E),
                saw(theta+time/GR/E))*2.-1.;
}

vec3 phase(float map)
{
    return vec3(sin(map),
                sin(4.0*PI/3.0+map),
                sin(2.0*PI/3.0+map))*.5+.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uv0 = uv.xy*2.-1.;
    uv0.x *= max(resolution.x/resolution.y, 1.);
    uv0.y *= max(resolution.y/resolution.x, 1.);
    uv0 = uv0*.5+.5;
    float map = 0.0;
    
    float lambda = 4.0;
    const int max_iterations = 12;

    float scale = 3.0*PI+(time*PI*GR*E);
    uv *= scale;
    uv -= scale/2.0;
    uv.x *= max(resolution.x/resolution.y, 1.);
    uv.y *= max(resolution.y/resolution.x, 1.);
    uv.xy += vec2(cos(time*.234),
                  sin(time*.345))*scale/2.;
    float m = smoothstep(0.45, .55, saw(time/E/PI));
    uv.xy = spiral(uv.xy*scale)*m+(1.-m)*(uv0);;
    
    float nature = smoothstep(.45, .55, saw(time/GR/E))*(1.-m);
    uv =  uv*(1.-nature)+flower(uv0*2.-1.)*nature;
    
    for(int i = 0; i <= max_iterations; i++)
    {
        float iteration = (float(i)/(float(max_iterations) ));
        uv.xy = saw(tree(uv.xy));
            map += square(uv.xy, uv0);
        uv0 = uv;
    }
    
    float w = smoothstep(saw(map/float(max_iterations)+time), .0, .2);
    float b = smoothstep(saw(map/float(max_iterations)+time), .0, .2);
    glFragColor.rgb = vec3(saw(map))*
                    
                    clamp(map, 0.0, 1.0);
    glFragColor.a = 1.0;
}
