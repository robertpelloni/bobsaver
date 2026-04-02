#version 420

// original https://www.shadertoy.com/view/Xs2yRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float zoom = 0.5;
    vec2 uv = zoom * (gl_FragCoord.xy - resolution.xy / 2.0);
        
    float t = time * 3.1415;
    
    float x = uv.x;
    float y = uv.y;
    
    
    float pi = acos(-1.);
        
   
    float m = 1.;
    float n = 8.;
    float p = 1.;
    
    float r = sqrt(x*x+y*y);
    float th = atan(y, x);
   
    
    float value = 0.;
    
    const int points = 7;
    
    for(int i = 0; i < points ; i++){
      float angle = pi / float(points) * float(i);

      float w = x * sin(angle) + y * cos(angle);

      value += sin(w + t);
    };

        
    float color = (sin(value * pi / 2.) + 1.) * 1.5;
    
    if(color > 0.0) {
      glFragColor = color - vec4(0,1.5,2,0); 
    } else {
      //glFragColor = vec4(med, med, low,1.0);
      glFragColor = -color - vec4(1,1.5,0,0); 
    }
}
