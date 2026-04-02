#version 420

// original https://www.shadertoy.com/view/3ljyWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Data {
    float interval;
    vec3 pos0, pos1, dir0, dir1;
    float grad, weight;
};
    
//const Data Z = Data(0.,vec3(0),vec3(0),vec3(0),vec3(0),0.,0.);
Data data[] = Data[]( 
    Data(8., vec3(2.3,3,1), vec3(1.5,2.5,2),vec3(1,0,1), vec3(1,1,0),  .2, .4),
    Data(9., vec3(0,1,2),   vec3(0,0,2),    vec3(0,1,1), vec3(1,1,1),  2., .3),
    Data(8., vec3(0,0,1),   vec3(0,0,3),    vec3(1,0,1), vec3(1,1,1), -3., .4),
    Data(8., vec3(0,1,1.7), vec3(1,0,1.7),  vec3(1,1,0), vec3(0,1,1),  0., .4),
    Data(7., vec3(2,2,1),   vec3(2,2.5,0),  vec3(1,0,1), vec3(1,1,0),  3., .3),
    Data(9., vec3(-2,1,1.5),vec3(-2,1.5,0), vec3(0,0,1), vec3(1,0,1),  1., .4)
);

#define fold45(p)(p.y>p.x)?p.yx:p
float map(vec3 p)
{
    float scale = 2.1,
           off0 = 0.8,
           off1 = 0.3,
           off2 = 0.83;
    vec3 off = vec3(2.,.2,.1);
    float s = 1.0;
    for(int i = 0;++i<20;)
    {
        p.xy = abs(p.xy);
        p.xy = fold45(p.xy);
        p.y -= off0;
        p.y =- abs(p.y);
        p.y += off0;
        p.x += off1;
        p.xz = fold45(p.xz);
        p.x -= off2;
        p.xz = fold45(p.xz);
        p.x += off1;
        p -= off;
        p *= scale;
        p += off;
        s *= scale;
    }
    return length(p)/s;
}

void main(void)
{
    int idx, size = data.length();
    float sam = 0.;
    for(int i=0; i<size; i++) sam += data[i].interval;
    float time = mod(time,sam);
    sam = 0.;
    for(idx=0; idx<size && time>sam; idx++)
        sam += data[idx].interval;
    Data P = data[idx-1];
    float t = (time-sam)/P.interval;
    vec2  R = resolution.xy,
         uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 ro = mix(P.pos0, P.pos1, t),
         up = vec3(sin(P.grad),cos(P.grad),0),
          w = normalize(mix(P.dir0, P.dir1, t)),
          u = normalize(cross(w,up)),
         rd = mat3(u,cross(u,w),w)*normalize(vec3(uv,2));

    float h = 0.0, d, i;
    vec3 p;
    for(i=0.; i<160.; i++)
    {
        p = ro+rd*h;
        p *= P.weight;
        d = map(p);
        if(d < 0.001 || t > 20.) break;
        h += d;
    }
    glFragColor.xyz = 20.*vec3(cos(p*1.2)*.5+.5)/i;
}
