#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3l2yDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cameraPos = vec3(0., 2., -6.5);
float softShadow = 10.;
float depthmax = 50.; 
const float eps = 1e-3;
vec3 backcol = vec3(.6,.7,1.);
float inf = 1e20;
float pi=3.14159265;

//additioanal operations
mat2 ro (float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}
//SDF operations
//colored
vec4 cun(vec4 d1, vec4 d2){
    return d1.w<d2.w?d1:d2;
}
vec4 cdif(vec4 d1, vec4 d2){
    d2.w*=-1.;
    return d1.w>d2.w?d1:d2;
}
vec4 cmix(vec4 d1, vec4 d2, float k) {
    float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
//uncolored
float un(float d1, float d2){
    return d1<d2?d1:d2;
}
float smix( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
//SDF
float sphere(vec3 pos){
    return length(pos);
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

//texturing functions
bool cb3(vec3 p){
    ivec3 d = ivec3(floor(p));
    return (d.x+d.y+d.z)%2==0;
}
bool cb1(float p, int i){
    int d = int(floor(p));
    return d%i==0;
}

//bee SDF with color
vec4 bee(vec3 p0, float a, float b, float c, float s, vec3 p){    
    p-=p0;s/=2.;
    p/=s;
    p.xz*=ro(a);
    p.xy*=ro(b);
    p.yz*=ro(c);
    vec4 body = vec4(cb1(p.z * 5. + .8 ,3)?vec3(.3,.3,.2):vec3(.7,.7,.3), sphere(p-vec3(.0,.0,0.))-1.3);        

    //sting    
    vec4 sting = vec4(.15,.15,.15,capsule(vec3(0.,0.,0.),vec3(0.,0.,-2.2),.3,.01,p));
    body = cun(body,sting);
    
    //legs
    p.x=abs(p.x);    
    vec3 p_=p;  
    float leg=1e20;
    for(int i=0;i<3;i++){
        leg = un(leg,capsule(vec3(.5,-1.5,.5),vec3(.4,-.9,.5),.15,.2,p_));
        p_.z+=.5;
    }
    p_=p;        
    body = cun(body,vec4(.1,.1,.1,leg));
        
    //eyes    
    vec4 eye = vec4(1.,1.,1.,sphere(p_-vec3(.6,0.8,1.))-.7);
    eye = cun(eye,vec4(.1,.1,.1,sphere(p_-vec3(.6,0.8,1.2))-.55));
    p_-=vec3(.7,1.5,1.);
    p_.xy*=ro(-.25);
    eye = cun(eye,vec4(.2,.2,.2,box(vec3(.6,.1,.2),p_)));        
    body = cun(body,eye);
    p_=p;
    
    //wings    
    p_.xy *= ro(.1*sin(time*30.));
    vec4 wing = vec4(.9,.9,1.,disk(vec3(.9,1.,-0.8),normalize(vec3(-1.,1.,0.3)),.8,p_)-.07);        
    body = cun(body,wing);
    
    return body*s;

}

//scene SDF
vec4 map(vec3 p){
    vec4 d0 = vec4(.9,.9,1.,-box(vec3(20.,20.,20.),p-vec3(0.,18.,0.)));
    d0.xyz *= vec3(cb3(p)?.6:.8);
    //d0.xyz *= vec3(0.,0.,inf);
    //greenscreen
    
    float t1 = .1*sin(time*.3);
    float t2 = .1*sin(time*.26);
    float t3 = .1*sin(time*.22);
    
    d0 = cun(d0, bee(vec3(-0.3,0.8+t1,-1.8),2.3,0.0+t2,-.3,1.5,p));
    d0 = cun(d0, bee(vec3(-1.3,4.0-t2,0.5),1.2,0.0-t3,-0.4,1.5,p));
    d0 = cun(d0, bee(vec3(0.9,3.9+t3,3.2),3.3,0.0-t1,-0.4,1.5,p));
    
    return d0;
}
//normals
vec3 norm(vec3 p){
    const vec2 e = vec2(eps,0.);
    float d = map(p).w;
    return normalize(vec3(
        map(p + e.xyy).w-d,
        map(p + e.yxy).w-d,
        map(p + e.yyx).w-d
    ));
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
//light from all sources + occlusion by point
vec3 getFullLight(vec3 pos, vec3 n){   
    pos+=eps*n;
    vec3 col;
    //vec3 col = map(pos).xyz;
    vec3 lighting = vec3(.25);

    if (length(pos) < depthmax){
        // adding 3 point lights and one directional light
        lighting += getLight(pos, vec3(6., 6., 6.), n, vec3(1.,.9,.9), 50.,false);
        lighting += getLight(pos, vec3(6., 10., -6.), n, vec3(1.,1.,1.), 50.,false);
        lighting += getLight(pos, vec3(-6., 6., 6.), n, vec3(1.,1.,1.), 50.,false);
        lighting += getLight(pos, vec3(3., 3., -6.), n, vec3(1.,.9,.9), 50.,false);
        
        col = lighting;
    }else{
        col = backcol;
    }
    return col;
}
//direction of ray by pixel coord
vec3 getDir(float angle){
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);    
    vec3 eye = cameraPos;
    float targetDepth = 2.;
    vec3 dir = normalize(vec3(p,targetDepth));
    dir.xz*=ro(angle);
    return dir;
}
//raymarching
vec3 rayCast(vec3 eye, vec3 dir){
    vec3 col = vec3(0.);
    float k=1.;
    
    vec3 pos; float depth=0., sdepth=0., dist;
    vec4 rc;
    const int maxsteps = 500;
    for (int i = 0; i < maxsteps; i++){
        pos = eye + dir * depth;
        rc = map(pos);
        dist = rc.w;

        depth += dist;
        
        if(dist < eps){ //intersection with object
            break; 
        }else if(length(pos)>depthmax){ //ray 
            depth = depthmax+eps;
            break;
        }
    } 
    vec3 n = norm(pos);
    pos+=eps*n;
    col+=map(pos).xyz*k*getFullLight(pos,n);
    return col * exp(-0.003*sdepth);
}
//full render
void main(void) {
    //direction calculation
    float angle = 1.32;    
    vec3 eye = cameraPos;
    eye.xz*=ro(angle); // rotating camera
    vec3 dir = getDir(angle);
    //raymarching
    vec3 col = rayCast(eye, dir);    
    glFragColor = vec4(1.5*log(1.+ col), 1.0);
}
