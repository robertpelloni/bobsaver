#version 420

// original https://www.shadertoy.com/view/MsyyDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* Inspired by @Candycat,https://blog.csdn.net/candycat1992/article/details/44040273
* Using Polar Coordinate To Calculate Distance
* The Other Steps Stay The Same
*/
void main(void)
{
    vec2 p = (2.*gl_FragCoord.xy-resolution.xy)/min(resolution.x,resolution.y);
    p.y -= 0.45;
    
    vec2 uv = p;
    vec2 st = vec2(atan(uv.x,uv.y),length(uv));//[-pi,pi]

    //heart curve http://mathworld.wolfram.com/HeartCurve.html
    float r = .3*(2.-2.*cos(st.x)+.85*cos(st.x)*sqrt(abs(.55*sin(st.x)))/(cos(st.x)+1.4));
    
    //background color
    vec3 bCol = vec3(1.,0.8,0.7-.07*p.y)*(1.-.25*length(p));
    
    //heart color
    vec3 hCol = vec3(1.,.25*length(p),.75*length(p)*.5);
    
    ///animation
    float tt = mod(time,1.5)/1.5;
    float ss = pow(tt,.2)*.5+.5;
    //https://zh.wikipedia.org/wiki/%E9%98%BB%E5%B0%BC
    ss=1.+ss*.5*sin(tt*6.283185*3.+p.y*.5)*exp(-tt*4.);
    p*= vec2(0.5,1.5)+ss*vec2(.5,-.5);
    
    //smoothstep https://en.wikipedia.org/wiki/Smoothstep
    glFragColor = vec4(mix(bCol,hCol,smoothstep(-0.01,0.05,r-length(p))),1.);
}
