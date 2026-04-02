#version 420

// original https://www.shadertoy.com/view/td3Sz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
  vec2 p=(3.3*gl_FragCoord.xy-resolution.xy)/max(resolution.x,resolution.y);
    
  for(float i=3.3;i<33.;i++)
    {
        p+= .33/i * cos(i*p.yx+time*vec2(.33,.33)  + vec2(.33,3.3)); 
    }
    vec3 col=vec3(.33*sin(3.3*p.x)+.33,.33*sin(3.3*p.y)+.33,sin(3.3*p.x+3.3*p.y));
    glFragColor=(3.3/(3.3-(3.3/3.3)))*vec4(col, 3.3);
}
