#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float cube(vec3 p,vec3 s){
    vec3 q =abs(p);
    return length(max(q-s,0.0));
}
vec2 rot(vec2 p,float r){
    mat2 m = mat2(cos(r),sin(r),-sin(r),cos(r));
    return m*p;
}
float dist(vec3 p){
    float d =length(p+vec3(0.,-0.3*abs(sin(time*3.)),0.))-0.2;
    float d1 = 0.15+p.y;
    vec3 pm =p;
    float k =1.5;
    p.xz =mod(p.xz,k)-0.5*k;
    for(int i=0;i<3;i++){
        p = abs(p)-0.1;
        p.xz = rot(p.xz,1.);
    }
    float d2 =cube(p,0.7*vec3(0.1,0.1,0.1));
    return min(d2,min(d,d1));
}

vec3 gn(vec3 p){
    vec2 e =vec2(0.001,0.0);
    return normalize(vec3(
    dist(p+e.xyy)-dist(p-e.xyy),
    dist(p+e.yxy)-dist(p-e.yxy),
    dist(p+e.yyx)-dist(p-e.yyx)
    ));
}

float ao(vec3 p,vec3 n,float len,float power){
    float oss =0.0;
    for(int i =0;i<3;i++){
        float d = dist(p+n*len/3.0*float(i+1));
        oss += (len-d)*power;
        power *=0.5;
    }
    return clamp(1.-oss,0.0,1.0);
}

vec3 draw(vec3 p,float t){
    vec3 n = gn(p);
    vec3  col =5.*vec3(exp(-0.3*t));
    float ao = ao(p,n,0.25,1.);
    return col*vec3(ao);
}
void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy )*2.-1.;
    p.y *=resolution.y/resolution.x;
    float kt =time;
    float ra =7.0;
    vec3 ro =vec3(ra*cos(kt),3.,ra*sin(kt));
    vec3 ta = vec3(0.,0.,0.);
    vec3 cdir = normalize(ta-ro);
    vec3 up =vec3(0.,1.,0.);
    vec3 side =cross(cdir,up);
    up = cross(side,cdir);
    float fov =4.0+sin(time*0.5);
    vec3 rd =normalize(p.x*side+p.y*up+fov*cdir);
    float t =0.001;
    float d;
    for(int i=0;i<99;i++){
        d = dist(ro+rd*t);
        t +=d;
    }
    vec3 col =vec3(0.0);
    if(d<0.01){
        col =draw(ro+rd*t,t);
    }
    glFragColor = vec4(col, 1.0 );

}
