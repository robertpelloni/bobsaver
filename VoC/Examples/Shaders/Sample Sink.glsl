#version 420

// original https://neort.io/art/c2vodrk3p9f8s59bd46g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
float pi = acos(-1.);
float frame( vec3 p, vec3 b, float e )
{
  p = abs(p)-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float box( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 min2(vec2 a , vec2 b)
{
    if(b.x < a.x)
    {
        a = b;
    }
    return a;
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

float smoothMin(float d1, float d2, float k){
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define PACKIN 1.
#define WALLS  2.
#define LIGHT  3.
#define BODY   4.

vec2 aquarium(vec3 p)
{
    vec2 o = vec2(1.);
    p += vec3(0.,1.,0.);
    o.x = frame(p , vec3(2.5,1.5,2.),0.001 ) - .03;
    vec3 p2 = abs(p) - vec3(0.,2.5,0.);
    vec3 p3 = abs(p) - vec3(3.5,0.,0.);
    float walls = box(p2 , vec3(2.5,1.,2.));
    walls = min(box(p3 , vec3(1.,2.,2.)),walls);
    walls = min(box(p + vec3(0.,0.,3.),vec3(2.5,1.5,1.)),walls);
    if(walls < .01)
    {
        walls -= simplex3d(p * 40.)/200.;
    }
    o = min2(o,vec2(walls,2.));
    return o;
}

vec2 light(vec3 p)
{
    vec2 o = vec2(0.,LIGHT);
    p -= vec3(0.,.5,.0);
    o.x = length(p)-.1;
    return o;
}

vec3 eyePos;
vec2 fish(vec3 p)
{
    vec2 o = vec2(0.,BODY);
    p -= vec3(0.,-1.3,5.);
    float tim = time / 3.;
    float t = floor(tim) + pow(fract(tim),1.3);
    float tt = noise(vec2(t/2.));
    float ttt = noise(vec2(-time,time));
    p.xz *= rot(sin(tt * pi * 2.)/2.);
    p.yz *= rot(sin(tt/2. * pi * 2. + .1)/3.);
    o.x = length(p) - 2.;
    
    vec3 p2 = p;
    vec3 p3 = p;
    //p.xz *= rot(.5);    
    p.z += 1.3;
    eyePos = p;
    o.x = min(o.x , length(p) - 1.);
    p2.y -= 1.;
    p2.x = abs(p2.x) - 2.5;
    p2.z += 0.5;
    p2.y += sin(p2.x + time * 2.)/7.;
    p2.yz *= rot(p2.x * 3.);
    p2.xz *= rot(.0);
    p2.yz *= rot(.7);
    o.x = smoothMin(o.x , frame(p2,vec3(30,.1,.3),.1),3. );
    
    //float sp = length(p) - simplex3d(p/3. + time) * 1.;
    //o.x = smoothMin(o.x , sp,4.);
    return o;
}

vec2 map(vec3 p)
{
    vec2 o = vec2(1.);
    o = min2(o,aquarium(p));
    o = min2(o,light(p));
    o = min2(o,fish(p));
    return o;
}

vec2 march(vec3 cp , vec3 rd)
{
    float depth = 0.;
    for(int i = 0; i < 99 ; i++)
    {
        vec3 rp = cp + rd * depth;
        vec2 d = map(rp);
        if(abs(d.x) < 0.001)
        {
            return vec2(depth,d.y);
        }
        if(depth > 10.)break;
        depth += d.x;
    }
    return vec2(-1.);
}

vec2 mPolar(vec2 p){
  float a = atan(p.y,p.x);
  float r = 0.;
  r = length(p);
  return vec2(a/pi, r);
}

vec3 eye(vec3 p)
{
    vec3 col = vec3(1.);
    if(p.z < 0.)
    {
        vec2 mpol = mPolar(p.xy);
        vec3 blackCol = vec3(1.,1.,1.) * smoothstep( (sin(mpol.x * pi * 18. )+.5 )/2.,1.,.3);
        blackCol = smoothstep(vec3(0.9,.8,.4),blackCol,vec3(min( .44 - length(p.xy)/2. ,1.)));
        col = mix(blackCol *(1.3 -  mpol.y * 1.5),vec3(1.) , step(0.,length(p.xy) - .9) );
        float t = floor(time/2.) + pow(fract(time/2.),2.);
        float shrink = max(abs(sin(sin(t))),.5);
        col *= step(0.,length(p.xy) - .4 * shrink);
        col += 1. - step(0.,length(p.xy) - .2 * shrink);
        
    }
    col *= .8;
    col += vec3(0.,0.,0.) * floor(simplex3d(p * vec3(30.,30.,1.)));
    return col;
}

vec3 getColor(vec2 d, vec3 cp,vec3 rd)
{
     vec3 col = vec3(0.);
    vec3 bcol = col;
    vec3 mat = vec3(1.);
    vec3 pos = cp + rd * d.x;
    vec2 e = vec2(0.,0.01);
    vec3 N = normalize(map(pos).x - vec3(map(pos + e.xyy).x,map(pos + e.yxy).x,map(pos + e.yyx).x) );
    vec3 sun = normalize(vec3(2.,4.,8.));
    sun.xz *= rot(time);

    vec3 lightPos = vec3(0.,0.5,0.);

    //vec3 lightDir = normalize(vec3(0.,pos.yz - lightPos.yz));
    vec3 lightDir = normalize(pos - lightPos);
    float lightDist = length(pos - lightPos);
    float attenuation = (1. / pow(lightDist,2.) );
    float diff = max(0.,dot(N , lightDir)) * attenuation;
    vec3 halfvector = normalize(lightDir + rd);
    float sp = max( 0.,dot(N,halfvector) );
    //fromWater

    float wattenuation = 1. / pow((3. - pos.z),1.3);
    vec3 wlight = normalize(vec3(5.,-1.,-2.));
    float wdiff = max(0.,dot(wlight,N)) * wattenuation ;
    vec3 whalfvector = normalize(wlight + rd);
    float wsp = max(0.,dot(whalfvector , N)) * wattenuation;

    float up = max(0.,dot(vec3(0.,-1.,0.),rd));
    float down = max(0.,dot(vec3(0.,1.,0.),rd));

    // col = vec3(0.,1.,1.)/2.;
    // col += up * vec3(.1);
    // col -= down * vec3(3.);
    // bcol = col;

    if(d.y == PACKIN)
    {
        mat = vec3(0.1);
        diff = mix(1.,diff,1.);
        sp = pow(sp , 10.);

        col = mat * diff + sp;
        col += bcol * wdiff + bcol * wsp; 
    }
    else if(d.y == WALLS)
    {
        mat = vec3(0.8)/10.;
        diff = mix(1.,diff,1.);
        sp = pow(sp , 60.);

        col = mat * diff + sp * vec3(0.2,.8,.9);

        col += (bcol * wdiff + bcol * wsp)/2.; 
    }
    else if(d.y == LIGHT)
    {
        mat = vec3(1.) * 1.;
        diff = .8;

        col = mat * diff + sp;
    }

    return col;
}

vec3 setColor(vec2 d , vec3 cp ,vec3 rd)
{
    vec3 col = vec3(0.);
    vec3 bcol = col;
    vec3 mat = vec3(1.);
    vec3 pos = cp + rd * d.x;
    vec2 e = vec2(0.,0.01);
    vec3 N = normalize(map(pos).x - vec3(map(pos + e.xyy).x,map(pos + e.yxy).x,map(pos + e.yyx).x) );
    vec3 sun = normalize(vec3(2.,4.,8.));
    sun.xz *= rot(time);

    vec3 lightPos = vec3(0.,0.5,0.);

    //vec3 lightDir = normalize(vec3(0.,pos.yz - lightPos.yz));
    vec3 lightDir = normalize(pos - lightPos);
    float lightDist = length(pos - lightPos);
    float attenuation = (1. / pow(lightDist,2.) );
    float diff = max(0.,dot(N , lightDir)) * attenuation;
    vec3 halfvector = normalize(lightDir + rd);
    float sp = max( 0.,dot(N,halfvector) );
    //fromWater

    float wattenuation = 1. / pow((3. - pos.z),1.3);
    vec3 wlight = normalize(vec3(5.,-1.,-2.));
    float wdiff = max(0.,dot(wlight,N)) * wattenuation ;
    vec3 whalfvector = normalize(wlight + rd);
    float wsp = max(0.,dot(whalfvector , N)) * wattenuation;

    float up = max(0.,dot(vec3(0.,-1.,0.),rd));
    float down = max(0.,dot(vec3(0.,1.,0.),rd));

    col = vec3(0.,1.,1.)/2.;
    col += up * vec3(.1);
    col -= down * vec3(3.);
    bcol = col;

    if(d.y == PACKIN)
    {
        mat = vec3(0.1);
        diff = mix(1.,diff,1.);
        sp = pow(sp , 10.);

        col = mat * diff + sp;
        col += bcol * wdiff + bcol * wsp; 
    }
    else if(d.y == WALLS)
    {
        mat = vec3(0.8)/10.;
        diff = mix(1.,diff,1.);
        sp = pow(sp , 60.);

        col = mat * diff + sp * vec3(0.2,.8,.9);

        col += (bcol * wdiff + bcol * wsp ); 
    }
    else if(d.y == LIGHT)
    {
        mat = vec3(1.) * 1.;
        diff = .8;

        col = mat * diff + sp;
    }

    //col = N * .5 + .5;

    if(d.y == BODY)
    {
        mat = eye(eyePos);
        vec2 d2 = march(pos + N * 0.1 ,N);
        vec3 ambCol = getColor(d2,cp,rd);
        mat = mix(mat,ambCol,.5);
        diff = mix(1.,diff,1.);
        sp = pow(sp , 3.) * 10.;
        col = mat * diff + sp;
        col += up * vec3(2.) * mat;
        //col += -down * vec3(3.3);
        float tt = 1.- exp(-0.001 * d.x * d.x * d.x * d.x);
        col = mix(col,bcol , tt);
    }
    return col;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.,0.,1.);
    vec3 bcol = col;
    vec3 mat = col;
    
    vec3 cp  = vec3(0.,0.,-1.5);
    vec3 target = vec3(0.,-.3,.0);
    vec3 cd = normalize(target - cp);
    
    vec3 cs = normalize( cross(cd , vec3(0.,1.,0.)) );
    vec3 cu = normalize( cross(cd , cs) );
    
    float fov = 2.;
    vec3 rd = normalize(fov * cd + cs * p.x + cu * p.y);
    
    vec2 d  = march(cp,rd);
    
    //if(d.x > 0.)
    {
        col = setColor(d,cp,rd);
    }
    
    glFragColor = vec4(col, 1.0);
}
