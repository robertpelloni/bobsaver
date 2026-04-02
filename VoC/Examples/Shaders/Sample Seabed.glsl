#version 420

// original https://neort.io/art/bnocdf43p9f5erb53p1g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float PI = acos(-1.);
float PI2 = PI * 2.;

mat2 rot(float a)
{
    float s = sin(a),c = cos(a);
    return mat2(c,s,-s,c);
}

//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float sdSphere(vec3 p , float s)
{
    return length(p) - s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}
//-----------------------------------------------------------

//https://www.youtube.com/watch?v=aNR4n0i2ZlM&feature=youtu.be
float sdHeart(vec3 p , float s )
{
    p.y /= 1.5;
    s = s + pow( (0.5 + 0.5 *sin(2.*PI * time + p.y*4.) ) * 0.6 ,4.);
    p.x =  p.y - abs(p.x) * sqrt((20. - abs(p.x)) / 15.);
    p.y *= 1.2;
    
    return length(p) - s;
}

//https://qiita.com/kaneta1992/items/21149c78159bd27e0860
vec2 pmod(vec2 p , float r)
{
    float a = atan(p.x,p.y) + PI/r;
    float n = PI2 / r;
    a = floor(a/n) * n;
    return p * rot(-a);
}

vec2 map(vec3 p)
{
    vec3 heart = p;
    vec3 sep = vec3(.7);
    heart.xz = pmod(heart.xz , 16.);
    
    heart.y -= time;
    heart.xyz = sin(heart.xyz*sep);
    heart.xz *= rot(time);
    
    vec3 sp = p;
    sp.xz  = sin(sp.xz + heart.zx * heart.y * heart.xz);
    sp.xz *= rot(sp.y*heart.y + time);
    float s = sdHeart(heart,0.4 );
    float pl = p.y + .25;
    float sb = sdBox(sp,vec3(.1,3.,.1));
    sp.y-= 2.;
    sp.y = sin(sp.y-time);
    float sb2 = sdSphere(sp,.3);
    float sb3 = sdBox(sp,vec3(0.3));
    sb2 = mix(sb2,sb3,clamp(sin(time + heart.y *6.),0.,1.));
    sb = smin(sb,sb2,0.5);
    
    float id = (pl > s)?0.:1.;
    float mm = sminCubic(sminCubic(s,pl,1.9),sb,0.6);
    return vec2(mm,id);
}

vec3 marching(vec3 ro,vec3 rd)
{
    float depth = 0.;
    float cyc = 0.;
    float id = -1.;
    for(int i = 0; i < 100 ; i++)
    {
        vec3 rp = ro + rd * depth;
        vec2 d = map(rp);
        if(d.x < 0.001 * (depth * 3.) )
        {
            id = d.y;
            cyc = float(i);
            break;
        }
        if(d.x > 20.){break;}
        depth += d.x;
    }
    depth = (depth > 20.)?-1.:depth;
    return vec3(depth,id,cyc);
}

//http://sayachang-bot.hateblo.jp/entry/2019/08/16/215059
vec3 calcNormal(vec3 p)
{
    vec2 e=vec2(.001,.0);
    return normalize(.000001+map(p).x-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}

float eq(float a, float b)
{
    return 1. - abs(sign(a - b));
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    p.y = -p.y;
    
    vec3 f = vec3(1.,0.,0.) * sin(time/5. ) * 3.;
    vec3 co = vec3(0.,7.5,-55.) + f;
    
    co.xz *= rot(time/100.);
    
    vec3 target = vec3(0.,-50.,0.) + f;
    
    target.xy *= rot(time/5.);
    target.z += cos(time/10.);
    
    vec3 cd = normalize(target - co);
    vec3 cu = vec3(0.,1.,0.);
    vec3 cs = normalize(cross(cu , cd));
    cu = normalize(cross(cs , cd));
    
    float fov = (1.-  dot(p,p)/3.);
    vec3 rd = normalize(vec3(cs * p.x + p.y * cu + fov * cd));
    
    vec3 d = marching(co,rd);
    float rl = (dot(vec3(0.,1.,0.),rd)+1.);
    float cl = clamp(dot(vec3(0.,1.,0.),cd),0.,1.);
    vec3 skyColor = vec3(0.05,.4,.2) * rl*cl + cl*rl/2.;
    vec3 color = skyColor;

    if(d .x> 0.){
        vec3 N = calcNormal(co + rd * d);
        float ao = (d.z/100.)*2.;
        float id = d.y;
        vec3 sun_dir=normalize(vec3(.8,.4,.2));
        vec3 mate = eq(id,0.) * vec3(.6,0.,0.) +
                                eq(id,1.) * vec3(0.18);
        float diff = clamp(dot(N,sun_dir),0.,1.);
        float shd = step(marching(co + rd *d.x + N* 0.001 , sun_dir).x, 0.);
      //  float sss = marching(co + rd * d.x * 0.01, sun_dir).x;
        float sky = (0.5 + 0.5 * dot(N,vec3(0.,1.,0.)),0.,1.);
        float gro = clamp(0.5 + 0.5 * dot(N , vec3(0.,-1.,0.)),0.,1.);
        
        color=mate*vec3(7.,4.5,3.)*diff*shd;
        color=mate*vec3(.9,.4,.8)*sky;
           color+=mate*vec3(.6,.3,.2)*gro;
       // color += abs(1./sss);
        color = mix(color,skyColor,ao);
    }
    color = pow(color , vec3(0.4545));
    glFragColor = vec4(color, 1.0);
}
