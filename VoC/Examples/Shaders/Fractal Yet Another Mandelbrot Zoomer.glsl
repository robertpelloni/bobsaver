#version 420

// original https://www.shadertoy.com/view/3tSGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 Iter(vec2 ab,float zoom,vec2 trapp) {
int i;
    vec2 xy;
    vec2 xy2;
    vec2 trp;
    xy=vec2(0,0);
    xy2=vec2(0,0);
    float trap=1e30;
    float lxy;
    float t;
    for (i=0;i<1024;i++) {
       xy2=vec2(2.0*(xy.x*xy2.x-xy.y*xy2.y)+1.0,2.0*(xy.x*xy2.y+xy.y*xy2.x));
       xy=vec2(xy.x*xy.x-xy.y*xy.y+ab.x,2.0*xy.x*xy.y+ab.y);
       trp=xy-trapp;
       t=dot(trp,trp);
       if (t<trap) trap=t;
       if (length(xy)>10000.0) break;
    }
    if (i==1024) return vec4(0,0,0,0);
    lxy=length(xy);
    float dis2=2.0*zoom*(lxy/length(xy2))*log(lxy);
    dis2=clamp(dis2,0.0,1.0);
    float clr=0.1*(float(i)-((log(lxy)/log(10000.0))-1.0));
    clr=10.0*sqrt(trap);
    vec4 color=dis2*(vec4(0.5,0.5,0.5,0)+0.5*vec4(cos(clr),cos(clr*3.0),cos(clr*7.0),1.0));
    return color;
}

void main(void) {
 float zoom=1000000.0*exp(-0.1+3.5*sin(time*0.3));
 float rot=time*0.5;
 vec2 center=vec2(-0.7490,0.1006+0.0002*sin(time*0.0423));
 vec2 trap=vec2(-1.0+0.2*sin(time*4.0),-1.0+0.2*cos(time*4.0));
 vec2 xy=(gl_FragCoord.xy-(resolution.xy/2.0))/zoom;

 vec2 xy2=center+vec2(xy.x*cos(rot)-xy.y*sin(rot),xy.x*sin(rot)+xy.y*cos(rot));
 glFragColor = Iter(xy2,zoom,trap);
}
