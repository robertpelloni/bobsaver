#version 420

// original https://www.shadertoy.com/view/sd3XD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//by danny - https://www.dwitter.net/d/24061
vec2 uv;
float x,y,z,r,d;
void main(void) {
    uv=(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    glFragColor=vec4(vec3(sin(x/(d=(r=(x=uv.x*5.*(z=sin(time)+1.5)+sin(time)*2.+2.)*x+(y=uv.y*5.*z-(sin(mod(time*3.,3.2))+sin(time)/2.))*y)>1.?0.:cos(r)/7.)+sin(time)*9.)/cos(y/d*.55-sin(time)*19.)<1.?1.:0.),1.0);
}

