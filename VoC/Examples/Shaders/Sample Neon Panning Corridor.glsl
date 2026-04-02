#version 420

// original https://www.shadertoy.com/view/3tySDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void)
{
    vec2 xy = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    
vec2 uv=xy;
    
    xy.y +=0.008*sin(100.*uv.y+time); //optional ripple effect
    xy*=.46;
    xy.x-=.05;
    //xy.x-=.3;
    xy.y+=.15;
    xy.y=abs(xy.y);
    xy+=.1;//+sin(time)/20.;
    vec3 col = 0.5 + 0.5*cos(time*4. +
                             xy.x*vec3(0.0, -2.0, -2.0)/
                             xy.y*vec3(0.0, sqrt(12.0), -sqrt(12.0)));
    col=col*vec3(.2,.9,.1);//less colorful
    // Output to screen
    glFragColor = vec4(col,1.0);
  glFragColor+=(hash42(uv*1e3+time*.2)-.5)*.2;  // optional film grain effect from https://www.shadertoy.com/view/tdy3DD
}
