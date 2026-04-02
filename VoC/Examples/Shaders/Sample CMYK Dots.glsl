#version 420

// original https://www.shadertoy.com/view/MtXSzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define resolution resolution.xy

const float pi = 3.14156;
const float pi2 = pi*2.0;

float hash( float n )
{
    return fract(sin(n)*43758.5453123);
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0;
    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+157.0), hash(n+158.0),f.x),f.y);
}

const mat2 m2 = mat2( 0.8, -0.6, 0.6, 0.8 );

float fbm( vec2 p )
{
    float f = 0.0;
    f += 0.5000*noise( p ); p = m2*p*2.02;
    f += 0.2500*noise( p ); p = m2*p*2.03;
    f += 0.1250*noise( p ); p = m2*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

vec2 tr(vec2 p)
{
     p /= resolution.xy;
     p = -1.0+2.0*p;
     p.x *= resolution.x/resolution.y;
     return p;
}

vec2 rot(vec2 p, float deg)
{
    float c = cos(deg);
    float s = sin(deg);
    mat2 m = mat2(c,s,
                                           s,-c);
    return m*p;
}

vec2 pix(vec2 p, int s)
{
    return floor(p*float(s)+0.5)/float(s);
}

float eudist(vec2 p, vec2 s)
{
    return max(abs(p.x-s.x),abs(p.y-s.y));
}

float hex(vec2 p)
{
    p.x *= 0.57735*2.0;
    p.y += mod(floor(p.x), 2.0)*0.5;
    p = abs((mod(p, 1.0) - 0.5));
    return abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
}

float circle(vec2 p, float r)
{
     return smoothstep(r,r*.95,length(p));
}

void main(void)
{
    vec2 p = tr(gl_FragCoord.xy);
    vec3 col = vec3(1.0);

    float t = time*.125;
    float g = 0.0275;

    p+=vec2(cos(t),sin(t));

    for(int i=0;i<3;++i)
    {
         vec2 f = rot(p,float(i+1)*-75.);
         vec2 q = mod(f,g)-g*.5;
         float n = fbm(2.*floor(f/g)*g
                    +4.*t*float(i)+t);
        col[i] -= circle(q,n*g*.8);
    }

    col = sqrt(col);

    glFragColor = vec4( col, 1.0 );
}
