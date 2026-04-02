#version 420

// original https://www.shadertoy.com/view/tlBcD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI  3.1415
#define TAU 2.0*PI
#define zero vec2(0.,0.)

#define K .05
#define RECUR 45.
#define BASE_SIZE 1.0
float det(vec2 a,vec2 b) {
    return (a.x * b.y) - (a.t * b.x);
}
vec2 intersect(vec2 a, vec2 b,vec2 p,vec2 q) {
       vec2 xdiff = vec2(a.x-b.x,p.x-q.x);
       vec2 ydiff = vec2(a.y-b.y,p.y-q.y);
      
       float div = det(xdiff,ydiff);
       
       vec2 d = vec2(det(a,b),det(p,q));
       return vec2(det(d,xdiff),det(d,ydiff))/div ;
       
    }
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}
vec2 coord(float a,float r) {
    return vec2(cos(a),sin(a))*r;
}
mat2 r(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,s,-s,c);
}

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}
void main(void)
{
    vec2 uv =( gl_FragCoord.xy-.5* resolution.xy)/resolution.y;
    uv*=2.;
    uv +=vec2(cos(time),sin(time))*.1;
    uv*=r(3.*sin(atan(uv.x,uv.y)*.45));
    vec2 id = floor(uv);
    uv=fract(uv)-.5;
    float d = 0.;
    vec3 col = vec3(0.);
    float q = 6.+cos(floor(time)+pow(fract(time),2.))*2.;
    float stepT = TAU/q;
   
   float D =1./20.;
   
   float loop_start;
   float loop_end;
   float stp;
   if(mod(id.x,2.)==0.){
      uv.x = -uv.x;
      
   } 
   if(mod(id.y,2.) == 0.){
   uv.y = -uv.y;
   }
  
   for(float j=0.;j<1.;j+=1./RECUR){
        for(float i=0.;i<=TAU;i+=stepT) {
         d += smoothstep(0.018,0.003,
         sdSegment(uv,coord(i,BASE_SIZE), coord(i+stepT,BASE_SIZE)  ));
      }
      vec2 ipoint = intersect(zero,coord(0.+K,BASE_SIZE),coord(stepT,BASE_SIZE),coord(0.,BASE_SIZE));
      float dst = length(ipoint);
      uv*=1./dst;
     uv *=r(K) ;
    col += d*(palette(j + mod(time*.2,2.),vec3(.5),vec3(.5),vec3(1.),vec3(0.50, 0.10, 0.33))/RECUR);
     
    }
     //col = mix(vec3(.1),vec3(.2,.3,.5),col);
    //vec3 col = vec3(d);
    
    glFragColor = vec4(col,1.0);
}
