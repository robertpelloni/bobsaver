#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wtfBWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cameraPos = vec3(0., 10., -13.5);
float softShadow = 10.;
float depthmax = 80.; 
const float eps = 0.0001;
vec3 backcol = vec3(.6,.7,1.);
float inf = 1e20;

mat2 ro (float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}
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
float box(vec3 b, vec3 p){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
bool closer(vec3 p, vec3 a, vec3 b){
    return length(p-a)<length(p-b);
}
vec4 koch(vec3 p){    
    float d = box(vec3(3.),p);
    float x,y,z,s=1.;
    const vec3 Y=vec3(0.,4.,0.),X=vec3(4.,0.,0.),Z=vec3(0.,0.,4.),XY=vec3(2.,2.,0.),XZ=vec3(2.,0.,2.),YZ=vec3(0.,2.,2.),XYZ=vec3(2.,2.,2.);

    float I=4.+2.1*sin(time),i_=0.;
    vec3 p_;
    for(float i=1.;i<=I;i++){
        p = abs(p);x=p.x,y=p.y,z=p.z;
        
        if(closer(p,XYZ,X)&&closer(p,XYZ,Y)&&closer(p,XYZ,Z)&&closer(p,XYZ,XY)&&closer(p,XYZ,XZ)&&closer(p,XYZ,YZ)){
            p_=XYZ;
        }else if(y>max(x,z)+2.){
            p_=Y;i_++;
        }else if(x>max(y,z)+2.){
            p_=X;i_++;
        }else if(z>max(x,y)+2.){
            p_=Z;i_++;
        }else{
            float m = min(x,min(y,z));
            if(m==x){
                p_=YZ;
            }else if(m==y){
                p_=XZ;
            }else{
                p_=XY;
            }
        }        
        p = 3.*(p-p_);
        s*=3.3;
        d = min(box(vec3(3.),p)/s,d);
    }    
    return vec4(mix(vec3(2.,2.,3.0),vec3(1.7),i_/I),d);
}

//color functions
bool cb3(vec3 p){
    ivec3 d = ivec3(floor(p));
    return (d.x+d.y+d.z)%2==0;
}
//scene SDF
vec4 map(vec3 p){
    vec4 d0 = vec4(1.,1.,1.,-box(vec3(20.,20.,20.),p-vec3(0.,20.,0.)));
    d0.xyz*=cb3(p)?1.:.8;
    
    vec4 d = koch(p-vec3(0.,6.,0.));
    d0 = cun(d0,d);
        
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
        c += h;//clamp(h,0.,3.0);
        if(c>l)break;
    }
    
    return lc*po*r*diff/(l*l);
}
// ambient occlusion by point
float getOcc(vec3 ro, vec3 rd){
    float totao = 0.0;
    float sca = 1.0;

    for (int aoi = 0; aoi < 2; aoi++){
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
vec3 getFullLight(vec3 pos, vec3 n){   
    pos+=eps*n;
    vec3 col;

    if (length(pos) < depthmax){
        col = vec3(.25);
        col += getLight(pos, vec3(11., 13., 8.), n, vec3(1.,.9,.9), 60.,false);
        col += getLight(pos, vec3(-8.,13., 11.), n, vec3(1.,1.,1.), 60.,false);
        col += getLight(pos, vec3(-11.,13.,-8.), n, vec3(1.,1.,1.), 60.,false);
        col += getLight(pos, vec3(8., 13.,-11.), n, vec3(1.,.9,.9), 60.,false);
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
    dir.zy*=ro(-.25);
    dir.xz*=ro(angle);
    return dir;
}

//color and length of ray
vec3 rayCast(vec3 eye, vec3 dir){
    vec3 col = vec3(0.);
    float k=1.;
    
    vec3 pos; float depth=0., sdepth=0., dist, distM;
    vec4 rc;
    const int maxsteps = 500;
    for (int i = 0; i < maxsteps; i++){
        pos = eye + dir * depth;
        rc = map(pos);
        dist = rc.w;

        depth += dist;
        sdepth += dist;
        
        if(dist < eps){ //intersection with object
            break; 
        }else if(length(pos)>depthmax){ //ray 
            depth = depthmax+eps;
            break;
        }
    } 
    vec3 n = norm(pos);
    pos+=eps*n*5.;
    col+=map(pos).xyz*k*getFullLight(pos,n);
    if(map(pos).w<0.)col+=vec3(1e20);
    return col * exp(-0.003*sdepth);
}
//full render
void main(void) {
    //direction calculation
    float angle = 6.9;    
    vec3 eye = cameraPos;
    eye.xz*=ro(angle);
    vec3 dir = getDir(angle);

    //raymarching
    vec3 col = rayCast(eye, dir);
    
    glFragColor = vec4(1.5*log(1.+ col), 1.0);
}

