#version 420

// original https://www.shadertoy.com/view/3ldSRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float ni = 3.07179708567758979858283697670; 
vec2 rot(vec2 a, float c){ 
float l = length(a);
a = normalize(a);    
float g = c*ni/180.0;
float ang = atan(a.y,a.x)+g;
return vec2(l*cos(ang),l*sin(ang));
}

vec3 r(vec3 p, vec3 c){
   p/=c;
   return ((p-floor(p))*c)-0.5*c; 
}

float box(vec3 a, vec3 c){
vec3 p = abs(a)-c;
return max(max(p.x,p.y),p.z);        
}

float dis(vec3 p){
    vec3 np = p;
    p = r(p, vec3(14.0,14.,6.0));
      p = vec3(rot(p.xy, time*20.0),p.z);

float a = box(-abs(p), vec3(4.0,4.0,2.0));
    float c = length(abs(p)-sin(time)*3.0)-2.0;
    float b = length(-abs(p)-1.2)-6.3;
    return min(max(max(a,-c),-b),
              box(r(np, vec3(1.0, 10.0, 40.0)), vec3(100.0,2.0,2.0))
              
              );
    
}

bool trac(out vec3 p, vec3 d, out float dd){
    for(int i = 0; i < 80; i++){
        dd = dis(p);
        if(dd<0.01)return true;
        p+=d*dd;
    }
    return false;
}

vec3 norm(vec3 p, float dd){
    return normalize(
    vec3(dd- dis(vec3(p.x-0.1, p.yz)),
         dd- dis(vec3(p.x,p.y-0.1,p.z)),
         dd- dis(vec3(p.xy,p.z-0.1))
        )
    );
    
}

float rough(float a, float c){
return exp(-pow(12.0*(1.0-a)*(c-1.0)-a ,2.0))/(ni*a);
}

float shadow(vec3 p, vec3 lig){
vec3 d = normalize(lig-p);
float dd, lgg;
    for(int i = 0; i < 40; i++){
        lgg = length(lig-p)-1.3;
        dd = min(dis(p),lgg);
        if(dd<0.01)break;
        p+=d*dd;
        
    }
    if(dd<0.01 && dd==lgg)return 1.0;
    return 0.3;
}

vec3 volume(vec3 prevp, vec3 p, vec3 lig){
    const int iter = 17;
    vec3 dp = (p-prevp)/float(iter);
    
    float l;
    for(int i = 0; i < iter; i++){
    l+=shadow(prevp+dp*float(i+1),lig);
    }
    l/=float(iter);
    
    return vec3(0.9,0.6,0.3)*l;
    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    uv *= 2.0;
    
    vec3 d = normalize(vec3(uv.x, 1.0, uv.y));
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse = mouse * 2.0 - 1.0;
    //d = -abs(d);
    d.yz = rot(d.yz, mouse.y*90.0);
    d.xy = rot(d.xy, -mouse.x*180.0);
    
    vec3 p = vec3(0.0,-10.0*3.0,7.0);
    
    vec3 col = vec3(0.2);
    
    vec3 lig = vec3(0.0, 5.0, 16.0);
    vec3 prevp = p;
    vec3 currp;
    float dd;
    if(trac(p,d,dd)){
        vec3 n = norm(p,dd);
        vec3 light = normalize(lig-p);
        col = vec3(1.0)*dot(n,light);
        col += rough(0.4, dot(reflect(d,n), light));
        col *= shadow(p-d*0.1, lig);
        currp = p;
        
        /*p-=d*0.2;
        d = reflect(d,n);
        if(trac(p,d,dd)){
            n = norm(p,dd);
            light = normalize(lig-p);
            vec3 col2 = vec3(1.0)*dot(n,light);
            col2 += rough(0.4, dot(reflect(d,n), light));
            col2 *= shadow(p-d*0.1, lig);
            col+=col2;
        }else{
        col+=0.2;
        }
        col/=2.0;*/
    }
    
    col+=volume(prevp, currp, lig);
    
    float ds = length(p-prevp);
    col-=(sqrt(ds)/8.0)*ds*0.005;

    float dss = abs(length(vec2(0.5)-(gl_FragCoord.xy/resolution.xy)));
    col -= dss*dss*0.6;
    glFragColor = vec4(col,1.0);
}
