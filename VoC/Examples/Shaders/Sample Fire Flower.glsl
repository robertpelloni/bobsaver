#version 420

// original https://www.shadertoy.com/view/MdVfRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265359,
    arms = 10.,
   speed = 1.5,
   width = .4,
subdivide = 5.;

vec4 color = vec4(1.,.4,.1,0.);

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy ) / resolution.y;
    
    float len = length(uv),
           angle = (atan(uv.x,uv.y)/(2.*PI))+1.5,
        wobble = 6.+4.*cos(time/5.),
        white = fract((angle)*arms+sin((sqrt(len)*wobble)-time*speed));
    
    white  = 2.*sin(white/(PI/10.));
    white *= floor(fract(angle*arms+sin(time/speed-(len*1.2)*wobble))*subdivide)/subdivide;
    
    vec4 O = smoothstep(0.,1.,white*color);
    
    vec4 levels = vec4(4,8,16,1);
    O = floor(O*levels)/levels;

    glFragColor = O;
}
