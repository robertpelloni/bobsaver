#version 420

// original https://www.shadertoy.com/view/4sSyRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float zoom = 0.5;
    vec2 uv = zoom * (gl_FragCoord.xy - resolution.xy / 2.0);
        
    float t = time *.5;
    
    float x = uv.x;
    float y = uv.y;   
    
    float pi = acos(-1.);
          
    float n = 7.;
    float p = 7.;
    float m = p/n;
   
    float value = 0.;     
    
    for(float i = 0.; i < p ; i+=m){
      float angle = pi / p * i;
      float w = x * sin(angle) + y * cos(angle);
      value += sin(w + t);
    };
        
    float c = (sin(2.*value * pi / p ) + 1.) * .5;

    glFragColor = clamp(vec4(2.*c-1.,.6-2.*abs(0.5-c)+2.*c-1.,.4-2.*c,0),0.,1.);
    
}
