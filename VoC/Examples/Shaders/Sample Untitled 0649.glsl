#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/fl2XDd

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 128.0
#define MDIST 250.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pmod(p,x) (mod(p,x)-0.5*(x))
#define lr 90.0
vec3 gl = vec3(0);
vec3 gl2 = vec3(0);
vec2 path(float t){
  return vec2(sin(t),cos(t));
}

vec2 map(vec3 p){
  vec2 a = vec2(9999);
  vec2 b = vec2(9999);
  float t = mod(time,1000.0);
  vec3 po = p;
  
  float ffti = time;
  float fft = 0.0;//texelFetch( iChannel0, ivec2(10,0), 0 ).x*0.008;
  float fft2 = 0.0;//texelFetch( iChannel0, ivec2(200,0), 0 ).x*0.003;
  
  p.yz*=rot(-ffti*0.35);
  float th = atan(p.y,p.z);
  th*=80.0;
  float r = length(p.yz)-lr;
  p.y = r;
  p.z = th;
  
  
  //INNER SPIRAL
  p.xy-=path(p.z*0.2)*4.0;
  vec3 p2 = p;
  p.xy*=rot(-p.z);
  p.x = abs(p.x)-1.0;
  b.x = length(p.xy)-0.5;
  
  b.y = 1.0;
  a=(a.x<b.x)?a:b;
  p = p2;
  
  
  //MIDDLE SPIRAL
  p.xy-=path(p.z*0.2)*min(3.0+fft*250.0,6.0);
  vec3 p3 = p;
  p.xy*=rot(sin(p.z));
  p.xy = abs(p.xy)-1.4;
  vec2 d2 = abs(p.xy)-1.0;
  float cut = max(d2.x,d2.y);
  p = p3;
  b.x = length(p.xy)-1.0;
  b.x = max(-cut,b.x);
  
  b.y = 2.0;
  a=(a.x<b.x)?a:b;
  
  
  //OUTER SPIRAL
  p.xy-=path(p.z*0.2)*min(3.0+fft*250.0,6.0);
  b.x = length(p.xy)-1.0;
  gl2 +=0.1/(0.01+b.x*b.x)*vec3(0,0.1,1.0);
  
  b.y = 3.0;
  a=(a.x<b.x)?a:b;
  
  
  //OUTER BOXS TUBES
  p = po; p.y = r;p.z = th;
  p.xy*=rot(sin(p.z*0.0035)+sin(t));
  p.xy = abs(p.xy)-20.0;
  
  for(float i = 0.0; i<4.0; i++){
    p.xy = abs(p.xy)-1.5;
    p.xy*=rot(p.z*0.1-t*2.0);
  }
  vec2 d = abs(p.xy)-1.0;
  b.x = max(d.x,d.y);
 
  b.y = 4.0;
  a=(a.x<b.x)?a:b;
  
  
  //LASERS
  p = po; p.y = r;p.z = th;
  p.xy = abs(p.xy)-20.0;
  p.xy*=rot(pi/4.0);
  p.xy = abs(p.xy)-5.0;;
  b.x = length(p.xy);
  gl+=0.1/(0.01+b.x*b.x)*vec3(0.0,1.0,0.5)*max(sin(p.z*0.05+t*10.0)*0.5+0.4,0.0);
  
  b.y = 0.0;
  a=(a.x<b.x)?a:b;
  
  
  //MIDDLE BALL THINGS
  p = po;p.y = r;p.z = th;
  p.xy*=rot(-t*5.0);
  p.z = pmod(p.z,20.0);
  p.yz*=rot(t*4.0);
  p.yx*=rot(t*4.0);
  p.xy = abs(p.xy)-1.5-fft2*300.0;
  b.x = length(p)-0.5-fft*60.0;
  gl+=(0.0004/(0.01+b.x*b.x))*vec3(0,1,1);
  
  b.y = 7.0;
  a=(a.x<b.x)?a:b;
  
  
  //BOX THINGYS
  p = po;
  p.y = r;
  p.z-=5.0;
  p.xy*=rot(-t*0.75);
  p.xy*=rot(ffti);
  p.xy = abs(p.xy)-6.0-fft2*1200.0;
  //p.xy*=rot(pi/4.0);
  
  //p.xy = abs(p.xy);
  p.xy*=rot(pi/4.0);
  vec3 d3 = abs(p)-vec3(4.0,0.75,0.75);
  b.x = max(d3.x,max(d3.y,d3.z));
  
  b.y = 9.0;
  a=(a.x<b.x)?a:b;
  return a;
}
//Anti-unroll normals (not live coded) 
#define ZERO (min(frames,0))
vec3 norm(vec3 p){
    
#if 0    
    vec2 e= vec2(0.01,0);

    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
#else    
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*0.001).x;
    }
    return normalize(n);
#endif  
}
void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
  float t = mod(time,1000.0);
  uv*=rot(t*0.75);
  vec3 col = vec3(0);
  
  vec3 ro = vec3(0,lr,0);
  vec3 rd = normalize(vec3(uv,0.6));
  
  float shad, dO;
  vec2 d;
  vec3 p = ro;
  bool hit = false;
  float bnc = 0.0;
  for(float i = 0.0; i<STEPS; i++){
    p = ro+rd*dO;
    d = map(p);
    if(d.x>1.0)d.x = sqrt(d.x);
    
    
    if(d.x<0.01){
      if(d.y==7.0&&bnc==0.0){
        vec3 n = norm(p);
        ro = p+n*0.5;
        rd = n;
        dO = 0.0;
        bnc = 1.0;
      }
      else{
        if(d.y == 3.0){
          d.x = 0.1;
        }
        else{
          shad = i/STEPS;
          hit = true;
          break;
        }
    }
    }
    if(dO>MDIST){
      p = ro+rd*MDIST;
      break;
    }
    dO+=d.x*0.6;
  }
  vec3 al;
  if(hit){
    
    vec3 n = norm(p);
    vec3 ld = normalize(vec3(0.25,0.25,-1.0));
    vec3 h = normalize(ld-rd);
    float spec = pow(max(dot(n,h),0.0),20.0);
    
    shad = 1.0-shad;
    shad = pow(shad,1.2);
    col = vec3(shad);
    if(d.y ==4.0) d.y = floor(mod(p.z*0.3,3.0))+1.0;
    
    if(d.y==1.0) al = mix(vec3(0.0,0.2,1.0),vec3(0,1.0,0.2),0.0);
    if(d.y==2.0) al = vec3(0,0.5,0.5)*1.5;
    if(d.y==3.0) al = mix(vec3(0.0,0.2,1.0),vec3(0,1.0,0.4),1.0);
    if(d.y==7.0) al = vec3(0,1.0,1.0);
    if(d.y==9.0) al = vec3(0.5,0.9,0);
    col*=al;
    col+=spec*0.3;
  }
  col = mix(col,vec3(0.05,0,0.15),dO/MDIST);
  col+=gl*0.6;
  col+=gl2*0.05;
  col = pow(col,vec3(0.75));
    glFragColor = vec4(col,0);
}
