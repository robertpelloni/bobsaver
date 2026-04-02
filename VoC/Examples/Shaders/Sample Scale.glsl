#version 420

// original https://neort.io/art/bnhqadk3p9f5erb52uk0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = acos(-1.);
const float PI2 = PI * 2.;

mat2 rot(float a)
{
    float s = sin(a),c = cos(a);
    return mat2(c,s,-s,c);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 random22(vec2 st)
{
    st =vec2(dot(st, vec2(127.1, 311.7)),
                dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec3 cellerTri(vec2 i , vec2 s)
{
    i *= s;
    i += rot(-PI/3.) * vec2(-1.,1.) * (time*0.4);
    
    float uv1 = fract(i.y);
    float id1 = floor(i.y);
    
    vec2 uv2 =i * rot(-PI/3.);
    float id2 = floor(uv2.y);
    uv2 = fract(uv2);
    vec2 uv3 = i* rot(PI/3.);
    float id3 = floor(uv3.y);
    uv3 = fract(uv3);
    
    vec2 fr = vec2(uv2.y,uv3.y);
    fr *= uv1;
    //vec2 fl = id1 - vec2(id2,id3);
    vec2 fl =  vec2(id2,id3);
    
    vec2 mp = vec2(0.);

    vec2 uv = vec2(0.6);
    float dist = 10.;
    
    for (float y = -1.; y <= 1.; y+= 1.)
    {
        if(y == 0.){continue;}
        
        for(float x = -1.; x <= 1.; x+= 0.5)
        {
            vec2 neighbor = vec2(x, y);
            vec2 pos = vec2(random22(fl+neighbor));
            pos = mix(sin(pos*6.2831 +time),vec2(1.),0.5);

            vec2 dis = neighbor + pos - fr;
            float divs = length(dis);
            if(dist > divs)
            {
                mp = pos;
               // uv = (fr + dis)/s;
                dist = divs;
            }
        }
    }
    return vec3(mp,dist);
}

vec3 tCellerNoise(vec2 i,vec2 s)
{
    i *= s;
    i += rot(PI/3.) * vec2(1.,1.) * sin(time/5.);
    float uv1 = fract(i.y);
    float id1 = floor(i.y);
    
    vec2 uv2 =i * rot(-PI/3.);
    float id2 = floor(uv2.y);
    uv2 = fract(uv2);
    vec2 uv3 = i* rot(PI/3.);
    float id3 = floor(uv3.y);
    uv3 = fract(uv3);
    
    vec2 fr = vec2(uv2.y,uv3.y);
    fr *= uv1;
    vec2 fl = abs(vec2(id2,id3))/10.;
    
    vec2 mp = vec2(0.);

    vec2 uv = vec2(0.6);
    float dist = 10.;
    
    for(float y = -1.; y <= 1.; y+= 1.)
    {
        
        if(y == 0.){continue;}
        for(float x = -1.; x <= 1.; x+= 0.5)
        {
            vec2 n = vec2(x,y);
            vec2 p = random22(n + fl);
            float dis = length(p + n - fr);
            if(dis < dist)
            {
                dist = dis;
                mp = p;
            }
        }
    }
    
    return vec3(fl,dist - length(mp));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    uv *= rot((uv.x+uv.y+time)/20.);
    uv.x += clamp(sin(time/2.),0.,0.7);
    uv.y += clamp(cos(time/4.),0.,0.8);
    vec2 size = vec2(1.,1.)*clamp(exp(cos(time/3.)+1.2),0.5,2.) *3.+ (clamp(exp(sin(time/2.)),-0.5,0.5)+0.5) * 2.+ clamp(cos(time/4.),0.,0.9)*10.;
    vec3 cc = cellerTri(uv,size);
   //cc.xy = cc.z;
   // cc *= 20.;
    
    vec3 ccc = tCellerNoise(uv,size);
    vec3 color = vec3(0.);
    
    
    ccc.xy = mix(ccc.xy , random22(ccc.xy), (cos(time/10.)+1.)/2.);
    float rate = (sin(time+8.*(ccc.x + ccc.y + cc.x + cc.y))+1.)/2. ;
    color.rg = (ccc.xy *mix(cc.xy,vec2(0.01), rate)) / max(abs(cc.z),0.01);
    color.b = ccc.z+cc.z;
    glFragColor = vec4(color, 1.0);
}
