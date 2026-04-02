#version 420

// original https://www.shadertoy.com/view/tllSD8

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float bpm =125.;
float pi =acos(-1.);
const int nu =6;

float cube(vec3 p,vec3 s){
    vec3 q = abs(p);
    vec3 kv = max(s-q,0.0);
    return length(max(q-s,0.0))-min(min(kv.x,kv.y),kv.z);
}

vec2 pmod(vec2 p,float n){
    float np =2.0*pi/n;
    float r = atan(p.x,p.y)+0.5*np;
    r = mod(r,np)-0.5*np;
    return length(p.xy)*vec2(sin(r),cos(r));
}

float cro(vec3 p,float s){
    vec3 q =abs(p);
    
    vec3 km = max(vec3(s)-q,0.0);
    return min( -min(km.y,km.x),min(-min(km.z,km.y),-min(km.z,km.x)));
}

float nPrism(vec3 p,vec2 h,float n,float s){
    float np =pi*2.0/n;
    float r = atan(p.x,p.y);
    r = mod(r,np)-0.5*np;
    vec2 kp = length(p.xy)*vec2(cos(r),sin(r));
    vec3 kv = vec3(abs(kp.x)-h.x,abs(kp.y)-s*h.x*tan(np*0.5),abs(p.z)-h.y);
    float d = length(vec2(max(kv.x,0.0),max(kv.y,0.0)));
    return length(vec2(d,max(kv.z,0.0)))-min(min(max(-kv.x,0.0),max(-kv.y,0.0)),max(-kv.z,0.0));
}

vec2 rot (vec2 p,float r){
    mat2 m = mat2(cos(r),sin(r),-sin(r),cos(r));
    return m*p;
}
vec3 hsv(vec3 c){
    return ((clamp(abs(fract(c.x+vec3(0.,1.,2.)/3.)*6.-3.)-1.,0.0,1.0)-1.)*c.y+1.)*c.z;
}
float menger (vec3 p){
    vec3 pm =p;
    p.xz = rot(p.xz,time);
    p.zy =rot(p.yz,time);
    float bt0 =pow(abs(sin(time*(bpm*pi/60.))),10.0);
    float s =1.+bt0*0.3;
    float d = cube(p,vec3(s));
    float k =s*2.0;
    float d1 ;
    float d2 =99999.;
  
    float bt =  1./6.*(clamp(abs(sin(0.05*time*(120.*pi/60.))),0.2,0.8)-0.2);
    for(int i =0;i <4;i++){
    s/=3.0;
    vec3 sn =sign(p);
    //p.xy = rot(p.xy,bt)*sn.xy;
    //p.xz = rot(p.xz,bt)*sn.xz;
    d1 = cro(p,s);
    k/=3.0+6.*bt+0.3*bt0;
    p =mod(p+0.5*k+sn*bt,k)-0.5*k;
    d1 = min(d1,d2);
    d2 =d1;
    }
    pm.y =-abs(pm.y);
    pm.yz = rot(pm.yz,0.5*pi);
    pm.z +=13.5; 
    vec2 kn =1.1*vec2(1.1,1.7);
    vec3 pm2 =pm;
    vec2 id1  = floor(pm.xy/kn)*kn-kn*0.5;
    pm.xy=mod(pm.xy,kn)-kn*0.5;
    float knt =0.1;
    float bt2 =  0.2*pow(abs(sin(-0.25*length(id1)+knt+time*(bpm*pi/60.))),10.0);
    float d3 = nPrism(pm,vec2(0.5,10.5-bt2),6.0,1.0-3.5*bt2);
    pm2.xy +=kn*0.5;
    vec2 id2  = floor(pm2.xy/kn)*kn-kn*0.5;
    pm2.xy=mod(pm2.xy,kn)-kn*0.5;
    float bt3 =  0.2*pow(abs(sin(-0.25*length(id2)+knt+time*(bpm*pi/60.))),10.0);
    d3 = min(d3,nPrism(pm2,vec2(0.5,10.5-bt3),6.0,1.0-3.5*bt3));
    return min(d3,max(d,-d1));
}
vec4 spheres(vec3 p,float s){
    float kt =time*2.;
    float ra =3.0;
    float ds;
    float ds2 =999.;
     const int kn =nu;
    float fkn = float(kn);
      vec3 col =vec3(0.0);;
    for(int i=0;i<kn;i++){
    float fi =float(i);
    vec3 ap = vec3(ra*cos(kt+pi*fi*2./fkn),0.,ra*sin(kt+pi*fi*2./fkn));
    ds = length(p-ap);
        col +=exp(-6.*ds)*hsv(vec3(0.0+fi*1./3.0,0.8,1.0));
       ds = length(p-ap)-s;
    ds =min(ds,ds2);
    ds2 =ds;
    }
    p.xz = pmod(p.xz,20.);
    float pky =2.2;
    p.y = mod(p.y,pky)-0.5*pky;
    float pkz =12.;
    float mpz = p.z; 
    p.z = mod(p.z-time*pkz*bpm/60.,pkz)-0.5*pkz;
        
    float dcs =length(vec2(length(p.xy),max(abs(p.z)-0.1,0.0)));
    vec3 lecol = exp(-26.*dcs)*vec3(1.);
    float far =30.;
    float near =3.;
    
    lecol = mix(vec3(0.),lecol,clamp((far-mpz)/(far-near),0.0,1.0));
    col +=lecol;
    ds = min(ds,dcs);
    return vec4(col,ds);
}
float dist (vec3 p){
    
    float d =menger(p);
    
    return d;
}

vec3 gn(vec3 p){
    vec2 e = vec2(0.0001,0.0);
    return normalize(vec3(
    dist(p+e.xyy)-dist(p-e.xyy),
    dist(p+e.yxy)-dist(p-e.yxy),
    dist(p+e.yyx)-dist(p-e.yyx)
    ));
}

float shadow(vec3 p,vec3 rd,float hn){
    float d;
    float t =0.0001;
    float res =1.0;
    for(int i =0;i<16;i++){
        d = menger(p+rd*t);
        res = min(res,hn*d/t);
        t += clamp(d,0.2,1.0);
    }
    return res;
        
}

vec3 lighting(vec3 p,vec3 rd){
    vec3 n = gn(p);
    vec3 col =vec3(0.0);
    vec3 ld;
    float kt =time*2.;
    float ra =3.0;
    float md = menger(p);
    
    const int kn =nu;
    float fkn = float(kn);
        
    if(md<0.01){
        
        for(int i=0;i<kn;i++){
            float fi =float(i);
            ld = normalize(vec3(ra*cos(kt+pi*fi*2./fkn),0.,ra*sin(kt+pi*fi*2./fkn))-p);
            float ndl = max(dot(n,ld),0.0);
            vec3 R = normalize(-ld+2.*n*ndl);
            float spec = pow(max(dot(R,-rd),0.0)*sign(ndl),15.);
            vec3 adcol = vec3(ndl*0.4+spec)*hsv(vec3(0.0+fi*1./3.0,1.0,1.0));
            float sha = shadow(p+n*0.001,ld,16.);
            col +=adcol*sha;
        }
    }
    return col;
}

vec3 draw(vec3 ro,vec3 rd){
    float t =0.001;
    float d =0.;
    float hit =0.001;
    vec3 ac =vec3(0.0);
    for(int i =1;i<99;i++){
        d =dist(ro+rd*t);
        vec4 s4 = spheres(ro +rd*t,0.);
        t+=min(d,s4.w);
        ac += s4.xyz;
        if(d<hit||t>1000.)break;
    }
    vec3 bgcol =vec3(0.,0.,0.);
    vec3 col = vec3(0.);
    float far =30.;
    float near =3.;
    col = lighting(ro+rd*t,rd);
    
    
    
    vec3 pm = ro+rd*t;
    vec3 normal = gn(ro+rd*t);
    vec3 rerd = normalize(-rd+normal*max(dot(normal,-rd),0.0)*2.);
    float ret =0.001;
    float red =0.;
    vec3 reac =vec3(0.);
    for(int i =1;i<29;i++){
        d =dist(pm+rerd*ret);
            vec4 s4 = spheres(pm +rerd*ret,0.);
        ret+=min(d,s4.w);
        reac += s4.xyz;
        if(d<hit||t>1000.)break;
    }
    vec3 recol =vec3(0.);
    recol = lighting(pm+rerd*ret,rerd);
    recol +=0.4*reac;
    col =0.6*col+recol ;
    col = mix(bgcol,col,clamp((far-t)/(far-near),0.0,1.0));
    return col+0.4*ac;
}

void main(void)
{
    vec2 p = ( gl_FragCoord.xy / resolution.xy ) -0.5;
    p.y *= resolution.y/resolution.x;
    float kt =-time*0.8;
    float ra =10.0+2.0*sin(time);
    vec3 ro = vec3(ra*cos(kt),0.,ra*sin(kt));
    vec3 ta =vec3(0.,0.,0.);
    vec3 cdir = normalize(ta-ro);
    vec3 up = vec3(0.,1.,0.);
    vec3 side = cross(cdir,up);
    up = cross(side,cdir);
    float fov =0.9;
    vec3 rd =normalize(up*p.y+side*p.x+cdir*fov);
    vec3 col;
    col = draw(ro,rd);
    glFragColor = vec4(col, 1.0 );

}
