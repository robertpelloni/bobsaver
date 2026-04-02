#version 420

// original https://www.shadertoy.com/view/ltKyWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
#define DST 0.001
#define WD 1.5
#define STP 5.
#define RES 500.

float Dline(vec2 p, vec2 a, vec2 b) {
    // line drawing function from BigWings
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.1);
    return length(pa-ba*t);
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    float va = (cos(time/6.)+.5)*20.;
    float shape = 3.+(cos(time/35.)*2.);
    
    float col=0.0;
    float i=0.0;
    for(int i2=0;i2<1000;i2++)
    {
        i+=shape;
        if (i >= 100.) {break;}
        float r=va;
        float rr=120.;
        float p=va;
        float ii=i+shape;
        vec2 myA = vec2((r+rr)*cos(i)+p*cos(r+rr)*i/r,(r+rr)*sin(i)+p*sin(r+rr)*i/r);
        vec2 myB = vec2((r+rr)*cos(ii)+p*cos(r+rr)*ii/r,(r+rr)*sin(ii)+p*sin(r+rr)*ii/r);
    
        float d = Dline(uv, myA/RES, myB/RES);
            float m = S(WD/200., (WD/200.)-(0.02-(i/9000.)), d)*WD;
        col = max(m,col);    
    }
    glFragColor = vec4(vec3(col*(cos(time/15.)/2.+1.2),col*(sin(time/23.)/2.+1.2), col*(sin(time/10.)/2.+1.2)),1.0);
}
