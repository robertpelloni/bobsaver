#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdyXDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv;
    
  
    uv.x = gl_FragCoord.x/resolution.x;
    uv.y = gl_FragCoord.y/resolution.y;
    
    uv.x -= 0.5;
    uv.y -= 0.5;
        
    // set Image aspect to square or you will get an oval
    uv *= resolution.xy  / resolution.y;
        
    float zoom = sin(time/10.0)*10.0; 
    
    float u = uv.x*cos(time/2.0)*zoom+uv.y*(-sin(time/2.0))*zoom;
    float v = uv.x*sin(time/2.0)*zoom+uv.y*cos(time/2.0)*zoom;
    
    float xorpattern = float(
        int(u*10.0)
        ^
        int(v*10.0)
    );
        
    
    vec3 color1 = vec3(
        0.0, 
        xorpattern/10.0,  
        xorpattern/50.0
       
    );
    
    glFragColor = vec4(color1, 1.0);
    
    //distance(vec2(0.5), uv)
      //  sin(uv.x*10.0+time*6.0)+sin(uv.y*10.0+time*6.0)),
//     u = x*cos(W)+y*(-sin(W));
//     v = x*sin(W)+y*cos(W);
//     color = getpixel(u,v,quellbild);
//     putpixel(x,y,color,zielbild);

}
