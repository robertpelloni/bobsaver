#version 420

// original https://www.shadertoy.com/view/llsSDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash2a(vec2 x,float anim)
{
    float r = 523.0*sin(dot(x, vec2(53.3158, 43.6143)));
    float xa1=fract(anim);
    float xb1=anim-xa1;
    anim+=0.5;
    float xa2=fract(anim);
    float xb2=anim-xa2;
    
    vec2 z1=vec2(fract(15.32354 * (r+xb1)), fract(17.25865 * (r+xb1)));
    r=r+1.0;
    vec2 z2=vec2(fract(15.32354 * (r+xb1)), fract(17.25865 * (r+xb1)));
    r=r+1.0;
    vec2 z3=vec2(fract(15.32354 * (r+xb2)), fract(17.25865 * (r+xb2)));
    r=r+1.0;
    vec2 z4=vec2(fract(15.32354 * (r+xb2)), fract(17.25865 * (r+xb2)));
    return (mix(z1,z2,xa1)+mix(z3,z4,xa2))*0.5;
}

float hashNull(vec2 x)
{
    float r = fract(523.0*sin(dot(x, vec2(53.3158, 43.6143))));
    return r;
}

vec4 NC0=vec4(0.0,157.0,113.0,270.0);
vec4 NC1=vec4(1.0,158.0,114.0,271.0);

vec4 hash4( vec4 n ) { return fract(sin(n)*753.5453123); }
vec2 hash2( vec2 n ) { return fract(sin(n)*753.5453123); }
float noise2( vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + p.y*157.0;
    vec2 s1=mix(hash2(vec2(n)+NC0.xy),hash2(vec2(n)+NC1.xy),vec2(f.x));
    return mix(s1.x,s1.y,f.y);
}

float noise3( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + dot(p.yz,vec2(157.0,113.0));
    vec4 s1=mix(hash4(vec4(n)+NC0),hash4(vec4(n)+NC1),vec4(f.x));
    return mix(mix(s1.x,s1.y,f.y),mix(s1.z,s1.w,f.y),f.z);
}

vec4 booble(vec2 te,float numCells)
{
    float d=dot(te, te);
    //if (d>=0.06) return vec4(0.0);

    vec2 te2=-te;
    float zb1=max(pow(noise2(te2*1000.11*d),10.0),0.01);
    float zb2=noise2(te*1000.11*d);
    float zb3=noise2(te*200.11*d);
    float zb4=noise2(te*200.11*d+vec2(20.0));
    
    vec4 colorb=vec4(1.0);
    colorb.xyz=colorb.xyz*(0.7+noise2(te*1000.11*d)*0.3);
    
    zb2=max(pow(zb2,20.1),0.01);
    colorb.xyz=colorb.xyz*(zb2*1.9);
    
    vec4 color=vec4(noise2(te2*10.8),noise2(te2*9.5+vec2(15.0,15.0)),noise2(te2*11.2+vec2(12.0,12.0)),1.0);
    color=mix(color,vec4(1.0),noise2(te2*20.5+vec2(200.0,200.0)));
    color.xyz=color.xyz*(0.7+noise2(te2*1000.11*d)*0.3);
    color.xyz=color.xyz*(0.2+zb1*1.9);
    
    float r1=max(min((0.033-min(0.04,d))*100.0/sqrt(numCells),1.0),-1.6);
    float d2=(0.06-min(0.06,d))*10.0;
    d=(0.04-min(0.04,d))*10.0;
    color.xyz=color.xyz+colorb.xyz*d*1.5;
    
    float f1=min(d*10.0,0.5-d)*2.2;
    f1=pow(f1,4.0);
    float f2=min(min(d*4.1,0.9-d)*2.0*r1,1.0);

    float f3=min(d2*2.0,0.7-d2)*2.2;
    f3=pow(f3,4.0);
    
    return vec4(color*max(min(f1+f2,1.0),-0.5)+vec4(zb3)*f3-vec4(zb4)*(f2*0.5+f1)*0.5);
}

vec4 Cells(vec2 p, in float numCells,in float count,float blur)
{
    p *= numCells;
    float d = 1.0;
    vec2 te;
    for (int xo = -1; xo <= 1; xo++)
    {
        for (int yo = -1; yo <= 1; yo++)
        {
            vec2 tp = floor(p) + vec2(xo, yo);
            vec2 rr=mod(tp, numCells);
            tp = p - tp - (hash2a(rr,time*0.1)+hash2a(rr,time*0.1+0.25))*0.5;
            float dr=dot(tp, tp);
            if (hashNull(rr)>count)
                if (d>dr) {
                    d = dr;
                    te=tp;
                }
        }
    }
    if (d>=0.06) return vec4(0.0);
    
    //te=te+(te*noise3(vec3(te*5.9,time*40.0))*0.02);
    //te=te+(te*(noise3(vec3(te*3.9+p,time*0.2))+noise3(vec3(te*3.9+p,time*0.2+0.25))+noise3(vec3(te*3.9+p,time*0.2+0.5))+noise3(vec3(te*3.9+p,time*0.2+0.75)))*0.05);
         
    if (blur>0.0001) {
        vec4 c=vec4(0.0);
        for (float x=-1.0;x<1.0;x+=0.5) {
            for (float y=-1.0;y<1.0;y+=0.5) {
                c+=booble(te+vec2(x,y)*blur,numCells);
            }
        }
        return c*0.05;
    }
    
    return booble(te,numCells);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy) / resolution.y*0.5;
    
    vec2 l1=vec2(time*0.02,time*0.02);
    vec2 l2=vec2(-time*0.01,time*0.007);
    vec2 l3=vec2(0.0,time*0.01);
    
    //vec4 e=vec4(noise2(uv*2.0),noise2(uv*2.0+vec2(200.0)),noise2(uv*2.0+vec2(50.0)),0.0);
    vec4 e=vec4(noise3(vec3(uv*2.0,time*0.1)),noise3(vec3(uv*2.0+vec2(200.0),time*0.1)),noise3(vec3(uv*2.0+vec2(50.0),time*0.1)),0.0);
    vec4 cr;
    
    cr=Cells(uv+vec2(10.3245,233.645)+l3,14.2,0.95,0.05);
    e=max(e-vec4(dot(cr,cr))*0.1,0.0)+cr*1.6;

    cr=Cells(uv+vec2(10.3245,233.645)+l3,9.2,0.9,0.02);
    e=max(e-vec4(dot(cr,cr))*0.1,0.0)+cr*1.6;
    
    cr=Cells(uv+vec2(200.19,393.2)+l3,7.0,0.8,0.01);
    e=max(e-vec4(dot(cr,cr))*0.1,0.0)+cr*1.3;
    cr=Cells(uv+vec2(230.79,193.2)+l2,4.0,0.5,0.0);
    e=max(e-vec4(dot(cr,cr))*0.1,0.0)+cr*1.1;
    cr=Cells(uv,3.0,0.5,0.003);
    e=max(e-vec4(dot(cr,cr))*0.1,0.0)+cr*1.4;
    
    cr=Cells(uv+vec2(20.2449,93.78)+l1,2.0,0.5,0.005);
    e=max(e-vec4(dot(cr,cr))*0.1,0.0)+cr*1.8;
    
    //e=e*(3.0+sin(time*10.0)*0.4+sin(time*5.0)*0.5+sin(time*100.0)*0.05 )*0.25;
    
    glFragColor= e;
}
