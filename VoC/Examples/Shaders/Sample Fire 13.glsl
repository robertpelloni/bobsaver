#version 420

// original https://www.shadertoy.com/view/7tVBW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Forget Gas heating, invest into GPU Heating !

*/
vec3 erot(vec3 p,vec3 ax,float t){return mix(dot(ax,p)*ax,p,cos(t))+cross(ax,p)*sin(t);}
void main(void)
{
     vec2 uv = (gl_FragCoord.xy -.5* resolution.xy)/resolution.y;
    
    vec3 col = vec3(0.);
    
    
    vec3 p,d=normalize(vec3(uv,1.));
    
    for(float i=0.,e=0.,g=0.;i++<99.;){
        p = d*g;
        vec3 op=p;
        p.z -=15.+sin(time);
        
        float v=0.3,qq=0.;
        for(v=.3;v<50.;op=erot(op,vec3(0.,1.,0.),v+=v)){
                 // ^-- Thermostat, increase to make GPU hotter
            qq+=abs(dot((sin(op*v)),vec3(.2)/v));           
           op = erot(op,normalize(vec3(-.5,.7,2.7)),time*.1+.741);
        }
        float h = length(p)-1.-qq;;
        h = max((abs(p.y)-5.1),abs(qq)-.5);
        g+=e=max(.01,abs(h));
        col += vec3(1.)*.0255/exp(e*e*i);
    }
    col =mix(vec3(.2,.05,.01),vec3(.95,.4,.1),col*col);
    glFragColor = vec4(mix(col,sqrt(col),.5),1.0);
                          // ^-- this is the a color normalization technics
                          // based on a new scientific approach 
                          // developed at the International Institute of La RACHE
                          // https://www.la-rache.com/
                          // Scientific paper will come soon
                          
}
