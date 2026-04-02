#version 420

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float wire (vec3 p,float k,float s){
    vec3 modp = abs(mod(p,k)-0.5*k);
    vec3 q = abs(p);
    float kx = length(max(vec2(modp.y,modp.x)-s,0.0))-min(max(s-modp.y,0.0),max(s-modp.x,0.0));
    float ky = length(max(vec2(modp.x,modp.z)-s,0.0))-min(max(s-modp.x,0.0),max(s-modp.z,0.0));
    float kz = length(max(vec2(modp.y,modp.z)-s,0.0))-min(max(s-modp.y,0.0),max(s-modp.z,0.0));
    return min(min(kx,kz),ky);
}
float cube (vec3 p,vec3 s){
    vec3 q = abs(p);
    vec3 kv = max(s-q,0.0);
    return length(max(q-s,0.0))-min(kv.y,min(kv.z,kv.x));
}

vec4 em (vec3 p){
    float d = length(p)-0.;
    vec3 col = exp(-14.*d)*vec3(1.0);
    return vec4(col,d);
}

float zitu(vec3 p){
    float d =wire(p+vec3(0.,0.,0.4*time),0.5,0.02);
    return d;
}

float dist(vec3 p){
    float d =zitu(p);
    return d;
}
vec3 gn (vec3 p){
    vec2 e =vec2(0.0001,0.0);
    return normalize(vec3(
    dist(p+e.xyy)-dist(p-e.xyy),
    dist(p+e.yxy)-dist(p-e.yxy),
    dist(p+e.yyx)-dist(p-e.yyx)
        ));
}
float shadow(vec3 p,vec3 lpos,float hn){
    float d;
    vec3 ld = normalize(lpos-p);
    float t =0.001;
    float res =1.0;
    for(int i =0;i<16;i++){
        d =zitu(p+ld*t);
        res = min(res,hn*d/t);
        if(length(p-lpos)<t){
            //res =1.;
            break;
        }
        t += clamp(d,0.0,1.0);
    }
    return res;
}
vec3 lighting(vec3 p,vec3 rd,float t,vec3 acem){
    vec3 n = gn(p);
    vec3 lpos =vec3(0.);
    vec3 ld = normalize(lpos-p);
    float ndl = max(dot(n,ld),0.0);
    vec3 R = normalize(-ld+2.*ndl*n);
    float spec = pow(max(dot(R,-rd),0.0)*sign(ndl),10.0);
    
    
    
    float sha = shadow(p+n*0.01,lpos,16.);
    vec3 col = vec3(ndl*0.4+spec)*sha;
    float far =6.;
    float near = 0.8;
    col = mix(vec3(0.0),col,clamp((far-t)/(far-near),0.0,1.0));
    col +=acem;
    return col;
}
void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy )-0.5;
    p.y *= resolution.y/resolution.x;
    float kt =time;
    float ra =1.0;
    vec3 ro = vec3(cos(kt)*ra,0.5*sin(time*0.5),ra*sin(kt));
    vec3 ta = vec3(0.,0.,0.);
    vec3 cdir =normalize(ta-ro);
    vec3 up = vec3(0.,1.,0.);
    vec3 side = cross(cdir,up);
    up = cross(side,cdir);
    float fov = 0.5;
    vec3 rd = normalize(side*p.x+up*p.y+fov*cdir);
    float t =0.0001;
    float d =0.;
    float hit =0.001;
    vec3 acem = vec3(0.0);
    float ac =0.0;
    for(int i =0;i<99;i++){
        d =dist(ro+rd*t);
        vec4 emc = em(ro+rd*t);
        t +=min(d,emc.w);
        acem +=emc.xyz;
        if(hit>d||t>12.)break;
    }
    vec3 col =vec3(0.);
    
        col = lighting(ro+rd*t,rd,t,acem);
        
    
    glFragColor = vec4( col,1.0 );

}
