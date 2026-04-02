#version 420

// original https://www.shadertoy.com/view/dlffD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y;
    uv *= 4.;
    uv -= time;
    uv.y  = fract(uv.y + time) - .5;
    uv.y= abs(uv.y);
    float d = 0.;  
         
    float angle = 1.;
    for( float i = 0.; i < 100. ; i++){
        uv = abs(uv) -1.7 * 900000.;
        uv *= mat2(sin(angle),cos(angle),-sin(angle),sin(angle));
        
     } 
    
       
   vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));       
    // Output to screen
    glFragColor = vec4(col,1.0);
}
