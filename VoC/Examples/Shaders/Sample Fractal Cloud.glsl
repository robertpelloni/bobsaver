#version 420

// original https://www.shadertoy.com/view/NsySD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 0

mat2 rot(float a)
{
  float s = sin(a), c = cos(a);
  return mat2(c,-s,s,c);
}

float cube(vec3 p)
{
  vec3 a = abs(p) - 1.;
  return max(a.x, max(a.y, a.z));
}

mat2 mx, my, mz;
float fold(vec3 p)
{
  float scale = 50.0;
  p *= scale;
  int iter = 13;
  for (int i=0; i < iter; i++)
  {
    p.xy *= mz;
    p.yz *= mx;
    p.xz *= my;
    p = abs(p) - float(iter - i);    
  }
  return cube(p) / scale;
}

float map(vec3 p)
{
   return fold(p);
}

float rayCastShadow(in vec3 ro, in vec3 rd)
{
   vec3 p = ro;
   float acc = 0.0;
   float dist = 0.0;

   for (int i = 0; i < 32; i++)
   {
      if((dist > 6.) || (acc > .75))
           break;

      float sdf = map(p);
      
      const float h = .05;
      float ld = max(h - sdf, 0.0);
      float w = (1. - acc) * ld;   
     
      acc += w;
             
      sdf = max(sdf, 0.05);
      p += sdf * rd;
      dist += sdf;
   }  
   return max((0.75 - acc), 0.0) / 0.75 + 0.02;
}

vec3 Render(in vec3 ro, in vec3 rd)
{
   vec3 p = ro;
   float acc = 0.;
   
   vec3 accColor = vec3(0);
   
   float dist = 0.0;

   for (int i = 0; i < 64; i++)
   {
      if((dist > 10.) || (acc > .95))
        break;

      float sdf = map(p) * 0.80;
      
      const float h = .05;
      float ld = max(h - sdf, 0.0);
      float w = (1. - acc) * ld;   
     
      accColor += w * rayCastShadow(p, normalize(vec3(0.75,1,-0.10))); 
      acc += w;
       
      sdf = max(sdf, 0.03);
      
      p += sdf * rd;
      dist += sdf;
   }  
    
   return accColor;
}

mat3 setCamera( in vec3 ro, in vec3 ta )
{
    vec3 cw = normalize(ta-ro);
    vec3 up = vec3(0, 1, 0);
    vec3 cu = normalize( cross(cw,up) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    mz = rot(time * 0.19);
    mx = rot(time * 0.13);
    my = rot(time * 0.11);

    vec3 tot = vec3(0.0);
        
#if AA
    vec2 rook[4];
    rook[0] = vec2( 1./8., 3./8.);
    rook[1] = vec2( 3./8.,-1./8.);
    rook[2] = vec2(-1./8.,-3./8.);
    rook[3] = vec2(-3./8., 1./8.);
    for( int n=0; n<4; ++n )
    {
        // pixel coordinates
        vec2 o = rook[n];
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
#else //AA
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif //AA
 
        // camera       
        float theta    = radians(360.);// *(mouse*resolution.x/resolution.x-0.5);
        float phi    = radians(90.);// *(mouse*resolution.y/resolution.y-0.5)-1.;
        vec3 ro = 6. * vec3( sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta));
        vec3 ta = vec3( 0 );
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta );
        
        vec3 rd =  ca*normalize(vec3(p,1.5));        
        
        vec3 col = Render(ro ,rd);
        
        tot += col;         
#if AA
    }
    tot /= 4.;
#endif
    glFragColor = vec4( sqrt(tot), 1.0 );
}
