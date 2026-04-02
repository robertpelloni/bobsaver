#version 420

// original https://www.shadertoy.com/view/3sByRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdEllipsoid( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}
#define ITER 32.
#define PI 3.141592
#define bpm time * (130/60)
float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
mat2 r(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,s,-s,c);
}
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float fig(vec3 p,float offset) {
     p.yz = p.zy;
     p.xy*=r(p.z*2.+time+offset);
     
     
     //float t = fract(time*.1)*10. <= 5. ? time*8. : floor(time*8.) ;
     float  t = time*4.;
     return sdTorus(p,vec2(.4+sin(offset+t+atan(p.x,p.z)*6.)*.2+.75,.05))*.4;
}
vec2 SDF(vec3 p) {
     float f = 100.;
     float id = 0.;
     for(float i=0.;i<=1.;i+=1./6.){
         float o = fig(p,i*acos(-1.)/(4.+sin(time+i)));
         
         f = min(f,o);
         if(f == o) id = i;
     
     }
     
     return vec2(id,f);
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
     
    vec3 ro =vec3(0.,0.,-3.),
    p = ro,
    rd = normalize(vec3(uv,1.)),
    col = vec3(0);
     
    float shad = 0.;
    bool hit = false;
    vec2 d = vec2(0.);
    for(float i=0.;i < ITER; i++) {
        d = SDF(p);
        if(d.y< 0.001) {
            hit = true;
            shad = i / ITER;
            break;
        }
        p += d.y*rd;
    }
    
    if(hit) {
      
        col = vec3(1.-shad*d.x,1.10*shad*(1./d.x),smoothstep(.1,0.9,d.x));
      

    }
    
     
     
    
    glFragColor = vec4(col,1.0);
}
