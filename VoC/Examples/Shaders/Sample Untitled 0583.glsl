#version 420

// original https://www.shadertoy.com/view/wdtBz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float t = 0.;
float pi = acos(-1.);

#define MAX 100.

vec2 min2(vec2 a,vec2 b)
{
    if(a.x < b.x){
        return a;
    }
    return b;
}

float rand(vec2 a)
{
    return fract(sin(dot(a,vec2(123.45,67.89))*123.4 ));
}
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

//カンニングします
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

vec3 simplex3dVector(vec3 p)
{
    float s = simplex3d(p);
    float s2 = simplex3d(random3(vec3(p.y,p.x,p.z)) + p.yxz);
    float s3 = simplex3d(random3(vec3(p.z,p.y,p.x)) + p.zyx);
    return vec3(s,s2,s3);
}

vec2 map(vec3 p)
{
    vec2 d = vec2(100.);
    d.x = length(p) - .5;
    d.x = p.y + .7;
    
    if(d.x < 1.)
    {
        d.x -= simplex3d(vec3(p.x,0.,p.z ) * 40. + t* .8)/100.;
        d.x -= simplex3d(vec3(p.x,0.,p.z ) * .6)/50.;
        d.x -= simplex3d(vec3(p.x,0. + t / 2.,p.z ) * .2)/1.1;
        d.y = 0.;
    }
    vec3 p2 = p;
    p.xy *= rot(floor(p.z/pi));
    p = cos(p) * 1.;
    p.y -= sin(floor(p2.z/pi) + t);
    p.x -= cos(floor(p2.z/pi) + t/2.) * .1;
    d = min2(vec2(length(p) - .7,1.),d);
    d.x *= .7;
    return d;
}

vec2 march(vec3 cp,vec3 rd)
{
    float depth = 0.;
    float id = 0.;;
    for(int i = 0 ; i < 256 ; i++)
    {
        vec3 rp = rd * depth + cp;
        vec2 d = map(rp);
        if(abs(d.x) < 0.0001)
        {
            depth *= -1.;
            id = d.y;
            break;
        }
        if(depth > MAX){break;}
        depth += d.x;
    }
    depth *= -1.;
    return vec2(depth,id);
}

float water(vec3 cp , vec3 rd,float maxdepth)
{
    float ac = 0.;
    float depth = 0.;
    for(int i = 0; i < 66 ; i++)
    {
        vec3 rp = cp + rd * depth;
        
       // rp = simplex3dVector(rp);
        float d = simplex3d(rp + vec3(0.,-t/8.,0.)) - .1  * abs(sin(0.7 * 1.2 + pi/2. * (simplex3d(rp /10.) - .5 )) - .1);
        d = max(0.01,abs(d));
        ac += exp(-d * .0000001);
        if(depth > maxdepth){break;}
        depth += d;
    }
    return ac - depth * depth;
}

void getCamra(vec2 p,out vec3 cp,out vec3 rd)
{
    t = time;
    vec3 forward = vec3(0.,0.,0.);
    forward.z += t/2.;
    vec3 target = vec3(0.,0.,0.) + forward;
    cp = vec3(0.,0.,-15.) + forward;
    vec3 cd = normalize(target - cp);
    vec3 cs = normalize(cross(cd,vec3(0.,1.,0.)));
    vec3 cu = normalize(cross(cd,cs));
    p.y *= -1.;
    float fov = 2.5 - dot(p,p)/6.;
    //fov  = 2. - dot(p,p) * 6.;
    rd = normalize(p.x * cs + p.y * cu + cd * fov);
}

void main(void)
{
   vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
   vec3 cp,rd;
    getCamra(p,cp,rd);
    vec2 d = march(cp,rd);
    vec3 color = vec3(0.);
    
    if(d.x > 0.)
    {
        vec3 pos = d.x * rd + cp;
        vec2 e = vec2(0.,0.001);
        vec3 N = normalize(vec3( map(pos).x - vec3(map(pos - e.yyx).x,map(pos - e.yxy).x , map(pos - e.xyy).x) ));
         //color = N;
        vec3 sun = normalize(vec3(2.,4.,8.));
        sun.xz *= rot(2.1);
        float diff = mix(max(dot(sun,N),0.),1.,0.);
        float aor = d.x/MAX;
        float ao = exp2(pow(max(0.,1. - map(pos + N * aor).x/aor),1.));
        float fr = pow(1. + dot(N,rd),4.);
        float spo = mix(3.,6.,d.y);
        float sss = smoothstep(0.,1.,map(pos+sun * .4).x / .4);
        float sp = pow(max(dot(reflect(-sun,N),-rd),0.),spo);
        
       // color = vec3(.6) * diff;
        color = mix(sp + mix(vec3(1.,0.8,.3),vec3(0.,.8,.5),d.y) * ao * (diff + sss),color,min(fr,.5));
        float m = 1. - exp(-.000003 * d.x * d.x * d.x);
           color = mix(color,vec3(0.),m);
    }else{
        d.x = MAX;
    }
    float ac = water(cp,rd,d.x);
    vec3 wcolor = normalize( vec3(0.,1.,.5) ) * max(0.,ac)/130.;
    color = clamp(color/4. + wcolor,vec3(0.),vec3(1.));
    
    glFragColor = vec4(color, 1.0);
}
