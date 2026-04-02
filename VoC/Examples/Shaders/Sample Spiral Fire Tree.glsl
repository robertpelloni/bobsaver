#version 420

// original https://www.shadertoy.com/view/ttG3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define EPS .001

#define time ((saw(float(__LINE__)/GR)/E+1.0)*time/PI)
#define stair floor
#define jag fract

float cross2( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

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
// given a point p and a quad defined by four points {a,b,c,d}, return the bilinear
// coordinates of p in the quad. Returns (-1,-1) if the point is outside of the quad.
vec2 invBilinear( in vec2 p, in vec2 a, in vec2 b, in vec2 c, in vec2 d )
{
    vec2 e = b-a;
    vec2 f = d-a;
    vec2 g = a-b+c-d;
    vec2 h = p-a;
        
    float k2 = cross2( g, f );
    float k1 = cross2( e, f ) + cross2( h, g );
    float k0 = cross2( h, e );
    
    float w = k1*k1 - 4.0*k0*k2;

    w = sqrt(abs( w ));
    
    float v1 = ((-k1 - w)/(2.0*k2));
    float v2 = ((-k1 + w)/(2.0*k2));
    float u1 = ((h.x - f.x*v1)/(e.x + g.x*v1));
    float u2 = ((h.x - f.x*v2)/(e.x + g.x*v2));
    

    vec2 res = vec2(min(abs(u1), abs(u2)), min(abs(v1), abs(v2)));
    return saw(res*1.0);
}

vec2 SinCos( const in float x )
{
    return vec2(sin(x), cos(x));
}
vec3 RotateZ( const in vec3 vPos, const in vec2 vSinCos )
{
    return vec3( vSinCos.y * vPos.x + vSinCos.x * vPos.y, -vSinCos.x * vPos.x + vSinCos.y * vPos.y, vPos.z);
}
      
vec3 RotateZ( const in vec3 vPos, const in float fAngle )
{
    return RotateZ( vPos, SinCos(fAngle) );
}
vec2 RotateZ( const in vec2 vPos, const in float fAngle )
{
    return RotateZ( vec3(vPos, 0.0), SinCos(fAngle) ).xy;
}
mat4 RotateZ( const in mat4 vPos, const in float fAngle )
{
    return mat4(RotateZ( vec3(vPos[0].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0,
                RotateZ( vec3(vPos[1].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0,
                RotateZ( vec3(vPos[2].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0,
                RotateZ( vec3(vPos[3].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0);
}
mat4 translate( const in mat4 vPos, vec2 offset )
{
    return mat4(vPos[0].xy+offset, 0.0, 0.0,
                vPos[1].xy+offset, 0.0, 0.0,
                vPos[2].xy+offset, 0.0, 0.0,
                vPos[3].xy+offset, 0.0, 0.0);
} 
mat4 scale( const in mat4 vPos, vec2 factor )
{
    return mat4(vPos[0].xy*factor, 0.0, 0.0,
                vPos[1].xy*factor, 0.0, 0.0,
                vPos[2].xy*factor, 0.0, 0.0,
                vPos[3].xy*factor, 0.0, 0.0);
} 
vec2 tree(vec2 uv)
{
    
    uv = uv*2.0-1.0;
    
    mat4 square = mat4(EPS, EPS, 0.0, 0.0,
                       1.0-EPS, EPS, 0.0, 0.0,
                       1.0-EPS, 1.0-EPS, 0.0, 0.0,
                       0.0, 1.0-EPS, 0.0, 0.0);
    
    float size =  .5;
    
    square = translate(square, vec2(-.5));
    square = scale(square, vec2(2.0));
    square = RotateZ(square, PI/6.0+sin(time)*.1);
    square = scale(square, vec2(3./4.));
    square = translate(square, vec2(.5, 0.0));
    
    
    vec2 uv1 = invBilinear(uv, square[0].xy, square[1].xy, square[2].xy, square[3].xy);
    square = scale(square, vec2(-1.0, 1.0));
    vec2 uv2 = invBilinear(uv, square[0].xy, square[1].xy, square[2].xy, square[3].xy);
    square = scale(square, vec2(1.0, -1.0));
    if(uv.x >= 0.0)
        return uv1;
    if(uv.x < 0.0)
        return uv2;
    else
        return uv*.5+.5;
}

float square(vec2 uv, float iteration)
{
    uv = uv*2.-1.;
    return 1.-smoothstep(0.0, 0.5, abs(saw(uv.y+time/PI)-uv.x));
}

vec2 spiral(vec2 uv)
{
    float r = log(length(uv)+1.)/2.;
    float theta = atan(uv.y, uv.x)/PI-r;
    return vec2(saw(r+time/E),
                saw(theta+time/GR));
}

vec3 phase(float map)
{
    return vec3(sin(map),
                sin(4.0*PI/3.0+map),
                sin(2.0*PI/3.0+map))*.5+.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 uv0 = uv.xy;
    
    float map = 0.0;
    
    float lambda = 4.0;
    
    const int max_iterations = 12;

    float scale = 3.0*PI+sin(time/GR/E);
    uv *= scale;
    uv -= scale/2.0;
    uv.x *= resolution.x/resolution.y;
    uv.xy += vec2(cos(time*.234),
                  sin(time*.345))*scale/2.;
    uv.xy = spiral(uv.xy*scale);
    
    for(int i = 0; i <= max_iterations; i++)
    {
        float iteration = (float(i)/(float(max_iterations) ));
        uv.xy = tree(uv.xy);
        map += square(uv.xy, iteration);
    }
    
    glFragColor.rgb = phase(map)*
                    clamp(map, 0.0, 1.0);
    return;
}
