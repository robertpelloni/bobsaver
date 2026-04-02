#version 420

// original https://www.shadertoy.com/view/tlcGz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//modificado por jorge flores.p --2019-dic-07
//Gracias a ....Created by russ in 2017-03-06
//https://www.shadertoy.com/view/XsfczB
    

const int iter =100;
const float eps = 0.001, far = 30.;
vec3 lDir0 = normalize(vec3(1,2,1)), lDir1 = normalize(vec3(-1,1.0,-2));
vec3 lCol0 = vec3(1,.8,.5), lCol1 = vec3(.6,0.8,1); 

float maxcomp(in vec3 p ) { return max(p.x,max(p.y,p.z));}

float sdBox( vec3 p, vec3 b )
{
  vec3  di = abs(p) - b;
  float mc = maxcomp(di);
  return min(mc,length(max(di,0.0)));
}

float cylUnion(vec3 p){
    float xy = dot(p.xy,p.xy);
    float xz = dot(p.xz,p.xz);
    float yz = dot(p.yz,p.yz);
    return sqrt(min(xy,min(xz,yz))) - 1.;
}

float cylIntersection(vec3 p){
    float xy = dot(p.xy,p.xy);
    float xz = dot(p.xz,p.xz);
    float yz = dot(p.yz,p.yz);
    return sqrt(max(xy,max(xz,yz))) - 1.;
}

//-------------------------------------------

float dsSphere(vec3 center, float r, vec3 point)// basic sphere SDF
{
    // point is point pos in space, center is sphere's center, r is its radius
    return length(point - center) - r;
}

float dsCapsule(vec3 point_a, vec3 point_b, float r, vec3 point_p)//cylinder SDF
{
     vec3 ap = point_p - point_a;
    vec3 ab = point_b - point_a;
    float ratio = dot(ap, ab) / dot(ab , ab);
    ratio = clamp(ratio, 0.f, 1.f);
    vec3 point_c = point_a + ratio * ab;
    return length(point_c - point_p) - r;
}

float dsTorus(vec3 center, float r1, float r2, vec3 point)
{
     float x = length(point.xz - center.xz) - r1;
    float y = point.y - center.y;
    float dist = length(vec2(x,y)) - r2;
    return dist;
}
//--------------------------------------------

float DE(vec3 p){
    
    //float d = cylIntersection(p);
    float d;
    float distToCapsule = dsCapsule(vec3(-0.f,0.0f,0.f), vec3(2.f,1.f,0.1f), 1.f, p);    
    
    d=distToCapsule;
    
    float s = 1.;
    
    
    for(int i = 0;i<5;i++){
        p *= 3.;
        s*=3.;
        float d2 = cylUnion(p) / s;
        
        
        float d3=sdBox(p, vec3(2.0,1.0,2.5));
        //d2=d2*d3/2.0;
            
        float m = -1.0; //texelFetch(iChannel0, ivec2(32, 0), 0).x * 2. - 1.;
        d = max(d,m*d2);
            p = mod(p+1. , 2.) - 1.;     
    }
    return d;
}

vec2 march(vec3 ro, vec3 rd){
    float t=0. , d = far, it = 0.;
    for (int i=0;i<iter;i++){
         t += (d = DE(ro+t*rd));
        if(d<eps || t> far) break;
        it += 1.;
    }
    return vec2(t,it/float(iter));
}

float getShadow(vec3 p, vec3 n, vec3 ld){
    p +=  2. * eps * n;
    float t=0.,d=far;
    for(int i=0;i<50;i++){
        t += (d=DE(p + t*ld));
        if (d<eps || t>3.) break;
    }
    return t<=3. ? 0.1 : 1. ;
}

vec3 getRay(vec3 ro, vec3 look, vec2 uv){
    vec3 f = normalize(look - ro);
    vec3 r = normalize(vec3(f.z,0,-f.x));
    vec3 u = cross (f,r);
    return normalize(f + uv.x * r + uv.y * u);
}

vec3 getNorm(vec3 p){
    vec2 e = vec2(eps, 0);
    return normalize(vec3(DE(p+e.xyy)-DE(p-e.xyy),DE(p+e.yxy)-DE(p-e.yxy),DE(p+e.yyx)-DE(p-e.yyx)));
}

vec3 light(vec3 p, vec3 n){
    vec3 col = vec3(0);
    for(int i=0;i<2;i++){
        vec3 ld = (i==0) ? lDir0 : lDir1;
        float diff = max(dot(n, (ld)),0.);
        diff *= getShadow(p, n, ld);
        col += diff * (i==0 ? lCol0 : lCol1);
    }
    return col * .7;
}

void main(void)
{
    //float time = time * .04;
    float time = time * .6;
    
    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    float s1 = sin(time), c1 = cos(time);
    float arg = 1.5*sin(time*.7894)*.5 + .5;
    float s2 = sin(arg), c2 = cos(arg);
    
    vec3 ro = vec3(0, .2, 1)*5.5;
    
    
    ro.yz = mat2(c2,-s2,s2,c2)*ro.yz;
    ro.xz = mat2(c1,s1,-s1,c1)*ro.xz;
    
    vec3 rd = getRay(ro, vec3(0.), uv);
    vec2 hit = march(ro, rd);
    vec3 p = ro + hit.x*rd;
    vec3 col = hit.x<far ? light(p, getNorm(p)) : vec3(.1*(1.-length(uv)));
    col += pow(hit.y,3.);
    glFragColor = vec4(sqrt(col),1.0);
}
