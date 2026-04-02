#version 420

// original https://www.shadertoy.com/view/3tByDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Data {
    float interval;
    vec3 pos0, pos1, dir0, dir1;
    float up;
};

Data data[] = Data[]( 
    Data(9., vec3(.3,1,-1), vec3(0,.5,0),  vec3(1,0,1), vec3(0,1,1),  0.),
    Data(8., vec3(0,.3,.6),   vec3(0,0,.6),   vec3(0,1,1), vec3(1,1,1),  2.),
    Data(8., vec3(0,0,.4),    vec3(0,0,1.2),  vec3(1,0,-1), vec3(1,1,1), -3.),
    Data(8., vec3(-.8,.4,.6), vec3(-.5,.6,0), vec3(0,0,1), vec3(1,0,1),  1.),
    Data(8., vec3(0,.4,.7),   vec3(.4,0,.7),  vec3(1,-1,0), vec3(0,1,1),  2.),
    Data(7., vec3(.8,.6,.3),  vec3(.2,-.8,0),  vec3(1,0,1), vec3(0,1,1),  3.)
);

#define PI acos(-1.)
#define TAU PI*2.
#define PIH PI*.5
#define pmod(p,n)length(p)*sin(vec2(0.,PIH)+mod(atan(p.y,p.x),TAU/n)-PI/n)
#define fold(p,v)p-2.*min(0.,dot(p,v))*v;

float map(vec3 p)
{
    p.z=fract(p.z)-.5;
    float s = 1.0;
    for(int i=0; i<20; i++)
    {
        p.y += .15;
        p.xz = abs(p.xz);
        for(int j=0;j<2;j++)
        {
            p.xy = pmod(p.xy,8.);
            p.y -= .18;
        }
        p.xy = fold(p.xy,normalize(vec2(1,-.8)));
        p.y = -abs(p.y);
        p.y += .4;
        p.yz = fold(p.yz,normalize(vec2(3,-1)));
        p.x -= .47;
        p.yz = fold(p.yz,normalize(vec2(2,-7)));
        p -= vec3(1.7,.4,0);
        float scale = 3.58/dot(p,p);
        p *= scale;
        p += vec3(1.8,.7,.0);
        s *= scale;
    }
    return length(p)/s;
}

void main(void)
{
    int idx, size = data.length();
    float t0,sam = 0.;
    for(int i=0; i<size; i++) sam += data[i].interval;
    float time = mod(time,sam);
    sam = 0.;
    for(idx=0; idx<size && time>sam; idx++)
        sam += data[idx].interval;
    Data P = data[idx-1];
    float t = (time-sam+P.interval)/P.interval;
    const float zoom = 3.;
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro = mix(P.pos0, P.pos1, t)*zoom,
          w = normalize(mix(P.dir0, P.dir1, t)),
          u = normalize(cross(w,vec3(sin(P.up),cos(P.up),0))),
         rd = mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    float h = 0.0,d,i;
    vec3 p;
    for(i=1.;i<100.;i++)
    {
        p = ro+rd*h;
        p /= zoom;
        d = map(p);
        if(d<0.001 || h>12.) break;
        h += d;
    }
    glFragColor.xyz=pow(30.*vec3(cos(p*1.5)*.5+.5)/i,vec3(1.5,3,3));
}
