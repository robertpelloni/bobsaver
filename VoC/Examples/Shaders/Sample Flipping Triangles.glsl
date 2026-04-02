#version 420

// original https://www.shadertoy.com/view/ttsyD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

float t(vec2 uv, float a){
   
       float d = step(uv.y,1.+tan(-PI/2.+a)*(1.-uv.x));
    float b = step(uv.y,uv.x*tan(a));

    if(a>PI/4.){
        d *= b;
    } else {
        d += b;
    }
            
      return clamp(d,0.,1.);    
}

void main(void)
{
    vec2 p = gl_FragCoord.xy;

    p = p/resolution.y;
    
    vec2 pos = fract(p*12.);
    vec2 id = floor(p*12.);
    
    float a = (id.x-id.y)/15.-time*.5;
    
    float ti = PI*fract(a)/2.;
    
    float d = t(pos, ti);
    
    a = floor(mod(a,2.));
    
    d = mod(a + d, 2.);   
       
    glFragColor = vec4(vec3(1.0-abs(d)),1.0);
    
    
}
