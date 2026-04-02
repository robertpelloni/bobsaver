#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi=3.14159265359;

vec2 hexify(vec2 p,float hexCount){
    p*=hexCount;
    vec3 p2=floor(vec3(p.x/0.86602540378,p.y+0.57735026919*p.x,p.y-0.57735026919*p.x));
    float y=floor((p2.y+p2.z)/3.0);
    float x=floor((p2.x+(1.0-mod(y,2.0)))/2.0);
    return vec2(x,y)/hexCount;
}

void main( void ) {
    vec2 p=gl_FragCoord.xy/resolution.xy-0.5;
    float l=length(p);
    p.x*=resolution.x/resolution.y;
    p=vec2(.5/length(p)+time*37.0,fract((atan(p.y,p.x)+pi/14.0)/pi+1.5));
    p.y=2.0+7.25*abs(p.y-0.5);
    p=hexify(p,8.0);
    glFragColor = pow(l,0.45)*vec4(sin(p.x)*cos(p.y-time*sin(p.y-p.x)),sin(p.y*(1.0-p.x))+cos(sin(p.x+time*15.0)+p.x*p.y),cos(sin(p.y+time-sin(p.x))),1);
}
