#version 420

// original https://www.shadertoy.com/view/3tK3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------CONSTANTS MACROS-----------------
#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define MAX_DIM (max(resolution.x,resolution.y))
//--------------------------------------------------

#define time ((sin(float(__LINE__))/PI/GR+1.0)*time/PI)
#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)

float saw(float x)
{
    float f = mod(floor(abs(x)), 2.0);
    float m = mod(abs(x), 1.0);
    return f*(1.0-m)+(1.0-f)*m;
}

vec2 saw(vec2 x) { return vec2(saw(x.x), saw(x.y)); }
vec3 saw(vec3 x) { return vec3(saw(x.x), saw(x.y), saw(x.z)); }
vec4 saw(vec4 x) { return vec4(saw(x.x), saw(x.y), saw(x.z), saw(x.w)); }

mat2 rotate(float x) { return mat2(cos(x), sin(x), sin(x), -cos(x)); }

float cross2d( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

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

float draw(vec2 uv)
{
    return (1.-smoothstep(0., .1, abs(uv.x-.5)))*(1.-smoothstep(0.9, 1., abs(uv.y)+.5));
}
void main(void)
{
    vec2 p = (gl_FragCoord.xy)/resolution.xy;//*2.-1.;
    p.x = p.x*2.-1.;
    p.x *= resolution.x/resolution.y;
    p.x = p.x *.5+.5;
    
    vec3 col = vec3(0.);

    const float max_iterations = 16.;
    
    float map = 0.;
    map += draw(p);
    for(float f = 0.; f < max_iterations; f+=1.){
        float iteration = (f/max_iterations+1.);
        float angle = sin(time*iteration)/PI-1.*PI/4.;

        vec2 a = vec2(1., 1.);
        vec2 b = vec2(0., 1.);
        vec2 c = vec2(0., 0.);
        vec2 d = vec2(1., 0.);
        
        p = p*2.-1.;
        
        vec2 s = vec2(.75);
        vec2 o = vec2(.5, 0.);
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
            
        map += (1.-smoothstep(0., .1, abs(p.x-.5)))*(1.-smoothstep(0.9, 1., abs(p.y)+.5));
    }
    glFragColor = vec4(flux(map*PI), 1.0 )*clamp(map, 0., 1.)+clamp(1.-map, 0., 1.);
}
