#version 420

// original https://www.shadertoy.com/view/MtccW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Benoit Marini - 15/08/2018
// SIGGRAPH Logo I
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define E(p,d) step(dot(f=(z+p)/d,f),1.) //ellipse center p, size d
#define V vec2

void main(void) //WARNING - variables void ( out vec4 o,in V f ) need changing to glFragColor and gl_FragCoord
{   
    vec2 f = gl_FragCoord.xy;
    vec4 o = glFragColor;
    V z = (f/resolution.y-.5)*mat2(1,.7,-.7,1),
    //  SIGGRAPH ellipse
    a=V(0,.04), b=V(.45,.145), c=V(.08,.015), d=V(.39,.14) ;
    // SIGGRAPH shape 
    float S = 2.*E(.0,.5)-1.
        - max ( E(.0,.46)-E(.0, V(.52,.22)) ,0.) 
        - max ( E(-a,b)-E(-c,d) , E(a,b)-E(c,d)) ,
    t=time*.25,
    u=floor(t),
    v=t-u,
    q=5.*u+t/8e1;
 
    // procedural col    
    o = vec4 (z*5e2,5,5);    
    for (int i=0; i++<92;) o.xzyw = abs( o/dot(o,o)- vec4(.7+.2*cos(q),.2+.2*sin(q*1.9),0,0)); 
    
    o*=pow(v,.3);
    //output  v       
    o=(S <.0)? o-o : S*o-o+1.;
    o=pow(o,vec4(2,4,3,1));
    
    glFragColor = o;
}
