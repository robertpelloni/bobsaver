#version 420

// original https://www.shadertoy.com/view/tdBGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// An attempt to express 'the symbol' as a Distance Field using some simple shapes and modifiers...
//
// I suck at modelling!

#define PI 3.141592
#define    TAU 6.28318

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// simple bend(Y) mod
vec2 opBendTest( vec2 p, float angle, float xmod )
{
    p.x += xmod;
    p = rotate( angle * p.x ) * p.xy;
    p.x -= xmod;
    return p;
}
// simple spriral(x) mod
float spiral(vec2 p, float sa, float b)
{
  float a = atan(p.y, p.x);
  float l = length(p);
  float n = (log(l/sa)/b - a) / (2.*PI);
  float upper_ray = sa * exp(b *(a + 2.*PI*ceil(n)));
  float lower_ray = sa * exp(b *(a + 2.*PI*floor(n)));
  return min(abs(upper_ray - l), abs(l-lower_ray));
}

// 2D-shapes (Trapezoid, Ring, Box, Triangle)
float dot2(in vec2 v ) { return dot(v,v); }
float sdTrapezoid( in vec2 p, in float r1, float r2, float he )
{
    vec2 k1 = vec2(r2,he);
    vec2 k2 = vec2(r2-r1,2.0*he);

    p.x = abs(p.x);
    vec2 ca = vec2(p.x-min(p.x,(p.y < 0.0)?r1:r2), abs(p.y)-he);
    vec2 cb = p - k1 + k2*clamp( dot(k1-p,k2)/dot2(k2), 0.0, 1.0 );
    
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    
    return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float ring(vec2 uv, float rad, float thickness)
{
    return abs(rad - length(uv)) - thickness;
}

float sdBox( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p) - b;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}    

// signed distance to a 2D triangle
float sdTriangle( in vec2 p0, in vec2 p1, in vec2 p2, in vec2 p )
{
    vec2 e0 = p1 - p0;
    vec2 e1 = p2 - p1;
    vec2 e2 = p0 - p2;

    vec2 v0 = p - p0;
    vec2 v1 = p - p1;
    vec2 v2 = p - p2;

    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));

    return -sqrt(d.x)*sign(d.y);
}

float NewSymbol(vec2 uv)
{
    vec2 p = uv+vec2(0.27,0.09);
    float s1 = length(p)-0.2;                        // circle1
      float s2 = length(p+vec2(-0.22,-0.01))-0.18;    // circle2
    p.x = spiral(p.xy, PI*0.5, -0.33);                // Spiral distort
    float d = sdTrapezoid(p,0.015,0.015,0.08);        // could just be a box...
    d = max(d, s1);                                    // subtract circle
    d = max(d,-s2);                                    // subtract circle

    p = vec2(abs(uv.x),uv.y);
    d = min(d,sdTriangle(vec2(-0.155,0.1),vec2(-0.055,0.1),vec2(-0.105,0.05),p.yx)); // mid-cross tri
    d = min(d,sdBox(p+vec2(-0.05,0.105),vec2(0.025,0.025)));                        // mid-cross bar
    d = min(d,sdTriangle(vec2(0.0, -0.425),vec2(0.1, -0.25),vec2(-0.025, -0.35),p.xy)); // bottom triangle
    
    p = opBendTest(uv+vec2(0.16, -0.088),radians(77.0),-0.103);
    d = smin(d, sdTrapezoid(p.yx,0.018,0.025,0.19), 0.012); // bent arm (attempted to smooth the join, needs work)

    d = min(d,ring(uv+vec2(0.0,-0.26),0.13,0.028));            // top-ring
    d = min(d,sdBox(uv+vec2(0.0,0.13),vec2(0.032,0.2)));    // main body
    d = min(d,sdBox(uv+vec2(-0.08,-0.085),vec2(0.09,0.025))); // horn1 (bar)

    float cuts = length( uv+vec2(-0.17,-0.32))-0.21;
    cuts = min(cuts,length( uv+vec2(-0.17,0.15))-0.21);
    cuts = min(cuts,length( uv+vec2(-0.73,-0.085))-0.4);
    p = uv+vec2(-0.26,-0.085);
    d = min(max(sdTrapezoid(p.yx,0.025,0.13,0.09),-cuts),d); // horn2 (cutout)
    return d;
}

float map(vec3 p)
{
    float time = time+0.2;
    p.z -= 1.5;
    
    float twist = 0.5+sin(fract(time*0.4)*TAU)*0.5;
    twist *= p.y * 1.5;
    p.xz *= rotate(twist+fract(time*0.26)*TAU);
    
    float dist = NewSymbol(p.xy);
    
    float dep = 0.02;
    vec2 e = vec2( dist, abs(p.z) - dep );
    dist = min(max(e.x,e.y),0.0) + length(max(e,0.0));
    dist -= 0.01;
    return dist;
}

// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ.
vec3 normal( in vec3 p )
{
    // Note the slightly increased sampling distance, to alleviate
    // artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.0025, -0.0025); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

vec3 render(vec2 uv)
{
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(uv, 2.95));
    vec3 p = vec3(0.0);
    float t = 0.;
    for (int i = 0; i < 120; i++)
    {
        p = ro + rd * t;
        float d = map(p);
        if (d < .001 || t > 20.) break;
        t += d*0.75;
    }
    
    vec3 c = vec3(0.35,0.35,0.45);
    c*= 1.2-abs(uv.y);
    
    if (t<20.0)
    {
           vec3 lightDir = normalize(vec3(1.0, 1.0, 0.5));
        vec3 nor = normal(p);

        float dif = max(dot(nor, lightDir), 0.0);
        c = vec3(0.5) * dif;

        float tf = 0.16;
        c += vec3(0.65,0.6,0.25) + reflect(vec3(p.x*tf, p.y*tf,p.z*tf), nor);

        vec3 ref = reflect(rd, nor);
        float spe = max(dot(ref, lightDir), 0.0);
        c += vec3(2.0) * pow(spe, 32.);
    }

    c *= 1.0 - 0.3*length(uv);
    return c;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.);
}

