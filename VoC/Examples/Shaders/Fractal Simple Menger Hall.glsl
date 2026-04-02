#version 420

// original https://www.shadertoy.com/view/Wl3BRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float r){
  return mat2(cos(r),sin(r),-sin(r),cos(r));
}

float cube(vec3 p,vec3 s){
    vec3 q = abs(p);
    vec3 m = max(s-q,0.);
    return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}

float cube2(vec2 p,vec2 s){
    vec2 q = abs(p);
    vec2 m = max(s-q,0.);
    return length(max(q-s,0.))-min(m.x,m.y);
}

float cube3(vec3 p,vec2 s){
    return min(min(cube2(p.xy,s),cube2(p.yz,s)),cube2(p.zx,s));
}

vec2 pmod(vec2 p,float n){
  float np = 3.141592*2./n;
  float r = atan(p.x,p.y)-0.5*np;
  r = mod(r,np)-0.5*np;
  return length(p)*vec2(cos(r),sin(r));
}

float menger(vec3 p){
  
  //p.y += 0.3;
    float d0 = cube(p,vec3(10000.));
    
    float k =1.8;
        
    float s = 1.0/3.;
    for(int i = 0;i<6;i++){
     
        
        vec3 sp = mod(p-vec3(k/2.),k)-0.5*k;
        
        float d1 = cube3(sp,vec2(s));
        
        d0 = max(d0,-d1);
        
          k /= 3.;
        s /= 3.;
        
    }
    
    return d0;
}

float dist(vec3 p){
    p.y -= 0.21;
    p.z -= 0.2*time;
    p.xy  = pmod(p.xy,8.);
    p.x -= -0.1;
    float k = 0.4;
    //p = mod(p,k)-0.5*k;
    float d = menger(p);
    return d;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
     vec2 p = (uv-0.5)*2.0;
    
    p.y *= resolution.y/resolution.x;

    vec3 ro = vec3(0,0,0);
    
    vec3 rd = normalize(vec3(p,0.5)-ro);
    rd.yz *= rot(0.4);
    float d,t =0.;
    float ac = 0.;
    for(int i = 0;i<66;i++){
        d = dist(ro+rd*t);
        t += d;
        ac += 0.8*exp(-0.2*t);
        if(d<0.0000001)break;
    }

    vec3 col = vec3(0);
    
    col = vec3(0.7,0.4,0.3)*ac*0.1;
    
    col = pow(col,vec3(1.4));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
