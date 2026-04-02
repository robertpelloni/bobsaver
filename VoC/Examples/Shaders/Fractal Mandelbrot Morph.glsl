#version 420

// original https://www.shadertoy.com/view/ltyGzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 complexExp(vec2 z, vec2 w){
   float l = length(z);
   float zsq = l*l;
   float argz = atan(z.y,z.x);
   float alpha = pow(zsq,0.5*w.x)* exp(-w.y*argz);
   float beta = w.x*argz + 0.5*w.y* log( zsq); 
    
   return alpha*vec2(cos(beta),sin(beta)) ; 
}

float mandelbrot(vec2 z,vec2 w){

  vec2 c = z;
                                                             
  int n=1;
  const int   maxitn = 50;                              
  
    for( int i = 0;i<maxitn;i++){
      
        z = complexExp(z,w) + c;
        
        if(length(z) >= 2.0) {
            return float(i)/float(maxitn);
        }
    }
   
   return 0.0;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float aspectRatio = resolution.x/resolution.y;
    vec2 z = 2.0*uv + vec2(-1.0,-1.3);
    z.x = z.x*aspectRatio;
    z = vec2(z.y,z.x);
    
    
    vec2 w = vec2(4.0  + 3.0*cos(time),0.0);
    float t = mandelbrot(z,w);
    
    float a = cos(time);
    float b = sin(time);        
     float c = cos(3.27*time);
    
    glFragColor = vec4(pow(t,1.0 +0.3*a ),pow(t,1.0+0.3*b),pow(t,0.7+0.3*c),1.0);
}

                                                                                       
