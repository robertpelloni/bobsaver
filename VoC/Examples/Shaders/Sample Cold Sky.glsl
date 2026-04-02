#version 420

// original https://www.shadertoy.com/view/3ds3RN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
vec3 getColor(float c){
   float r = cos((c-0.75)*PI);
   float g = cos((c-0.55)*PI);
   float b = cos((c-0.25)*PI);
   return vec3(r,g,b);
}

mat2 rot2D(float a){
   float c = cos(a);
   float s = cos(a);
   return mat2(c,s,-s,c); 
}

float hash1(vec2 p){
  vec2 v = vec2(PI*1453.0,exp(1.)*3054.0);
  return fract(sin(dot(p,v)*0.1)*4323.0);
}

vec2 hash2(vec2 p){
  vec2 v = vec2(hash1(p),hash1(p*p));   
  return v+v*rot2D(time*0.5); 
}

float noise1D(float x){
   float p = floor(x);
   float f = fract(x);
   
   float p1 = p+1.0;
   float h1 = hash1(vec2(p));
   float h2 = hash1(vec2(p1));
   
   f = f*f*f*(f*(f*6.-15.)+10.);
   float v = mix(h1,h2,f); 
    
   return v;
}

float noise2D(vec2 uv){
   vec2 p = floor(uv);
   vec2 f = fract(uv);
   vec2 e = vec2(1,0);
   vec2 p00 = p;
   vec2 p10 = p+e;
   vec2 p11 = p+e.xx;
   vec2 p01 = p+e.yx;
   float v00 = dot(f-e.yy,hash2(p00));
   float v10 = dot(f-e.xy,hash2(p10));
   float v11 = dot(f-e.xx,hash2(p11));
   float v01 = dot(f-e.yx,hash2(p01));
    
   f = f*f*f*(f*(f*6.-15.)+10.); 
   
   return mix(mix(v00,v10,f.x),mix(v01,v11,f.x),f.y);
}

float fbm1d(vec2 uv){
    float freq  = 1.0;
    float ampli = 3.0;
    float ret   = 0.0;

    for(int i=0;i<5;i++){
       ret += noise1D(uv.x*freq)*ampli;
       ampli*=0.6;
       freq*=2.0;
       uv+=sin(0.01*float(i));
    }
    return ret;
}

float fbm(vec2 uv){
    float freq  = 1.0;
    float ampli = 3.0;
    float ret   = 0.0;

    for(int i=0;i<5;i++){
       ret += noise2D(uv*freq)*ampli;
       ampli*=0.6;
       freq*=2.0;
       uv+=sin(0.01*float(i));
    }
    return ret;
}

void mountain(inout vec3 col,vec2 uv,vec2 cuv){
    cuv.y+=6.;
    cuv.x+=7.0;
    float n = fbm1d(cuv*0.12);
    vec2  f = vec2(cuv.x,n);
    float v = 0.1/length(cuv-f);
    v = pow(v,3.5);
    if(cuv.y<=n){
      col-= 20.;
    }else {
      col-=v*10.;
    }
    
}

void moon(inout vec3 col,vec2 uv,vec2 cuv){
   uv -= vec2(5.,3.);
   uv*=vec2(0.1);
   
   vec2 f  = vec2(uv.x,uv.y);
   float r = .1; 
   float v = r/(length(uv));
   float t =  0.0;
   
   for(int i=0;i<4;i++){
       t = time*0.5+float(i)*0.8;
       v+=fbm(cuv+vec2(t,t*0.1))*0.05;
   }
    
   col+= getColor(0.16)*v; 
}

void star(inout vec3 col,vec2 uv,vec2 cuv){
   float v =0.0;
   
    
   v+=abs(0.5)/length(uv-70.*vec2(hash2(uv*5.0)));
    
   col+= getColor(0.14)*v*1.4; 
}

void drawMeteor(inout vec3 col, in vec2 uv,vec2 startP,vec2 endP,float linWidth){
 
   uv*=3.0;
   vec2 lineDir=endP-startP;
   vec2 fragDir=uv-startP;
   
   // keep the line coefficient bewteen [0,1] so that the projective dir on the 
   // lineDir will not exceed or we couldn't get a line segment but a line.
   float lineCoe=clamp(dot(lineDir,fragDir)/dot(lineDir,lineDir),0.,1.0);
                       
   vec2 projDir=lineCoe*lineDir;
    
   vec2 fragToLineDir= fragDir- projDir;
    
   float dis=length(fragToLineDir);
   float disToTail = length(projDir);
   dis=linWidth/dis;
     
   col += dis*getColor(0.3)*pow(disToTail,3.0);
    
}
 
void drawMeteors(inout vec3 col,vec2 uv){
    
    vec2 dir = normalize(vec2(-1.0,-0.5));
    vec2 mv  = -dir*cos(mod(time*2.,PI))*60.0;
    vec2 sp  = vec2(10.0+100.0*hash1(vec2(floor(time*2./PI))),10.0);
    vec2 ep  = sp+dir*5.0;

    drawMeteor(col,uv,sp+mv,ep+mv,0.0005);

}
 

void rlight(inout vec3 col,vec2 uv){
   uv-=vec2(0.,-1.4); 
   vec2 f  = vec2(uv.x,cos(uv.x));
   float v = 0.5/length(uv-f);
   v*=fbm(uv);
   col+= clamp(getColor(.95)*v,0.,1.); 
}
 
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 cuv = uv - vec2(0.5);
    cuv.x *= resolution.x/resolution.y;
    // Time varying pixel color
    vec3 col = vec3(0);
    cuv *=10.;
    moon(col,cuv,uv);
    //rlight(col,uv);
    star(col,uv,cuv);
    drawMeteors(col,cuv);
    mountain(col,uv,cuv);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
