#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float r){
    return mat2(cos(r),sin(r),-sin(r),cos(r));
}

vec2 pmod(vec2 p, float n){
    float np = 3.1415*2./n;
    float r = atan(p.y,p.x)-0.5*np;
    r = mod(r,np)-0.5*np;
    return length(p)*vec2(cos(r),sin(r));
}

float cube(vec3 p,vec3 s){
    vec3 q = abs(p);
    vec3 m = max(s-q,0.);
    return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}

float crossBox(vec3 p,float s){
    float m1 = cube(p,vec3(s,s,99999.));
    
    float m2 = cube(p,vec3(99999.,s,s));
    
    float m3 = cube(p,vec3(s,99999.,s));
    
    return min(min(m1,m2),m3);
}

float dist(vec3 p){
    p.xy *= rot(time*0.2);
    p.z += time;
    
    p.xy = pmod(p.xy,6.);
    
    for(int i  =0;i<4;i++){
        p = abs(p)-1.;
        p.xz *= rot(0.3);
    }
    
    float k = 0.6;
    p = mod(p,k)-0.5*k;
    return min(crossBox(p,0.02),cube(p,vec3(0.1)));
}
    

void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    p = (p-0.5)*2.;
    p.x *= resolution.x/resolution.y;

    p *= rot(time*0.0);
    
    vec3 ro = vec3(cos(time/2.),0.7,0.7);
    vec3 rd = normalize(vec3(p,0.)-ro);

    float d,t=2.;
    
    float ac = 0.;
    
    for(int i = 0;i<50;i++){
        d = dist(ro+rd*t);
        t += d;
        ac += exp(-4.0*d);
        if(d<0.01) break;
    }
    
    float cl = exp(-1.0*t);
    
    vec3 col = vec3(0.7,0.7,0.2)*0.05*vec3(ac);
    col += vec3(0,0.3,0.3);
    col = pow(col,vec3(0.7));
    if(d<0.01) col +=vec3(0.4,0.8,0.9)*0.01/abs(mod((ro+rd*t).z,1.0)-0.5);
    glFragColor = vec4(col, 1.0 );

}
