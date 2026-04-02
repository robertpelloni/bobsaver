#version 420

// original https://www.shadertoy.com/view/tdGSR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 3

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec4 fractal(vec2 U) {
    float m=1e3,t=time;
    U*=.13-sin(t*.2)*.1;
    U*=rot(sin(t*.1)*3.14);
    U+=vec2(sin(t),cos(t))*.005*sin(t*.2);
    vec4 p=vec4(cos(U.x),sin(U.x),cos(U.y),sin(U.y));
    for (int i=0;i<8;i++) {
        p=abs(p+1.)-abs(p-1.)-p;
        p=p*1.5/min(1.,dot(p,p))-1.;
        m=min(m,fract( length(p*2.) -t*.1 ) );
    }
    return m*m*normalize(2.+abs(p.xyww))*2.;
}

void main(void)
{
    vec4 O;
    vec2 u = gl_FragCoord.xy;

    vec2 R=resolution.xy,
         U=(u-R*.5)/R.y;
    U*=1.-dot(U,U)/4.;
    O=vec4(0);
    vec2 pix=1./R/float(AA)+max(0.,2.-time)*.005;
    for (int x=-AA;x<AA;x++) 
        for (int y=-AA;y<AA;y++)
            O+=fractal(U+vec2(x,y)*pix);

    O/=float(AA*AA);

    glFragColor = O;
}
