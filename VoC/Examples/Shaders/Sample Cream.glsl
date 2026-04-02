#version 420

// original https://www.shadertoy.com/view/3lXGWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = gl_FragCoord.xy/resolution.x;
   
    u.y += sin(u.x*25.3)*.03 + time*.1;
    u *= vec2(30,10);

    float x = u.x + time + floor(u.y) * 23.,
          y = fract(u.y),
          f = .5 + sin(x*.22)*.2,
          w = 1. - sin(x-cos(x))*f  
                 - sin(x*1.7)*.1,
          k = smoothstep(w*.9,w,y*2.);    

    glFragColor = vec4( (y-k) *1.5 );
}
