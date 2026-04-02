#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;
float pi = acos(-1.);

vec2 rot(vec2 p ,float r){
    mat2 m = mat2(cos(r),sin(r),-sin(r),cos(r));
    return m*p;
}

float nPrism(vec3  p,vec2 h,float n){
    float np = pi*2./n;
    float r =atan(p.x,p.y);
    r =mod(r,np)-0.5*np;
    vec2 kp = length(p.xy)*vec2(cos(r),sin(r));
    vec3 kv = vec3(abs(kp.x)-h.x,abs(kp.y)-h.x*tan(np*0.5),abs(p.z)-h.y);
    float d = length(vec2(max(kv.x,0.0),max(kv.y,0.0)));
    d = length(vec2(d,max(kv.z,0.0)))-min(min(max(-kv.x,0.0),max(-kv.y,0.0)),max(-kv.z,0.0));
    return d;
}

float line(vec3 p,float s,float dt){
    p.xy =abs(p.xy)-1.;
    vec3 q =abs(p);
    return length(p.xy)-s-0.1;//length(max(q.xy-vec2(s),0.0))-min(max(s-q.x,0.0),max(s-q.y,0.0))-0.01;
}

float hexap (vec3 p){
    //p.y =-p.y;
    p.yz = rot(p.yz,pi*0.5);
    p.z += 12.5;
    vec3 pm =p;
    vec2 k =vec2(1.,1.5);
    p.xy = mod(p.xy,k)-0.5*k;
    float d = nPrism(p,vec2(0.4,10.),6.0);
    pm.xy +=vec2(0.5,0.8);
    pm.xy = mod(pm.xy,k)-0.5*k;
    float d1 = nPrism(pm,vec2(0.4,10.),6.0);
    return min(d,d1);
}

float dist(vec3 p,float dt){
    p.z += -30.*(time+dt);
    vec3 pm =p;
    p.xy =rot(p.xy,p.z*0.2);
    pm.xy =rot(pm.xy,-p.z*0.15);
    float dl =line(pm,0.02,dt);
    p.y =-abs(p.y);
    float d = hexap(p);
    return min(d,dl);
}

vec3 gn (vec3 p,float dt){
    vec2 e = vec2(0.1,0.0);
    return normalize(vec3(
    dist(p+e.xyy,dt)-dist(p-e.xyy,dt),
    dist(p+e.yxy,dt)-dist(p-e.yxy,dt),
    dist(p+e.yyx,dt)-dist(p-e.yyx,dt)
    ));
}
vec3 L(vec3 p,vec3 rd,float dt){
    vec3 n = gn(p,dt);
    float kt =time*5.;
    vec3 ld = normalize(vec3(cos(kt),sin(kt),5.));
    float ndl = max(dot(n,ld),0.0);
    vec3 R = normalize(-ld+2.*n*ndl);
    float spec = pow(sign(ndl)*max(dot(R,-rd),0.0),10.0);
    vec3 mat = vec3(0.,0.3,0.7);
    vec3 pm =p;
    pm.z += -30.*(time+dt);
    pm.xy =rot(pm.xy,-p.z*0.15);
    float dl =line(pm,0.02,dt);
    vec3 em =vec3(0.);
    if(dl<0.96){
    mat =4.*vec3(0.5,0.8,0.6);
        em =0.1*mat;
    }
    
    vec3 col = vec3(spec)+ndl*mat+em;
    return col;
}
vec3 draw (vec3 ro, vec3 rd,float dt){
    float d;
    float t =0.001;
    float hit =0.01;
    for(int i=0;i <40;i++){
        d =dist(ro+rd*t,dt);
        t+=d;
        if(d<hit||t>1000.)break;
    }
    vec3 bgcol =vec3(0.3,0.5,0.8);
    vec3 col = vec3(0.);
    if(d<hit){
        col =L(ro+rd*t,rd,dt);
    }
    float near =3.0;
    float far =40.0;
    col = mix(bgcol,col,clamp((far-t)/(far-near),0.0,1.0));
    
    return col;
}

void main( void ) {

    vec2 p = 2.*( gl_FragCoord.xy / resolution.xy )-1.;
    p.y *=resolution.y/resolution.x;
     vec2 uv =  ( gl_FragCoord.xy / resolution.xy );
    vec3 bcol = texture2D(backbuffer,uv).xyz;
    vec3 ro =vec3(0.,0.,3.);
    vec3 ta =vec3(0.,0.,0);
    vec3 cdir =normalize(ta-ro);
    vec3 up = vec3(0.,1.,0.);
    vec3 side = cross(cdir,up);
    up = cross(side,cdir);
    float fov = 1.5;
    vec3 rd = normalize(p.x*side+p.y*up+fov*cdir);
    float dt =0.0;
    vec3 col =vec3(0.);
    for(int i =0 ;i<5;i++){
        float fi =float(i);
        col += (0.2-0.01*fi)*draw(ro,rd,dt+0.014*fi);
    }
    col = 0.32*col+0.8*bcol;
    glFragColor = vec4(col, 1.0 );

}
