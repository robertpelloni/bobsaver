#version 420

// original https://www.shadertoy.com/view/fdsfDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define yellow vec3(248.0, 223.0, 118.0)/256.0
#define gray vec3(69.0, 41.0, 52.0)/256.0
#define red vec3(255.0, 74.0, 68.0)/256.0
#define green vec3(0.0, 255.0, 0.0)/256.0
#define blue vec3(.0, 74.0, 255.0)/256.0
#define white vec3(255., 255., 255.0)/256.0

vec3 circle_crown(
    vec2 uv, 
    vec2 position, 
    vec3 circles_color
) {
    return circles_color*(
        smoothstep(1.0, 0.5, distance(position,uv*(2.*length(fract(-uv*2.0)-0.5)-length(fract(uv*20.0)-0.5))*2.0))+
        smoothstep(1.0, 0.5, distance(position,uv-(2.*length(fract(uv*5.0)-0.5))*2.0))+
        smoothstep(1.0, 0.5, distance(position,uv+(2.*length(fract(uv*10.0)-0.5))*2.0))+
        smoothstep(1.0, 0.5, distance(position,uv*(2.*length(fract(-uv*20.0)-0.5)-length(fract(uv*5.0)-0.5))*2.0))
    );
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x, resolution.y);
    uv=uv+vec2(cos(time/3.),sin(time/5.0));
    uv=uv*rotate2d(time/5.0);
    uv=uv*(sin(time/3.0)*0.5+1.0);

    vec3 color=vec3(0);

    color+=circle_crown(
        uv, 
        vec2(cos(time*2./5.), sin(time*3./7.)), 
        yellow
    );

    color+=circle_crown(
        uv, 
        vec2(cos(time*4./5.), sin(time*3./7.)), 
        red
    );
    color+=circle_crown(
        uv, 
        vec2(cos(time*5./5.), sin(time*7./7.)), 
        blue
    );
    
    glFragColor = vec4(color, 1.0);
}
