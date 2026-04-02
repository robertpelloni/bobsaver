#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
float pi = acos(-1.);

vec2 rot(vec2 p,float r){
    mat2 m = mat2(cos(r),sin(r),-sin(r),cos(r));
    return m*p;
}

vec2 pmod(vec2 p,float n){
    float np = pi*2./n;
    float r = atan(p.x,p.y)+0.5*np;    
    r = mod(r,np)-0.5*np;
    return length(p.xy)*vec2(sin(r),cos(r));
}

float nPrism (vec3 p,vec2 h,float n,float s){
    float np = pi*2./n;
    float r = atan(p.x,p.y);
    r = mod(r,np)-0.5*np;
    vec2 kp = length(p.xy)*vec2(cos(r),sin(r));
    vec3 kv = vec3(kp.x-h.x,abs(kp.y)-s*h.x*tan(np*0.5),abs(p.z)-h.y);
    float d = length(vec2(max(kv.x,0.0),max(kv.y,0.0)));
    return length(vec2(d,max(kv.z,0.0)))-min(min(max(-kv.x,0.0),max(-kv.y,0.0)),max(-kv.z,0.0));
}
float rand(vec2 co){
    return fract(sin(dot(vec2(12.345,67.89012),co))*45678.912);
}
float hx(vec3 p,float s){
    float d = nPrism(p,vec2(0.3*s,0.02),6.0,1.0);
    float d1 = nPrism(p,vec2((0.28-0.06*(1.-s))*s,0.021),6.0,1.0);
    return max(d,-d1);
}

float krs(vec3 p){
    float s=1.0;
    float d = hx(p,s);
    for(int i =0;i<6;i++){
        s *=0.5;
        float pk = p.y;
        p.xy = pmod(p.xy,6.0);
        p.y =p.y-1.*s;
        float d1 =9999.;
        if(pk>0.||i<1){
        d1 = hx(p,s);
        }
        d = min(d,d1);
    }
    return d;
}

float dist(vec3 p){
    vec3 pm = p;
    p.xz = rot(p.xz,time);
    float d = krs(p);
    float k =1.2;
    vec2 id = floor(pm.xz*k)/k;
    pm.xyz = mod(pm.xyz,k)-0.5*k;
    
    pm.xz = rot(pm.xz,rand(id)*4.+time*0.2);
    
    float sk = 10.2;
    float d1 = krs(pm*sk)/sk;
    return min(d,d1);
}
vec3 gn(vec3 p){
    vec2 e = vec2(0.001,0.0);
    return normalize(vec3(
    dist(p+e.xyy)-dist(p-e.xyy),
    dist(p+e.yxy)-dist(p-e.yxy),
    dist(p+e.yyx)-dist(p-e.yyx)
    ));
}
vec3 draw(vec3 p,vec3 rd){
    vec3 n = gn(p);
    vec3 ld = normalize(vec3(0.1,0.1,1.2));
    
    float ndl = max(dot(n,ld),0.0);
    vec3 R = normalize(-ld+2.*n*ndl);
    float spec = pow(max(dot(R,-rd),0.0)*sign(ndl),10.);
    vec3 col = vec3(0.4,1.,1.)*ndl*0.4+vec3(spec);
    return col;
}
void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy )*2.-1.;
    p.y *= resolution.y/resolution.x;
    vec3 ro = vec3(0.,0.,5.);
    vec3 ta = vec3(0.,0.,0.);
    vec3 cdir = normalize(ta-ro);
    vec3 up = vec3(0.,1.,0.);
    vec3 side = cross(cdir,up);
    up = cross(side,cdir);
    float fov = 2.5;
    vec3 rd = normalize(fov*cdir+p.x*side+p.y*up);
    float t =0.0001;
    float d =0.0;
    float hit =0.001;
    for(int i =0;i<90;i++){
        d = dist(ro+rd*t);
        t +=d;
    }
    vec3 col = vec3(0.);
    if(hit>d){
        col = draw(ro+rd*t,rd);
    }
    glFragColor = vec4( col, 1.0 );

}
