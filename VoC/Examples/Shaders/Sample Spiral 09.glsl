#version 420

// original https://www.shadertoy.com/view/4lGSWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//spiral made of circles of increasing radius
//with circle color varying with time and distance to circle center

// Falloff : attenuation en fonction de la distance
// x : distance
// r : distance limite
// a : coefficient de ponderation
float Falloff(in float x,in float r,in float a)
{
    if (x<r)
    {
        float t = x / r;
        return a*(1.0-t*t)*(1.0-t*t)*(1.0-t*t);
    }
    else
    {
        return 0.0;
    }
}

// Cercle
// c  : Centre
// r  : Rayon
// uv : position pixel
// old : ancienne couleur
vec4 Circle(in vec2 c,in float r, in vec2 uv)
{
  float L=length(uv-c);
 
  // Dans le cercle si distance < rayon
  if (L<r)
  {  
      //chaque couleur varie en fonction de la distance au centre L
      //et en fonction du temps, avec desynchronisation
      
       float red = 0.5*sin((-time*1.0+10.0*L)+1.0);
       float green = 0.5*sin((-time*2.0+20.0*L)+1.0);
       float blue = 0.5*sin((-time*3.0+30.0*L)+1.0);
     
    return Falloff(L,r,1.0)*vec4(red, green, blue, 1.0);
  }
  // Else ancienne couleur
  else
  {
    return vec4(0.0);
  }
}

// Image
void main(void)
{
    glFragColor=vec4(0.0);
  //parametre :
    
  const float circle_size = 0.01;
    
  //spirale de cercles de rayon croissant
    
  vec2 uv = (gl_FragCoord.xy-resolution.xy/vec2(2.0)) / resolution.y;

  for (int k=0;k<int(1.0/circle_size);k++)
  {
      vec2 q=(circle_size*float(k))*vec2(cos(0.5*float(k)),sin(0.5*float(k)));
   
      glFragColor =  glFragColor + Circle(q,circle_size*float(k),uv);
   }
}
