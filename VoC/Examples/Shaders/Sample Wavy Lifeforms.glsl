#version 420

// original https://www.shadertoy.com/view/Wl3cDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
vec2 c=(40.*clamp(sin(time/2.),0.,.5)+2.)*(gl_FragCoord.xy-resolution.xy/2.)/max(resolution.x,resolution.y);
vec2 i=2.*floor((c+1.)/2.);
c-=i;
float o=atan(c.y,c.x);
float t=.25+abs(cos(time+o/2.+i.x+i.y))*(sin((10.+i.x-i.y)*o)+.75)/10.;
glFragColor=sqrt(vec4((1.-smoothstep(0.,.025,abs(length(c)-t)))*vec3(t,sin(o-.5),(o+3.14)/6.28),1.));
}
