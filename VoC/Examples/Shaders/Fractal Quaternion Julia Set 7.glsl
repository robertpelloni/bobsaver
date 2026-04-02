#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wtScRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cameraPos = vec3(0., .6, -5.5);
float softShadow = 10.;
float depthmax = 40.; 
const float eps = 1e-4;
vec3 backcol = vec3(1.,1.,1.)*1.;
float inf = 1e20;
float pi=3.14159265;

//SDF operations
//colored
vec4 cun(vec4 d1, vec4 d2){
    return d1.w<d2.w?d1:d2;
}
vec4 cdif(vec4 d1, vec4 d2){
    d2.w*=-1.;
    return d1.w>d2.w?d1:d2;
}
vec4 cmix( vec4 d1, vec4 d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
//uncolored
float un(float d1, float d2){
    return d1<d2?d1:d2;
}
float dif(float d1, float d2){
    d2*=-1.;
    return d1>d2?d1:d2;
}
float smix( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

//additioanal operations
vec4 qxq( in vec4 a, in vec4 b){
    return vec4(
        a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
        a.y * b.x + a.x * b.y + a.z * b.w - a.w * b.z, 
        a.z * b.x + a.x * b.z + a.w * b.y - a.y * b.w,
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y );

}
mat2 ro (float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

//SDF
float sphere(vec3 pos){
    return length(pos);
}
float plane(vec3 n, vec3 pos){
    return dot(pos, n);
}
float capsule(vec3 a, vec3 b, float r1, float r2, vec3 p){
    vec3  ba = b - a;
    float l2 = dot(ba,ba);
    float rr = r1 - r2;
    float a2 = l2 - rr*rr;
    float il2 = 1.0/l2;
    
    vec3 pa = p - a;
    float y = dot(pa,ba);
    float z = y - l2;
    float x2 = dot( pa*l2 - ba*y, pa*l2 - ba*y );
    float y2 = y*y*l2;
    float z2 = z*z*l2;

    float k = sign(rr)*rr*rr*x2;
    if( sign(z)*a2*z2 > k ) return  sqrt(x2 + z2)        *il2 - r2;
    if( sign(y)*a2*y2 < k ) return  sqrt(x2 + y2)        *il2 - r1;
                           return (sqrt(x2*a2*il2)+y*rr)*il2 - r1;
}
float box(vec3 b, vec3 p){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float disk(vec3 p0, vec3 n, float r,vec3 p){
    p-=p0;
    float d = length(p);
    float h = abs(dot(p,n));    
    float R = sqrt(d*d-h*h)-r;
    return (R>0.)?sqrt(h*h+R*R):h;
}
float loop(vec3 p0, vec3 n, float r,vec3 p){
    p-=p0;
    float d = length(p);
    float h = abs(dot(p,n));    
    float R = sqrt(d*d-h*h)-r;
    return sqrt(h*h+R*R);
}
float cylinder(vec3 a, vec3 b, float r, vec3 p){
    p-=a;b-=a;
    float k = dot(b,p)/dot(b,b);
    float d1 = length(b*k-p)-r;
    if(k>0.&&k<1.){
        return d1;
    }else{
        float d2 = (abs(k-.5)-.5)*length(b);
        if(d1>0.){            
            return sqrt(d1*d1+d2*d2); 
        }else{
            return d2;
        }
    }
}
float cut(vec3 p, float r){
    p*=r;
      float da = box(vec3(inf,1.0,1.0),p);
    float db = box(vec3(1.0,inf,1.0),p);
    float dc = box(vec3(1.0,1.0,inf),p);
    return min(da,min(db,dc))/r;
}
float sponge(vec3 p, int L){
    float d = box(vec3(1.,1.,1.),p);
    float s=1.;
    float r=4.;
    do{
        d = max(-cut(p,r/(r-2.))/s,d);
        p = mod((p+1.)*r,2.)-1.;   
        s*=4.;L--;
    }while(L>0&&length(p)<2.5);
    return d;
}
float julia(int L, vec3 p){
    float t = time / 3.0;
    
    vec4 c = 0.5*vec4(cos(t),cos(t*1.1),cos(t*2.3),cos(t*3.1));
    vec4 z = vec4( p, 0.0 );
    vec4 nz;
    
    float md2 = 1.0;
    float mz2 = dot(z,z);

    for(int i=0;i<L;i++){
        md2*=4.0*mz2;
        nz.x=z.x*z.x-dot(z.yzw,z.yzw);
        nz.yzw=2.0*z.x*z.yzw;
        z=nz+c;

        mz2 = dot(z,z);
        if(mz2>4.0){
            break;
        }
    }
    return 0.25*sqrt(mz2/md2)*log(mz2);
}
//color functions
vec3 checkerboard(vec3 p){
    ivec3 d = ivec3(floor(p));
    return vec3(1.)*((d.x+d.y+d.z)%2==0?1.:.8);
}
//scene SDF
vec4 map(vec3 p){
    //"room"
    vec4 d0 = vec4(.9,.9,1.,plane(vec3(0.,1.,0.),p)+1.5);
    d0 = cun(d0,vec4(.9,.9,1.,plane(vec3(0.,0.,-1.),p)+10.02));
    d0 = cun(d0,vec4(.9,.9,1.,plane(vec3(1.,0.,0.),p)+10.02));
    d0 = cun(d0,vec4(.9,.9,1.,box(vec3(1.,1.,1.),p-vec3(0.,-2.,0.))));
    d0.xyz *= checkerboard(p);

    p+=vec3(.0,.1,.0);
    
    //julia set
    vec4 jul = vec4(1.,.9,.9,julia(8,p*.5-vec3(.0,.5,.0)));
    d0 = cun(d0,jul);
    
    return d0;
}
//normal vector by point
vec3 norm(vec3 pos){
    const vec2 e = vec2(eps,0.);
    float d = map(pos).w;
    return normalize(vec3(
        map(pos + e.xyy).w-d,
        map(pos + e.yxy).w-d,
        map(pos + e.yyx).w-d
    ));
}

//color and length of ray
vec4 rayCast(vec3 eye, vec3 dir){
    vec3 pos; float depth=0.,dist;
    vec4 rc;
    const int maxsteps = 500;
    for (int i = 0; i < maxsteps; i++){
        pos = eye + dir * depth;
        rc = map(pos);
        dist = rc.w;
        depth += dist;
        if (dist < eps){
            break;
        }else if(depth>depthmax){
            depth = depthmax+eps;
            break;
        }
    }
    rc.w=depth;
    return rc;
}
// color of lighting for point
vec3 getLight(vec3 p, vec3 lp, vec3 n, vec3 lc, float po, bool mode){
    p += n * eps;
    vec3 ld=mode?lp:lp-p;
    float l = length(ld);ld/=l;
    float diff = dot(ld,n);
    
    float h, c=eps, r=1.;
    
    for (float t = 0.0; t < 50.0; t++){
        h = map(p + ld * c).w;
        if (h < eps){
            return vec3(0.);
        }
        r = min(r, h * softShadow / c);
        c += clamp(h,0.02,2.0);
        if(c>l)break;
    }
    
    return lc*po*r*diff/(l*l);
}
// ambient occlusion by point
float getOcc(vec3 ro, vec3 rd){
    float totao = 0.0;
    float sca = 1.0;

    for (int aoi = 0; aoi < 5; aoi++){
        float hr = 0.01 + 0.02 * float(aoi * aoi);
        vec3 aopos = ro + rd * hr;
        float dd = map(aopos).w;
        float ao = clamp(-(dd - hr), 0.0, 1.0);
        totao += ao * sca;
        sca *= 0.75;
    }

    const float aoCoef = 0.5;

    return totao*(1.0 - clamp(aoCoef * totao, 0.0, 1.0));
}

//full render
void main(void) {

    //direction calculation
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);    
    vec3 eye = cameraPos;
    float angle = (1.2+cos(time*.4))*.6;
    eye.xz*=ro(angle);
    float targetDepth = 2.;
    vec3 dir = normalize(vec3(p,targetDepth));
    dir.xz*=ro(angle);

    //raymarching
    vec4 rc = rayCast(eye, dir);
    float depth = rc.w;

    vec3 pos = eye+dir*depth;
    vec3 n = norm(pos);
    pos+=eps*n;
    
    vec3 col = rc.xyz;
    vec3 lighting = vec3(.25);

    if (depth < depthmax){

        // adding 3 point lights and one directional light
        lighting += getLight(pos, vec3(6., 8., 0.), n, vec3(1.,.9,.9), 15.,false);
        lighting += getLight(pos, vec3(6., 8., -10.), n, vec3(1.,1.,1.), 50.,false);
        lighting += getLight(pos, vec3(-10., 10., -2.), n, vec3(1.,1.,1.), 30.,false);
        lighting += getLight(pos, vec3(2., 13., -10.), n, vec3(1.,.9,.9), 120.,true);
        
        //lighting -= getOcc(pos, n);
        col *= lighting;
    }else{
        col=backcol;
    }
    
    //compositing color, lighting and fog
    glFragColor = vec4(1.5*log(1.+ col)*exp(-0.003*depth), 1.0);
}
