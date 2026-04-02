#version 420

// original https://www.shadertoy.com/view/ws2fDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define s(x) sin(x)
#define p 3.14
#define r(x) mat2(cos(x),-s(x),s(x),cos(x))
#define R resolution.y
#define T sin((sin(time*0.9)*2.5+49.)*0.1)+4.

float x;

void main(void){
 vec2 v =(gl_FragCoord.xy)/R;  
 v.x = abs(v.x-0.85);
 for(int i=0;i<35;++i) { v = fract(v*r(T*.1)* 1.099)+.3; 
            v=        (v*r(-T*.0314*p)* 1.);

            v=        (v*r(-T*.01*p)* 1.);   
                            //                    v+=vec2(.5,-0.2);
           v=        (v*r(T*.0314)* 1.0); 
                                                v+=vec2(.5,-0.2);
                         v.y = abs(v.y-0.);

           v=        (v*r(T*.0314)* 1.0);      

x-=v.x;} 
 glFragColor = vec4(s(T*1.+x), s(T*2.+x),s(T*3.+x),1.)*.5+.5;
}
