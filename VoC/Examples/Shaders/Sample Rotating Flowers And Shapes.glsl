#version 420

// original https://www.shadertoy.com/view/msjSRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795
#define len 5.0

// Author: Elio Ramos (@garabatospr instagram, twitter) 

// color palette

const vec3 COLORS[]=vec3[](
    vec3(0.949,0.922,0.541),
    vec3(0.996,0.816,0.),
    vec3(0.988,0.518,0.0),
    vec3(0.929,0.212,0.102),
    vec3(0.886,0.941,0.953),
    vec3(0.702,0.863,0.878),
    vec3(0.267,0.392,0.631),
    vec3(0.125,0.188,0.318),
    vec3(1.,0.773,0.78),
    vec3(0.953,0.596,0.765),
    vec3(0.812,0.22,0.584),
    vec3(0.427,0.208,0.541),
    vec3(0.024,0.706,0.69),
    vec3(0.294,0.541,0.373)  
);

float Hash21(vec2 p) {
    p = fract(p*vec2(234.234, 435.145));
    p += dot(p, p+34.236767);
    return fract(p.x*p.y);
}

// get "random" color based on location 

vec3 getColor(vec2 id,float seed)
{
  return COLORS[int(14.*Hash21(id*seed))];
}

// standard 2d rotation matrix 

mat2 rotate2d(in float radians)
{
  float c = cos(radians);
  float s = sin(radians);
  return mat2(c, -s, s, c);
}

// distortion function 

vec2 distort(vec2 uv,float freq)
{
  float freq1 = 2.;
  float freq2 = 2.;

  float x = uv.x;
  float y = uv.y;

  return vec2(x + cos(freq1*y + freq*time)*0.1,y + cos(freq2*x + freq*time)*0.1);
}

// draw flowers with polar coordinates 

vec3 drawFlower(vec2 uv,vec2 offset,float rad,vec3 col,vec3 col1,vec3 col2)
{
   float n = floor(10.*Hash21(offset));
   uv -= offset; 
   uv *= rotate2d(time*0.1);
   float a = atan(uv.y,uv.x);
   float r = length(uv);
   float f = rad*cos(n*a);
   float blur = 0.01;
   return mix(mix(col1,col2,r),col,smoothstep(f-blur,f,r));
   //return mix(mix(col1,col2,r),col,smoothstep(-1.5,0.,(r-f) / fwidth(r-f)));
   
}

void main(void)
{
    
    vec2 uv = gl_FragCoord.xy/resolution.xy -0.5;
    
    uv.x *= resolution.x/resolution.y;
 
    uv *= 5.0; 
 
    uv = distort(uv,1.);
 
    vec3 col = mix(COLORS[3],COLORS[2],uv.y);
    
    
    for(float x = -len;x <= len;x+=1.)
    {
      for(float y = -len;y <= len;y+=1.)
      {
        vec2 pos = vec2(x,y) + 0.5;

        float rang  = 2.0*PI*(Hash21(pos*678.));
        float radFlower = Hash21(pos*945.)*2. + 0.1;
        float dir = sign(0.5 - Hash21(pos*145.));
        uv *= rotate2d(rang*dir*time*0.01);
        col = drawFlower(uv,pos,radFlower,col,getColor(pos,567.),getColor(pos,145.));
        
      }
    } 
   
    
    glFragColor = vec4(col,1.0);
}
