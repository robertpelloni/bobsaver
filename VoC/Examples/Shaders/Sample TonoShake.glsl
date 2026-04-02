#version 420

// original https://neort.io/art/bo5vkh43p9fc827hcei0

precision highp float;
uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.);
float pi2 = pi * 2.;

mat2 rot(float a)
{
  float s = sin(a), c = cos(a); 
   return mat2(c,s,-s,c);
}

float lpnorm(vec3 p, float n)
{
    vec3 t=pow(abs(p),vec3(n));
    return pow(t.x+t.y,1./n);
}

float maxes(vec3 p)
{
    return max(max(p.x,p.y),p.z);
}

float mines(vec3 p)
{
    return min(min(p.x,p.y),p.z);
}

float absmap(vec3 p,vec3 size,float s)
{
    p/=6.;
    p = abs(p) - size ;
    float o = 0.;
    o = lpnorm(p,s);
    //o = maxes(p);
   // o = mines(p);
    return o;
}

float cube(vec3 p,vec3 size)
{
    p = abs(p) - size;
    return max(max(p.x,p.y),p.z);
}

float cubem(vec3 p,vec3 size)
{
    p.xz += exp((-sin(p.y *1.+ time)+1.));
    p = abs(p) - size;
    return max(max(p.x,p.y),p.z);
}

float random(vec2 p)
{
    float s = dot(p.x,1234.5);
    float t = dot(p.y,3456.7);
    return fract(sin(s+t)*123.5);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float smoothMin(float d1, float d2, float k){
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

vec2 map(vec3 p)
{
    
    vec2 id = floor(p.xz /8.);
    //p.xy *= rot(time/2. + random(id)*6.7);
    //p.yz = mod(p.yz,10.) - 5.;
    //p.y += sin(length(id) + time)*13.;
    vec3 op = p;
    
   
    vec3 cubesize = vec3(3.6) + clamp(sin((time + (p.z)/50.)*14.),0.,1.)*1.5;
    vec3 cp = p;
    //cp.xy += random(vec2(floor(time*2. ))) * 5.;
    float cc = cube(cp,cubesize);
    //vec3 pp = p;
    
    //pp.xz += vec2(2.) * rot(time/1. + length(id)*10.);
    
    //float sp = length(pp)-.6;
    
    op.xy *= rot(time/2.5);
    
    //op = mod(op,100.) - 50.;
    
    float dd =10.*( sin(time)+1.1)/2.;
    float ss = absmap(op,vec3(1.5) * (sin(time*2.+op.z/5.9)+1.1)*4.,dd);
    
    op = sin(op/17.+time/20.)*16.;
    op.yz *= rot(pi/2.);
    for(int i = 0; i < 3;i++)
    {
       // op = op + floor(op * (sin(time *16.)+1.) / 2.);
        op.xz *= rot(pi/2.);
        op.x += 1.1;
        ss = min(ss,absmap(op,vec3(1.5) * (sin(time*2.+op.z/5.9)+1.1)*4.,dd));
    }
    op.xz *= rot(time);
    float s = cube(cp,vec3(0.6,2.9,0.6) + fract(time)*2. );
   // ss = min(ss,ss2);
    ss = smoothMin(ss,s,5.21+ .5 * sin(time));
   // return ss;
    float ox =smoothMin(ss,cc,1.2);
    float oy = (ss > cc)?0.:1.;
    return vec2(ox,oy);
}

vec2 marching(vec3 cp,vec3 rd)
{
    float depth = 0.;
    vec2 o = vec2(-1.);
    for(int i = 0 ; i < 99; i++)
    {
        vec3 rp = rd * depth  + cp;
        vec2 d = map(rp);
        if(d.x < 0.001 + depth * .001)
        {
            o.x = depth;
            o.y = d.y;
            break;
        }
        if(depth > 126.){break;}
        depth += d.x;
    }
    return o;
}

//http://sayachang-bot.hateblo.jp/entry/2019/08/16/215059
vec3 calcNormal(vec3 p)
{
    vec2 e=vec2(.001,.0);
    return normalize(.000001+map(p).x-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}

//https://qiita.com/keim_at_si/items/c2d1afd6443f3040e900
vec3 hsv2bgr(float h,float s,float v)
{
    return ((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
   
    vec3 forward = (vec3(0.,0.,1.6) ) * time  *0.;
    vec3 cp = vec3(15.,19.,-15.) + forward;
    
    cp = sin(cp/100.);
    cp.z += clamp( exp(-sin(time)*10.-2.),-20.,3.) * 23.;
    cp.y += cos(time/2.) * 28.;
    cp.x += sin(floor(time*2.+dot(p,p)/10. )) * 70.;
    cp .xz *= rot(time);
    cp.yz *= rot(floor(time));
    vec3 target = vec3(1.,0.,0.) + forward;
    vec3 cd = normalize(vec3(target - cp));
    vec3 cu = vec3(0.,1.,0.);
    vec3 cs = normalize(cross(cd,cu));
    cu = normalize(cross(cs,cd));
    float fov = (1.4- dot(p,p)) ;
    fov = pow(fov,3.);
    //fov = 2.1;
     p = sin(p * 1.5);
    vec3 rd = normalize(vec3(p.x * cs + p.y * cu + cd* fov));
    
    vec3 color = vec3(.0);
    vec3 sky = vec3(0.01,0.01,0.05) + (cd + rd) *vec3(.1,.01,.3);
    sky *= sin(cp * rd);
    //sky = vec3(1.) - sky;
    color = sky;
    
    vec2 d = marching(cp,rd);
    if(d.x > 0.)
    {
        float sep = clamp(3./pow(d.x,4.),0.,1.) * .1 + .9 ;
        
        vec3 light = normalize(vec3(.8,.4,.2));
        vec3 normal = calcNormal(d.x * rd + cp);
        float diff = clamp(dot(light , normal),0.,1.)* .3 + .7;
        float h = d.x/100.;
        float s = 1.;
        float v = 2. + sin(time/2.);
        color = clamp(hsv2bgr(h,s,v) - d.y/1.1,0.,1.);
       // float n = marching(d.x * rd + cp + 0.1,normal).x;
        color += (1. - d.y) * color * (sin(time + d.x/10000.)+1.);
        color += d.y * clamp(sin((time+ d.x*3.)/3.),0.,.1) * vec3(120.5) * color;
        //color = (color.x + color.y + color.z < 0.5)?sky:color;
        color = color * diff;
        color = mix(sky,color,sep);    
    }
    
    color = pow(color , vec3(0.4545));
    glFragColor = vec4(color, 1.0);
}
