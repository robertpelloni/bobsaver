#version 420

// original https://www.shadertoy.com/view/3tK3WK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Using code from

// Inigo Quilez for the primitives
// https://www.shadertoy.com/view/Xds3zN

//Morgan McGuire for the noise function
// https://www.shadertoy.com/view/4dS3Wd

#define time time

uniform vec2 v2Resolution; // viewport resolution (in pixels)

float random (in float x) {
    return fract(sin(x)*1e4);
}

float noise(in vec3 p) {
    const vec3 step = vec3(110.0, 241.0, 171.0);

    vec3 i = floor(p);
    vec3 f = fract(p);

    // For performance, compute the base input to a
    // 1D random from the integer part of the
    // argument and the incremental change to the
    // 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix( mix(mix(random(n + dot(step, vec3(0,0,0))),
                        random(n + dot(step, vec3(1,0,0))),
                        u.x),
                    mix(random(n + dot(step, vec3(0,1,0))),
                        random(n + dot(step, vec3(1,1,0))),
                        u.x),
                u.y),
                mix(mix(random(n + dot(step, vec3(0,0,1))),
                        random(n + dot(step, vec3(1,0,1))),
                        u.x),
                    mix(random(n + dot(step, vec3(0,1,1))),
                        random(n + dot(step, vec3(1,1,1))),
                        u.x),
                u.y),
            u.z);
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float sphere(in vec3 p, in vec2 uv) {
  vec3 truc = vec3(p.x,p.y,0.0);
  return length(truc)-1.0;
}

float fog(in vec3 p, vec3 centerPos, float scale,float radius ) {
  
  float x=(noise((p+(time*1.0)*2.0)*0.2)*2.0-1.0)*15.0;
  float y=(noise((p+(time*1.0+5.0)*2.0)*0.2)*2.0-1.0)*15.0;
  float z=(noise((p+(time*1.0+3.5)*2.0)*0.2)*2.0-1.0)*15.0;
  p+=vec3(x,y,z);
    return max((noise(p*scale)+noise(p*2.0*scale)*0.5+
              noise(p*3.0*scale)*0.33+
              noise(p*4.0*scale)*0.25)*0.4807,0.0)*5.0;
}
  

float map(vec3 p, vec2 uv){
  return sphere(p,uv);
  }

 
float mapHyper(vec3 p){ 
  return fog(p,vec3(0,0,0),0.5,0.1);
  }  

  
float dot2( in vec3 v ) { return dot(v,v); }

float udQuad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d )
{
    
    vec3 ba = b - a; vec3 pa = p - a;
    vec3 cb = c - b; vec3 pb = p - b;
    vec3 dc = d - c; vec3 pc = p - c;
    vec3 ad = a - d; vec3 pd = p - d;
    vec3 nor = cross( ba, ad );

    return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float map3(vec3 p){
return udQuad(p,
              vec3(5, 0, 100.0),
              vec3(-5.0, 0, 100.0), 
              vec3(-5.0,   cos(time*0.35)*2.0, -100.0),
              vec3(5.0,  cos(time*0.35)*2.0, -100.0));
  }
  
void main(void)
{
    
    
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1.0);
  vec3 s=vec3(0.0,0.0,-100.0);
  vec3 t=vec3(0.0,0.0,0.0);
  vec3 cz=normalize(t-s);
  vec3 cx=normalize(cross(cz,vec3(0,1,0)));
  vec3 cy=normalize(cross(cz,cx));
  vec3 r=normalize(uv.x*cx+uv.y*cy+cz*0.7);
  
  vec3 p=s;
 float dd=0.0;
  
  vec3 col=vec3(0.0);
//  float text1=mapHyper(p);
  if(dd==500.0)col = vec3(0.0);
  p=s;
  dd=0.0;
  vec2 c= vec2(0,0);
  for(int i=0; i<1000; ++i) {
    float d=map(p,uv);
    float d2=map3(p);
   float mH=mapHyper(p);
    c+=vec2(pow(mH*0.06,2.0)*clamp(0.2-d2,0.0,1.0)*0.55+
       pow(mH*clamp(cos((p.x+sin(p.x+time*100.0))*20.0),0.0,1.0),4.0)*0.007*clamp(0.05-d2,0.0,1.0)+mH*0.0004,0.0)+
       pow(mH*0.06,2.0)*clamp(1.0-d2,0.0,1.0)*0.20;

    if( d>0.0001 ){ break;}
    p+=r*(0.1);
    dd+=0.1;
  }
  
 
  
  col = mix(vec3(0,0,0),vec3(0.5,0.5,0.8),c.x);
  
  
  glFragColor = vec4(col,1.0);
}
