#version 420

// original https://www.shadertoy.com/view/MdlyRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float SmoothCurve(float t){
 return smoothstep(0.0,1.0,t);   
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv-=0.5;
    uv.x*= resolution.x/resolution.y;
       uv*=0.2 + 3.0*(0.5+0.5*sin(0.3*time));
    
    float vel = 0.1;
    vec2 uvrot = uv;
    uvrot.x = cos(vel*time)*uv.x + sin(vel*time)*uv.y;
    uvrot.y = -sin(vel*time)*uv.x + cos(vel*time)*uv.y;
    uv = uvrot;
    
    float radius = 0.6;
    float offset = 0.01;
    float freq = 3.0;    
       
    float maskx = 2.0*smoothstep(0.0,0.0,sin(freq*2.0*3.1419*uv.y))-1.0; 
    float masky = 2.0*smoothstep(0.0,0.0,sin(freq*2.0*3.1419*uv.x))-1.0; 

    float t = mod(time,4.0);
    
    if(t<1.0){
          uv.x += SmoothCurve(t)*maskx;  
    }else if(t<2.0){
          uv.y += SmoothCurve(t-1.0)*masky;  
    }else if(t<3.0){
          uv.x -= SmoothCurve(t-2.0)*maskx;          
    }else if(t<4.0){
          uv.y -= SmoothCurve(t-3.0)*masky;             
    }
    
       
    float f = sin(freq*2.0*3.14159*uv.x)*sin(freq*2.0*3.1419*uv.y);
    f = 1.0-smoothstep(radius-offset,radius+offset,abs(f));
    
    glFragColor = vec4(f,f,f,1.0);
    
}
