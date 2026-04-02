#version 420

// original https://www.shadertoy.com/view/MsSGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define VOYEUR_MODE

float orgy(vec2 p) {
    float pl=0., expsmo=0.;
    float t=sin(time*10.);
    float a=-.35+t*.02;
    p*=mat2(cos(a),sin(a),-sin(a),cos(a));
    p=p*.07+vec2(.728,-.565)+t*.017+vec2(0.,t*.014);
    for (int i=0; i<13; i++) {
        p.x=abs(p.x);
        p=p*2.+vec2(-2.,.85)-t*.04;
        p/=min(dot(p,p),1.06);  
        float l=length(p*p);
        expsmo+=exp(-1.2/abs(l-pl));
        pl=l;
    }
    return expsmo;
}

void main( void )
{
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    vec2 p=uv; p.x*=1.2;
    //if (iMouse.z<.1) p=floor(p*250.)/250.;
    float o=clamp(orgy(p)*.07,.3,1.); o=pow(o,1.8);
    vec3 col=vec3(o*.8,o*o*.87,o*o*o*.9);
    float hole=length(uv+vec2(.1,0.05))-.25;
    #ifdef VOYEUR_MODE 
        col*=pow(1.-max(0.,hole),80.);
    #endif
    glFragColor = vec4(col*1.2+.15, 1.0 );
}
