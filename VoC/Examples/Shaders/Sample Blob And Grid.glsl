#version 420

// original https://www.shadertoy.com/view/sl2yW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

Greetings 
All Revision participants
All Live Shader coders

In particular Gaz and Kamoshika that I heavly based the code on their work :D 

*/

// I CERTIFY ITS NOT A BOT

mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
float diam(vec2 p,float s){
   p = abs(p);
   return (p.x+p.y-s)*inversesqrt(3.);
     
}
float smin(float a,float b,float r){
    float k = max(0.,r-abs(a-b));
  return min(a,b) -k*k*.25/r;
  
}

void main(void)
{
   float bpm = (time*60./130.*2.);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    bpm = floor(bpm)+pow(fract(bpm),.5);

    vec3 col = vec3(.1);
    vec3 p,d = normalize(vec3(uv,1.));
  
    for(float i=0.,g=0.,e;i++<99.;){
    
      p = d*g;
      p.z -=5.;
       
      vec3 gp = p;
      gp.xy *=rot(gp.z*.1);
      gp.y =-abs(gp.y);
      gp.y +=1.;
 
     
      float dd,c=20./3.141592;
  
      gp.xz = vec2(log(dd=length(gp.xz)),atan(p.x,p.z))*c;
                                            // Here I struggle during live 
                                            // as I was doing p.y (which is to do torus)
                                            // Rather than atan(p.x,p.y) to have proper log polar
      gp.y/=dd/=c;
      gp.y +=sin(gp.x)*.5;
      gp.xz = fract(gp.xz+time)-.5;
     
      for(float j=0.;j<4.;j++){ 
        gp.xzy = abs(gp.xzy)-vec3(.1,.01,.1);
         gp.xz *=rot(-.785);
      }
      float ha_grid = dd*.8*min(diam(gp.xy,.01),diam(gp.zy,.01));
           // You're a variable Harry
    
    
      float f = ha_grid;
    
      float blob = length(p)-.5;
      float gy = dot(sin(p*4.),cos(p.zxy*2.))*.1;
      for(float j=0.;j<16.;j++){ 
           vec3 off = vec3(cos(j),tan(bpm+j),sin(j*3.33))+gy;
            blob = smin(blob,length(p-off)-.125,.25); 
      }
    
      f= smin(f,blob,.5);
      g+=e=max(.001,f);;
      col+= mix(vec3(1.,.2,sin(p.z+bpm)*.5+.5),vec3(.5,sin(p.z)*.5+.5,.9),fract(2.*i*i*e))*.25/exp(i*i*e);
    
   }
    // Output to screen
    glFragColor = vec4(col,1.0);
}
