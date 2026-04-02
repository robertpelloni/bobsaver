#version 420

// original https://www.shadertoy.com/view/XlKXDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T time
#define PI 3.1415926
void r(inout vec2 p, in float a) {p = cos(a)*p + sin(a)*vec2(p.y, -p.x);}
float sb(in vec3 p, in vec3 b) {vec3 d = abs(p) - b; return min(max(d.x,max(d.y,d.z)), 0.) + length(max(d, 0.));}
float sp(in vec3 p, in vec4 n) {return dot(p,n.xyz) + n.w;}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float map(in vec3 p)
{
    p.y += sin(p.z*.5 + T);
    p.x += 2.;
    vec3 c = p*.5;
    p = mod(p-2., 4.)-2.;
    p = abs(p);
    float s = .3;
    float d = sb(p, vec3(s, p.y, s));
    d = smin(d, sp(c+vec3(0., .5, 0.), vec4(0., 1., 0., 1.)), .2);
    d = smin(d, length(cos(p)) - .1, .4);
    for (int i = 0; i < 3; i++)
    {
        p.y -= 1.;
        r(p.xy, PI / 2. + T * float(i));
        r(p.yz, PI / 2. - T * float(i));
        r(p.zx, PI / 4. * c.y + T);
        d = smin(d, sb(p, vec3(s, p.y, s)), .5);
        s *= .75;
    }
    return d;
}

// lj's raymarch from Revision
float df(in vec3 ro, in vec3 rd)
{
    float d = 0.;
    float ii;
    for (int i = 0; i < 100; i++)
    {
        ii = float(i);
        float m = map(ro + rd * d);
        d += m*.9;
        if (abs(m) < 0.02) break;
        if (d > 40.) break;
    }
    return 1.-ii/30.;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy)*2.-1.;
    uv.x *= resolution.x/resolution.y;
    vec3 ro = vec3(uv, -T), rd = normalize(vec3(uv, -1.)), p, n, col;
    float m = df(ro, rd);
    p = ro + rd * m;
    col = vec3(m);
    col = abs(sin(col + vec3(.92424, .122, .5245) + T))+clamp(tan(1.+ T*.5)*.5, .1, .2);
    glFragColor = vec4(1.0-col,1.0);
}
