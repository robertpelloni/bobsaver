#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main() {
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = abs(surfacePos*11.);
    
    vec2 v1 = vec2(sin(time*0.261), cos(time*0.841))*0.3;
    vec2 v2 = vec2(sin(time*0.774), cos(time*0.274))*0.5;
    
    p+= v2;
    float a = atan(p.x,p.y);
    float r = length(p);
    
    r = (sin(abs(2.*sin(1.*r-time)-(sin(time*2.4))))) - .8*abs(sin(a*4.-time*1.7)*sin(r));
    glFragColor = vec4(r,abs(r*r*cos(a*5.+time*1.13)),r*cos(a*3.-time*2.77+r+.5*3.1415926),1);
}
