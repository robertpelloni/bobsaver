#version 420

// original https://www.shadertoy.com/view/fdfSz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fGlobalTime time
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
float ball(vec3 p,float l){
    return length(p)-l;
}

vec2 mmin(vec2 a,vec2 b){return a.x < b.x ? a:b;}
float box(vec3 p,vec3 a){
  vec3 q = abs(p)-a;
   return length(max(vec3(0.),q)+min(0.,max(q.z,max(q.x,q.y))));
  }
vec2 ball1(vec3 p){ 
 
  vec2 d = vec2(10000.,-1.);
   float c = 6.;
  for(float i=0.;i<=c;i++){ 
       p= abs(p)-.200*i;
        p.xz = p.x > p.z ? p.xz:p.zx;

        p.xy *=rot(.754*i);      

       p.xy = p.x > p.y ? p.xy:p.xy;
        if(mod(i,2.)==1.){
        d = mmin(d, vec2(ball(p+vec3(1.5*(1.+i/c),0.,.0),1.)/2.5,mod(i,2.)+1.0));
        } else {
          d = mmin(d, vec2(box(p+vec3(1.8+p.y*(1.+i/c),-0.5,.0),vec3(0.5,0.5,.6))/1.5,mod(i,2.)+1.0));
          }
     
      
    }
    return d;

}
vec2 sdf(vec3 p){
  p.zy *=rot(sin(fGlobalTime*.3)*.5);
    p.xy *=rot(fGlobalTime*.1);
  vec2 b1 = ball1(p);
 // p.zy *=rot(3.141591/4.+fGlobalTime);
  p.y = abs(p.y)-.5;
   p.x = abs(p.x)-.5;
  vec2 aa =p.xy *rot(p.z*4.);
  vec2 bb =p.xy *rot(p.z*8.);
  
    p.xy = mix(aa,bb,-1.5);
    
  for(float j=0.;j<=2.;j++) { p.yxz = abs(p.zyx)-.2; p.yx *=rot(1.3*j);};
    
     p.yz = p.z > p.y ? p.yz:p.yx;
  vec2 b2 = vec2(box(p,vec3(.151)+vec3(.4,.0,.0))/4.9,3.);
  return mmin(b1,b2);
}
  
 vec2 nv= vec2(.001,.0);
  vec3 norm(vec3 p){
      return normalize(vec3(sdf(p+nv.xyy).x-sdf(p-nv.xyy).x,sdf(p+nv.yxy).x-sdf(p-nv.yxy).x,sdf(p+nv.yyx).x-sdf(p-nv.yyx).x));
    }

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

vec3 col = vec3(.1);
  vec3 ro = vec3(.0001,.0001,-2.1);
  vec3 rd = normalize(vec3(uv,.6));
  vec3 rp = ro;
  float td =0.;
  vec3 light = vec3(.01,.02,.03);
  for(float i=0.;i<=69.*3.;i++){
        vec2 d = sdf(rp);
        rp += rd*d.x*.8;
        td += d.x;
        if(d.x<= 0.000001){
           vec3 n = norm(rp);
          float ld = length(light-rp);
          if(d.y == 1.0){  
           
            col += vec3(0.2,.5,.5)*dot(normalize(light),n)*2./ld;
            break;
          } else if(d.y == 2.){
              rd = reflect(rd,n);
              rp += rd*0.01;
            col +=vec3(.1,0.,0.);
            }
          else if(d.y == 3.){
              rd = reflect(rd,n);
              rp += rd*0.00001;
            col +=vec3(.3,0.2,0.1);
            }
          }
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
