#version 420

// original https://www.shadertoy.com/view/lslfDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2 R = resolution.xy;
    
    //uncomment for pixelated chunky display
    //u = trunc(u*.15)/.15; 
    
    u.x -= 225.;
    
    vec4 c = vec4(.6*u/R, .25, 1).yzxw;
    
    glFragColor -= glFragColor;
    for (float i = -3.; i<3.; i++)
        glFragColor += sin( length( (u-R*.5)*.12 - vec2(0,6)* sin(20.2*i+.6*time) ) ), 
        u.x += 90.;
 
    glFragColor = abs(glFragColor*c);
}
