#version 420

// original https://www.shadertoy.com/view/fsV3WD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1415926535
#define STEPS 500.0
#define MDIST 200.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pmod(p,x) (mod(p,x)-0.5*(x))
float h21(vec2 a){
    return fract(sin(dot(a,vec2(453.2734,255.4363)))*994.3434);
}
vec3 rdg;
float box(vec3 p, vec3 b){
    vec3 d= abs(p)-b;
    return max(d.x,max(d.y,d.z));
}
vec3 glow = vec3(0);
vec2 map(vec3 p){
    vec3 po = p;
    vec2 a = vec2(1);
    vec2 b = vec2(2);
    float t =time;
    p.x+=t;
    
    float m = 2.; //Adjust the sphere size here :)
    
    vec2 id3 = floor(p.xz/m)+0.5;
    p.x+=id3.y;
    vec2 id2 = floor(p.xz/m)+0.5;
    float hash =h21(mod(id2,100.0));
    p.y+=(hash-0.5);
    id2*=rot(-pi/6.0);
    p.y+=sin(id2.x+t)*0.7;
    p.y+=sin(id2.x*0.6+t)*0.4;
    p.y+=sin(id2.x*0.3+t)*0.2;
    id2*=rot(pi/6.0)*0.3;
    p.y+=sin(id2.y+t)*0.7;
    po = p;
    float dc = 0.;
    {
        vec3 p2=p/vec3(m);
        vec3 id = floor(p2);
        vec3 dir = sign(rdg)*.5;
        vec3 q = fract(p2)-.5;
        vec3 rc = (dir-q)/rdg;
        rc*=m;
        dc = min(rc.x,min(rc.y,rc.z))+0.01;
    }
    p.xz = pmod(p.xz,m);
    t+=hash*200.;
    //t*=-1.;
    //////////////////////////////////
    //////////////////////////////////
    float spd = .025;
    t*=spd;
    float lscl = m;
    float le = -mod(t * lscl,lscl); 
    float tscl = 650.; 
    float te = tscl - mod(t * tscl,tscl); 
    float scl = 0.; 
    float id = 0.;
    float npy = 0.;
    bool mid = false;
        if(p.y > le && p.y < te){ 
            npy = mod(p.y-le,tscl);
            scl = mix(tscl,lscl,min(fract(t)*2.0,1.0));
            mid = true;
            id = floor(t);
        }
        if(p.y<le){ 
            npy = mod(p.y-le,lscl);
            id = floor((p.y-le)/lscl)+floor(t);
            scl = lscl;
        }
        if(p.y>te){ 
            npy = mod(p.y-te,tscl);           
            id = floor((p.y-te)/tscl)+floor(t)+1.0; 
            scl = tscl;
            //mid = true;
        }
        npy-=scl*0.5;
        p.y = npy;
    //////////////////////////////////
    //////////////////////////////////
    
    a.x = length(p)-m*0.98*0.5;
    b.x = length(p)-0.3;
    glow+=0.1/(0.1+b.x*b.x);
    
    a.x = max(-po.z-16.,a.x);
    a.x = min(a.x,dc);
    
    if(mid)a.x = min(a.x,max(-(-po.y+le),0.1));
    a.y = id;
    return a;
}
vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0.);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    
    vec3 ro = vec3(1,10,-25);
    vec3 lk = vec3(1.01,2,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = f*0.95+uv.x*r+uv.y*cross(f,r);
    rdg=rd;
    vec3 p = vec3(0);
    vec2 d = vec2(0);
    float dO = 0.;//,shad;
    bool hit = false;
    for(float i =0.; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO += d.x*1.3;
        if(abs(d.x)<0.005){
            hit =true;
            //shad = i/STEPS;
            break;
        }
        if(dO>MDIST){
            dO=MDIST;
            p = ro+rd*dO;
            break;
        }   
    }
    if(hit){
        //col =vec3(shad);
        vec3 n = norm(p);
        //col = n*0.5+0.5;
        float fres = 1.-abs(dot(rd,n))*.6;
        //col = length(col)*vec3(1);
        col = vec3(clamp(fres,0.,1.));
        vec3 p2 = p;
        p2.xz*=rot(0.1+cos(time*0.2)*0.3);
        float mat = mod(d.y,2.0);
        vec3 al;
        //if(mat == 0.) al = vec3(0.106,0.137,0.553);
        //if(mat == 1.) al = vec3(0.310,0.471,0.953);
        //col*=al;
        col*=mix(vec3(0.310,0.471,0.953),vec3(0.106,0.137,0.553),sin(p2.z+p2.x)*0.5+0.5);

    }
    col*=clamp(p.y*0.15+1.0,-1.,1.);
    col = pow(col,vec3(0.6));;
    vec3 bg = mix(vec3(0.000,0.12,0.400),vec3(0.439,0.784,1.000),max(rd.y+0.6,0.));
    //bg = vec3(0,0,0);
    col = mix(col,bg,clamp(length(p-ro*0.5)/50.,0.,1.));

    glFragColor = vec4(col,1.0);
}

