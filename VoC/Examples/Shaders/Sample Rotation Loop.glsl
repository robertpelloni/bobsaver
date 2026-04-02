#version 420

// original https://www.shadertoy.com/view/tt23Ww

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BLACK_COL vec3(32,43,51)/255.
#define WHITE_COL vec3(235,241,245)/255.

#define PI2 6.2831852
#define PI 3.1415926
#define PI_2 1.5707963
#define PI_4 0.78539815

#define L 1./6.

#define SQ_38 0.6164414002968976
#define SQ_64 0.8

#define SF 1./min(resolution.x,resolution.y)
#define SS(l,s) smoothstep(SF,-SF,l-s)

mat2 rot (float a){
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca,-sa,sa,ca);
}

float triangle(vec2 uv, vec2 pos, float size){    
    uv/=size;
    uv+=vec2(.25,.25) - pos;
    
    float m = SS(0., uv.x) * SS(0., uv.y);    
    uv *= rot(-PI_2);
    uv -= vec2(.5, 0.);
    m *= SS(uv.x, uv.y);
    
    return m;        
}

float drawPhase1(float t, vec2 uv){
    float m = 0.;
    
    for(float i=0.;i<8.;i++){
        vec2 iuv = uv;
        iuv *= rot(PI2*(i+t)/8.);
        iuv-=vec2(0., (L+sqrt(.5)*L));
        iuv *= rot(PI_4 - PI_2*(.5*t + 1.5*t*t - t*t*t));
        float s = L*.5;
        m += SS(abs(iuv.x), s) * SS(abs(iuv.y), s);
    }
    
    return clamp(m, 0., 1.);
}

float drawPhase2(float t, vec2 uv){
    
    
    float s = L*.5*(2.+sqrt(2.));
    float m = step(abs(uv.x), s) * step(abs(uv.y), s);
    
    uv*=rot(PI_4);
    m += step(abs(uv.x), s) * step(abs(uv.y), s);
    
    m = min(m, 1.);
    
    uv*=rot(-PI_4);    
    
    for(float i=0.;i<4.;i++){
        vec2 iuv = uv;
        
        iuv *= rot(PI_2*i + PI_4*t);
        m -= triangle(iuv, vec2(L*SQ_38,L*SQ_38), SQ_64);
    }
    
    return clamp(m, 0., 1.);
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    
    float t = time*.5;
    
    float phaseV = fract(t);
    
    float m;
    if(phaseV < .5){
        m = drawPhase1(phaseV*2., uv);        
    } else {        
        m = drawPhase2(phaseV*2.-1., uv);
    }       
    vec3 col = mix(WHITE_COL, BLACK_COL, m);
    
    glFragColor = vec4(col,1.0);
}
