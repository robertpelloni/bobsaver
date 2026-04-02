#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = (surfacePos+vec2(0.,-0.0))*11.4;
    
    float a = atan(p.x,p.y+1.);
    float r = length(p);
    float c = sin(time/1.-r*2.-cos(a*13.0*sin(r*r/15.14+time/7.)));
    c *=cos(r*0.9);
    glFragColor = vec4(c*c*0.55,c*0.75,-c*.6,1.0)*1.2;

}
