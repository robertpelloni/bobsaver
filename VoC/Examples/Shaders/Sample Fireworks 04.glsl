#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define N(h) fract(sin(vec4(6,9,1,0)*h) * 9e2) 

void main(void) { 
    vec4 o; 
    vec2 u = gl_FragCoord.xy/resolution.y;
    
    float e, d, i=0.;
    vec4 p;
    
    for(float i=0.; i<9.; i++) {
      d = floor(e = i*9.1+time);
      p = N(d)+.3;
          e -= d;      
      for(float d=0.; d<50.;d++)    
        o += p*(1.-e)/1e3/length(u-(p-e*(N(d*i)-.5)).xy); 
    }
    
     if(u.y<N(ceil(u.x*10.+d+e)).x*.5) o-=o*u.y;
     glFragColor = vec4(o.rgb, 3
                );
}
