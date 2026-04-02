#version 420

///////////////////////////////////////////////////////////// 
// Game Engine 2d (OpenGL / GLSL / Box2d / C++) + download///
// See more https://www.youtube.com/watch?v=JhEREu9-t-c   ///
/////////////////////////////////////////////////////////////

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D mySampler;

vec2 t;

float ti;
float col=1e3,col2=1e3,col3=1e3;

float hash(float n)
{
    return fract(sin(n)*43758.5453);
}

float noise(vec2 p)
{
    return hash(p.x + p.y*57.0);
}

float valnoise(vec2 p)
{
    vec2 c=floor(p);
    vec2 f=smoothstep(0.,1.,fract(p));
    return mix (mix(noise(c+vec2(0,0)), noise(c+vec2(1,0)), f.x),
                mix(noise(c+vec2(0,1)), noise(c+vec2(1,1)), f.x), f.y);
}

float f(vec3 p)
{    
    // 
    vec3 _p = p;
    float W = 1.;
    p.x = mod(p.x+W/2., W)-W/2.;
    p.z += fract(max(0., _p.x-p.x)/1.7)*5.;
    W = 3.;
    p.z = mod(p.z+W/2., W)-W/2.;

    // ground-floor
    col3=p.y-(.5+.5*cos(p.x*2.))*.1;

    float d=max(col3,length(p.xz)-5.5);
    float s=1.,ss=1.6;
    
    // Tangent vectors for the branch local coordinate system.
    vec3 w=normalize(vec3(-.8+cos(time/5.87+100.1*(_p.x-p.x))*.125,1.2+sin(time/4.43+100.1*(_p.x-p.x))*.125,-1.));
    vec3 u=normalize(cross(w,vec3(0,1,0)));

    int j = int(min(floor(ti-1.),7.));

    float scale=min(.3+ti/6.,1.);
    p/=scale;

    

    for (int i = 0; i < 10; ++i)   
    {
    
    d=min(d,scale*max(p.y-1.,max(-p.y,length(p.xz)-.1/(p.y+.7)))/s);
        
        p.xz=abs(p.xz);
        
    p.y-=1.;
    p*=mat3(u,normalize(cross(u,w)),w);
        p*=ss;
        s*=ss;
    }

    return min(d,col=max(0.,length(p)-.25)/s);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    t=(uv*2.-1.)*.5;
    t.x*=resolution.x/resolution.y;

    float times=140.;

    // Timing value used in the original demo.
    ti=max(0.,times)/3.;
    ti=noise(floor(gl_FragCoord.xy))+(floor(ti)+clamp(fract(ti)*2.,0.,1.));
    ti=floor(ti);

    float zoom=1.5;
    vec2 filmoffset=vec2(0);

    // Set up camera and primary ray.
    vec3 ro=vec3(-2.5+cos(time/4.),.1+cos(ti*17.)*.1+.8+0.8*cos(time/11.11),3.5);
    vec3 rd=normalize(vec3(t.xy+filmoffset,zoom));
    if(ti==10.)ro.y+=2.;
    vec3 camtarget=vec3(0,1.3,0);

    vec3 w=normalize(camtarget-ro);
    vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 v=normalize(cross(w,-u));

    rd=mat3(u,v,w)*rd;

    glFragColor.rgb=vec3(.8,.8,1.)/6.;
    float s=20.;

    // Signed distance field raymarch.
    float t=0.,d=0.;
    for(int i=0;i<100;++i)
    {
        d=f(ro+rd*t);
        if(d<1e-3)break;
        t+=d;
        if(t>10.)return;
    }

    // Colourise ground, branch/trunk, or cherry blossom.
    {
        vec3 rp=ro+rd*t;
        glFragColor.rgb=vec3(.75,.6,.4)/1.5;
        if(col<2e-3)glFragColor.rgb=vec3(1.,.7,.8);
        if(col3<2e-2&&(ti<17.||ti>22.))glFragColor.rgb=vec3(.5,1.,.6)/3.;
    }

    // Lighting.
    vec3 ld=normalize(vec3(1.,3.+cos(ti)/2.,1.+sin(ti*3.)/2.));
    float e=1e-2;
    float d2=f(ro+rd*t+ld*e);
    float l=max(0.,(d2-d)/e);

    float d3=f(ro+rd*t+vec3(0,1,0)*e);
    float l2=max(0.,.5+.5*(d3-d)/e);

    {
        vec3 rp=ro+rd*t;
        if(ti>12.&&ti<22.)
            if(col2<1e-2||d3+d2/7.>0.0017 && pow(valnoise(rp.xz*8.),2.)>abs(ti-18.)/5.) glFragColor.rgb=vec3(0.65);
    }

    {
        vec3 rp=ro+rd*t;
        if(ti>12.&&ti<17.)
            if(col2<1e-2||d3+d2/7.>0.0017 && valnoise(rp.xz*8.)<(ti-12.)/3.)glFragColor.rgb=vec3(.65);
    }

    vec3 rp=ro+rd*(t-1e-3);

    // Directional shadow.
    t=0.1;
    float sh=1.;
    for(int i=0;i<30;++i)
    {
        d=f(rp+ld*t)+.01;
        sh=min(sh,d*50.+0.3);
        if(d<1e-4)break;
        t+=d;
    }

    glFragColor.rgb*=1.*sh*(.2+.8*l)*vec3(1.,1.,.9)*.7+l2*vec3(.85,.85,1.)*.4;
    glFragColor.rgb=clamp(glFragColor.rgb,0.,1.);
}
