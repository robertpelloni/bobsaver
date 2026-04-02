#version 420

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time*0.3

//gtr State Of The Art Amiga
void main( void ) {
    
   glFragColor *= vec4(0.0);   // ios fix    

   vec2 p =   gl_FragCoord.xy / resolution.xy *2.-1.  ;
   p.x *= resolution.x/resolution.y;
    
  vec2 p1 =   gl_FragCoord.xy / resolution.xy *2.-1.  ;
   p1.x *= resolution.x/resolution.y;    
    
    
  vec2 c1 = vec2(0.9, 0.0);
    c1 += vec2(-0.9+sin(time)  , cos(time) * .85);
    
    vec2 c2 = vec2(0.0, 0.25);
    c2 += vec2(-sin(time+sin(time)) * 1.40, cos(time) * .85+sin(time*0.4));
        
    
     
    // really  nightmare here !! 
   
      
  //  p = p+c1;
    p1 = p1+c2;
   
    p1 = abs(p1);    
   // p = abs(p); 
   
  if (mod(float(int((distance(p,c1)) * 20.0)), 2.) == 0.){
      
   float r = 0.5*sin(40.* ( p.y+p.x*0.2)+time*2.)+0.5 ;
    
    float g = 0.5*sin(30.* ( p.y+p.x*0.3)+time*3.)+0.5 ;
    
    float b = 0.5*sin(20.* ( p.y+p.x*0.4)+time*4.)+0.5 ;
          
    glFragColor = vec4(r,g,b,1.0) ;      
      
   
   
    }
           
    
     // sq 
     
    if (mod(float(int(abs(max(p1.x,p1.y)+c1) * 15.0)), 2.) == 1.){
        
    
       glFragColor.rgb = 1. - glFragColor.rgb * vec3(0.99,0.99,0.99);
    
         
    }    
    

}
