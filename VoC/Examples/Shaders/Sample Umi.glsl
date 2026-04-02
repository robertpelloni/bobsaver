#version 420

// original https://neort.io/art/bovaihk3p9fd1q8oeue0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

mat2 rot(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float rand(vec2 p)
{
    return sin(fract(dot(p,vec2(1234.5,678.91))));
}

vec3 rand13(float p)
{
    float o = rand(vec2(p,123.456));
    float t = rand(vec2(p,o));
    float th = rand(vec2(t,o));
    return sin(vec3(o,t,th));
}

vec3 random33(vec3 st)
{
    st = vec3(dot(st, vec3(127.1, 311.7,811.5)),
                dot(st, vec3(269.5, 183.3,211.91)),
                dot(st, vec3(511.3, 631.19,431.81))
                );
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec4 celler3D(vec3 i,vec3 sepc)
{
    vec3 sep = i * sepc;
    vec3 fp = floor(sep);
    vec3 sp = fract(sep);
    float dist = 5.;
    vec3 mp = vec3(0.);

    for (int z = -1; z <= 1; z++)
    {
        for (int y = -1; y <= 1; y++)
        {
            for (int x = -1; x <= 1; x++)
            {
                vec3 neighbor = vec3(x, y ,z);
                vec3 pos = vec3(random33(fp+neighbor));
                pos = sin( (pos*6. +time/2.) )* 0.5 + 0.5;
                float divs = length(neighbor + pos - sp);
                mp = (dist >divs)?pos:mp;
                dist = (dist > divs)?divs:dist;
            }
        }
    }
    return vec4(mp,dist);
}

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

//https://www.shadertoy.com/view/XsX3zB
/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
    /* 1. find current tetrahedron T and it's four vertices */
    /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
    /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

    /* calculate s and x */
    vec3 s = floor(p + dot(p, vec3(F3,F3,F3)));
    vec3 x = p - s + dot(s, vec3(G3,G3,G3));

    /* calculate i1 and i2 */
    vec3 e = step(vec3(0.,0.,0.), x - x.yzx);
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
    return dot(d, vec4(52.0,52.0,52.0,52.0));
}

float map(vec3 p)
{
    return length(p - (sin(p * 6. + time))  ) - .7;
}

float march(vec3 cp, vec3 rd)
{
    float depth = 0.;
    for(int i = 0; i < 3; i++)
    {
        vec3 rp = cp + rd * depth;
        float d = map(rp);
        depth += 0.01;
    }
    return -1.;
}

float gedray(vec3 cp,vec3 rd,vec3 sund)
{
    float r = 0.;
    float depth = 0.;
    for(int i = 0; i < 6 ; i++)
    {
        vec3 rp= cp + rd * depth;
        vec3 rps = rp + (simplex3d(rp * 5.1 + vec3(1.,1.,-1.) * sin(time/12.))-.5)/10.;
        float d =  1. - celler3D(rps,vec3(15.)).w;
        r += smoothstep(.0,.7,clamp(d-0.4,0.,0.8))/mix(2.,29.,clamp((sin(time + length(rps.xy) * 25.)+1.)/1.6,0.,1.));
        r += max(step(0.9,d),.1)/7.;
        depth += 0.1;
    }
    return r;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    
    vec3 forward = vec3(0.,1.,1.) * time/6. ;
    vec3 cp = vec3(0.,0.,-5.) + forward;
    vec3 target = vec3(0.,0.,10.) + forward;
    
    target.y += sin(time/2.)  * 2.5;
    target.xz = (target.xz - forward.xz) * rot(time) + forward.xz;
    vec3 cd = normalize(target - cp);
    vec3 cu  = vec3(0.,1.,0.);
    vec3 cs = normalize(cross(cu , cd));
    cu  = normalize(cross(cs , cd));
    
    float fov = .3;// - dot(p,p);
    vec3 rd = normalize(fov * cd + cs * p.x + cu * p.y);
    
    float d = march(cp,rd);
    
    vec3 rp = cp + rd;
    vec3 color = vec3(0.);
    vec3 sun = normalize(vec3(.2,.4,.8));
    vec3 sky = normalize(vec3(0.,-1.,0.)-vec3(sin(time + rp * 1.6)));
    float rdsky = max(0.,dot(rd,sky));
    rp.xz += (simplex3d(rp * 5.1 + vec3(1.,1.,-1.) * sin(time/2.))-.5)/10.;
    float c = celler3D(vec3(rp.x,0.,rp.z),vec3(5.) ).w;
    
    float godray = gedray(cp,rd,sky);
    color += normalize(vec3(.1,1.,1.)) * (rdsky * max(c,.4) );
    color += normalize(vec3(1.6,2.7,2.6)) * godray * (1.5 - rdsky);
    color = clamp(color,0.,1.);
    glFragColor = vec4(color, 1.0);
}
