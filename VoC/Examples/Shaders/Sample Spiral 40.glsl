#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FC gl_FragCoord
#define o glFragColor
#define r resolution
#define t time

#define rotate2D(a) mat2(cos(a),-sin(a),sin(a),cos(a))

void main( void ) {
    vec2 p;
    float i,g,d=1.;
    for(float j=0.;j<128.;j++) {
        ++i;
        if (d<=.001) break;
        p=vec2((FC.xy-.5*r)/r.y)*g+vec2(.3)*rotate2D(g*2.);
        g+=d=-(length(p)-2.+g/9.)/2.;
    }
    p=vec2(atan(p.x,p.y),g)*8.28+t*2.;
    p=abs(fract(p+vec2(0,.5*ceil(p.x)))-.5);
    o+=30./i-.5/step(.9,1.-abs(max(p.x*1.5+p.y,p.y*2.)-1.));
}
