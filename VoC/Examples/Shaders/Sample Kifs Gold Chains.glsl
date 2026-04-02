#version 420

// original https://www.shadertoy.com/view/7ll3WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 ep=vec2(0.003,-0.003);
float ti,b,f;
float em;
float bo(vec3 p, vec3 b){p=abs(p)-b;return max(p.x,max(p.y,p.z));}
mat2 rt(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
vec2 sdf(vec3 p)
{
    vec3 yp,xp,zp;
    vec2 h,r=vec2(bo(abs(p),vec3(1)),1);
    yp=xp=zp=p;
  f=1.0;
    float a=.1, of=.25, w=6.*f;
    vec2 we= vec2(w,.1);
    xp.yz*=rt(abs(xp.x));
    h=vec2(bo(abs(xp)-vec3(of+a*abs(p.x)),we.xyy),3);    
    yp.xz*=rt(abs(yp.y));     
    h.x=min(bo(abs(yp)-vec3(of+a*abs(p.y)),we.yxy),h.x);
    zp.xy*=rt(abs(zp.z));  
    h.x=min(bo(abs(zp)-vec3(of+a*abs(p.z)),we.yyx),h.x);
    r=r.x<h.x?r:h;
  b=1.0;
    float bi = 1.+b;
    h=vec2(bo(abs(p)-vec3(0,bi,bi),vec3(.5,.0,.0)),2);
    p.xy*=rt(1.59);
    h.x=min(bo(abs(p)-vec3(0,bi,bi),vec3(.5,.0,.0)),h.x);
    p.xz*=rt(1.59);
    h.x=min(bo(abs(p)-vec3(0,bi,bi),vec3(.5,.0,.0)),h.x);  
    em+=0.002/(0.1+h.x*h.x);
    r=r.x<h.x?r:h;
    r.x*=.5;
    return r;
}

vec2 mp(vec3 p)
{
  p.xz*=rt(.5*ti);
  p.xy*=rt(.89*ti);
  vec3 np=p;
  //f = texture(texFFTSmoothed,1).r*400;
  //b = clamp(texture(texFFTSmoothed,0).r*800,0,3);
  for(int i=0; i<3; i++){
    np=abs(np)-vec3(pow(1.8,2.));
    //float t = clamp(100000/fGlobalTime,0,1);
    //np.zx*=r2(-ti*.1*t);
    //np.yz*=r2(sin(-ti*.1*t));
    //np.xy*=r2(sin(-ti)*.1*t);
  }
  return sdf(np);
}

vec2 rm(vec3 ro, vec3 rd)
{
  float tn=.001,tx=75.;
  vec2 h,d=vec2(tn,0);
  for(;d.x<tx;d.x+=h.x)
  {
      h=mp(ro+rd*d.x);
      if(h.x<.0001)break;
      d.y=h.y;
  }
  if(d.x>tx)d.x=0.;
  return d;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    ti=mod(time,100.);
    vec3 co=vec3(0,0,-15),
    cd=normalize(vec3(uv,1.5)),fo,cl=fo=vec3(.2,.5,1)+cd.y*vec3(0,.5,0);
    vec2 r=rm(co, cd);
    float d=r.x;
    if(d>0.)
    {
        vec3 p=co+cd*d, no=normalize(ep.xyy*mp(p+ep.xyy).x+
        ep.xyx*mp(p+ep.xyx).x+
        ep.xxy*mp(p+ep.xxy).x+
        ep.xxx*mp(p+ep.xxx).x),
        l=normalize(vec3(-1,-.5,1)),
        al=vec3(1.);
        if(r.y>0.)al=vec3(.1,.2,1.);
        if(r.y>1.)
        {
            float at = clamp(1.-(length(p)-7.),0.,1.);
            al=vec3(1.-at,1.-at,.4*at);
        }
        float dif=max(dot(no,-l),0.),r=40./d, ao = exp2(pow(max(0.,1.-mp(p+no*r).x)/r,2.));
        float spec=pow(max(0., dot(no, normalize(-l-cd))), 100.),
        sss=smoothstep(0., 1., mp(p+l*.4).x/.4);
        cl=spec+al*(.3*ao)*(dif+sss);
    }
    cl=mix(cl+em*vec3(.5,b,(.4*b)), fo, 1.-exp(-.0001*d*d*d));
    glFragColor=vec4(pow(cl,vec3(.45)),1);
}
