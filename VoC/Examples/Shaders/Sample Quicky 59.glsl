#version 420

// original https://www.shadertoy.com/view/sdKGWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
vec3 ln ;
vec2 sdf(vec3 p){

    vec2 h;
  vec3 ph=p;
    ph.x += asin(.2*sin(p.y*10.))*.2;
  h.x=length(ph.xz)-1.;
    h.y=1.;
  
  
  vec2 t;
  vec3 pt = p;
    pt.y +=+time*.35;
    float idy = floor(pt.y);
    pt.xz *=rot(time*.33+idy);
    pt.xz = abs(pt.xz)-1.;
 
    pt.y = fract(pt.y)-.5;
    t.x  = min(.25,length(pt)-(.2+fract(time)*.2));
    t.y = 2.+ mod(idy,2.);
    ln = pt;
   
  h = t.x < h.x ? t:h;

  
    
  
  return h;
 }
#define q(s) s*sdf(p+s).x

 float ao(vec3 rp, vec3 n, float k){
    vec2 d = sdf(rp+n*k);
    if(d.y==2.){
       return 1.;
      }
     return d.x /k;
   }

vec3 norm(vec3 p,float ee){vec2 e= vec2(-ee,ee);return normalize(q(e.xyy)+q(e.yxy)+q(e.yyx)+q(e.xxx));}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
 float timer = fract(time*.06);
 
  vec3 col = vec3(.1);

  vec3 ro = mix(vec3(0.,0.,-7.),vec3(0.,100.,-1.25),timer);
  vec3 rt = mix(vec3(0.,0.,-0.),vec3(0.,110.,-0.),timer);
  vec3 z = normalize(rt-ro);
  vec3 x = normalize(cross(z,vec3(0.,-1.,0.)));
  vec3 y = normalize(cross(z,x));
  
  vec3 rp = ro;
  vec3 rd = mat3(x,y,z)*normalize(vec3(uv,1.));
  
  vec3 light = vec3(1.,2.,-3.);
  float dd =0.;
  vec3 acc = vec3(0.);
  bool nohit = false;
  for(float i=0.;i<=128.;i++){
    
      vec2 d = sdf(rp);
    
    dd +=abs(d.x);
    if(dd > 60.){nohit= true; break;}
    
    if(d.y==2. && d.x <.1){
      
        acc += vec3(1.,.30,.0)*exp(-abs(d.x))/18.;
        d.x = max(.002,abs(d.x));
      }
      if(d.x <.001){
          vec3 l2 = normalize(ln);
          vec3 n = norm(rp,.0003);
          float diff = max(0.,dot(normalize(light-rp),n));
          float diff2 = max(0.,dot(l2,n));
     
          if(d.y==1.) { 
            col = vec3(.1)*diff+ vec3(1.,.30,.0)*diff2;;  
             rd = reflect(rd,n);
             rp+=rd*.1;
           
          } else if (d.y==3.){
              col = vec3(.1,.1,.1)*diff;
                break;
              }
          
    
       
          
          }
          rp+=rd*d.x;
 }
  col +=acc;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
