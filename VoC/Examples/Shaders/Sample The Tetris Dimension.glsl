#version 420

// original https://www.shadertoy.com/view/NtByzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
vec2 uv;
vec3 cp,cn,cr,ro,rd,ss,oc,cc,gl,vb;
vec4 fc;
float tt,cd,sd,io,oa,td,tc;
int es=0,ec;

float bx(vec3 p,vec3 s){vec3 q=abs(p)-s;return min(max(q.x,max(q.y,q.z)),0.)+length(max(q,0.));}

vec3 minoc(int num)
{
    num=int(mod(float(num),7.));
    vec3 c;switch(num){
    case 0:c=vec3(0.7,0,0);break;
    case 1:c=vec3(0,0.7,0);break;
    case 2:c=vec3(0.8,0.7,0.1);break;
    case 3:c=vec3(0.5,0.2,0.8);break;
    case 4:c=vec3(0.1,0.7,0.8);break;
    case 5:c=vec3(0,0.2,0.7);break;
    case 6:c=vec3(0.9,0.5,0);break;}
    return c;
}

float mino(int num, vec3 p, float s)
{
    num=int(mod(float(num),7.));
    vec2 o2,o3,o4;switch(num){case 2:o2=vec2(1,-1);
    o4=vec2(-0.5,0.5);break;case 3:o4=vec2(0,0.5);break;
    case 4:o3=vec2(-2,0);o4=vec2(0.5,0);break;}
    if(num>2)o2=vec2(-1,0);if(num<4)o3=vec2(0,1-sign(num)*2);
    if(num>4){o3=vec2(sign(float(num)-5.5),-1);o4=vec2(0,0.5);}
    if(num<2){o2=vec2(-1,-sign(float(num)-0.5));o4=vec2(0,sign(float(num)-0.5)*0.5);}
    p.xy+=o4*s;vec3 dp=p;float hs=s/2.;float d=bx(dp, vec3(hs));
    dp.xy+=vec2(1,0)*s;d=min(d,bx(dp,vec3(hs)));dp=p;
    dp.xy+=o2*s;d=min(d,bx(dp,vec3(hs)));dp=p;
    dp.xy+=o3*s;d=min(d,bx(dp,vec3(hs)));dp=p;
    return d;
}

float hash(vec2 p)
{
    p=fract(p)-cos(p);
    vec2 q=tan(abs(p*37482.34)+p.yx*678324.);
    return fract(q.x+p.x*q.y-p.y);
}

float mp(vec3 p)
{
        vec3 pp=p;
        p.y+=tt;
        p.z-=20.;float yid=trunc(p.y/16.+8.);
        p.y=mod(p.y,16.)-8.;
        p.xz*=rot(tt*0.3+yid);
        p.xy*=rot(tt*0.1);
        int mn=int(tt+yid*2.);
        float mm=pow(mod(tt,1.),5.);
        float ms=3.;
        float mno=mino(mn,p,ms)-0.05;
        mno=mix(mno,mino(mn+1,p,ms)-0.05,mm);
        vec3 mc=mix(minoc(mn),minoc(mn+1),mm);
        if(mno>0.03)gl+=exp(-mno)*mc*1.4;
        p=pp;p.z+=tt*1.5;
        vec3 cellID = trunc(p/2.+0.5);
        vec3 id=vec3(hash(cellID.xx+cellID.yz),hash(cellID.yz),hash(cellID.zy))*vec3(1,0.6,1);
        if(length(id) < 1.15) id = vec3(0.);
        else id = normalize(id);
        if(isnan(id.x))id=vec3(0); //this is a stupid fix but whatever
        p.yz=mod(p.yz-1.,2.)-1.;
        p.x=abs(p.x)-28.;
        float wls = bx(p,vec3(0.7))-0.05;
        if(sd>0.01) gl += exp(-wls*0.1) * id*0.5;
        sd=min(mno,wls);
        sd=abs(sd)-0.001;
        if(sd<0.001)
        {    
            io=mno<wls?1.1:1.05;
            oc=mno<wls?mc:id;
            oa=length(id)<0.5?0.:0.1;
            ss=vec3(1.);
          vb=vec3(0.);
            ec=2;    
        }
        return sd;
}

void tr(){vb.x=0.;cd=0.;for(tc=1.;tc<512.;tc++){mp(ro+rd*cd);cd+=sd;td+=sd;if(sd<0.0001||cd>80.)break;}}
void nm(){mat3 k=mat3(cp,cp,cp)-mat3(.001);cn=normalize(mp(cp)-vec3(mp(k[0]),mp(k[1]),mp(k[2])));}

void px()
{
  cc=vec3(0.,0.,0.)+length(pow(abs(rd+vec3(0,0.5,0)),vec3(3)))*vec3(0.1,0.,0.2)+gl/tc;
  vec3 l=vec3(0.5,0.5,0.8);
  if(cd>80.){oa=1.;return;}
  float df=clamp(length(cn*l),0.,1.);
  vec3 fr=pow(1.-df,3.)*mix(cc,vec3(0.4),0.5);
    float sp=(1.-length(cross(cr,cn*l)))*0.2;
    float ao=min(mp(cp+cn*0.3)-0.3,0.3)*0.5;
  cc=mix((oc*(df+fr+ss)+fr+sp+ao+gl/tc),oc,vb.x);
}

void render(vec2 frag, vec2 res, float time, out vec4 col)
{
    
  uv=vec2(frag.x/res.x,frag.y/res.y);
  uv-=0.5;uv/=vec2(res.y/res.x,1);
  ro=vec3(0,0,-15);rd=normalize(vec3(uv,1));
    tt=mod(time, 100.);
  
    for(int i=0;i<25;i++)
  {
        tr();cp=ro+rd*cd;nm();ro=cp-cn*(io<0.?-0.01:0.01);
        cr=refract(rd,cn,i%2==0?1./io:io);i=io<0.?i+1:i;
    if((length(cr)==0.&&es<=0)||io<0.){cr=reflect(rd,cn);es=(io<0.?es:ec);}
    if(max(es,0)%3==0&&cd<128.)rd=cr;es--;
        if(vb.x>0.&&i%2==1)oa=pow(clamp(cd/vb.y,0.,1.),vb.z);
        px();fc=fc+vec4(cc*oa,oa)*(1.-fc.a);if((fc.a>=1.||cd>80.))break;
  }
  col = pow(fc/fc.a,vec4(0.8));
}

void main(void)
{
    render(gl_FragCoord.xy,resolution.xy,time,glFragColor);
}
