#version 420

// original https://www.shadertoy.com/view/3s23Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//"Infinite Spinal Squid" - Shader Showdown practice session 007

// evvvvil / DESiRE demogroup

vec2 sc,e=vec2(0.00035,-.00035);float t,tt,att,su;vec3 np,pp;
float bo(vec3 p,vec3 r){vec3 q=abs(p)-r;return max(max(q.x,q.y),q.z);}

//Simple 2d rotate function, nothing to see here, move along, find the angry mother and introduce her to DMT
mat2 r2(float r) {return mat2(cos(r),sin(r),-sin(r),cos(r));}

vec2 fb( vec3 p )
{
  vec2 h,t=vec2(bo(abs(p)-vec3(2,0,0),vec3(0.3,0.3,10)),5);
  h=vec2(1000,3);
  for(int i=0;i<6;i++) {
    h.x=min(h.x,bo(abs(p)-vec3(0,0,0.5*float(i)),vec3(2,0.1,0.1)));
    h.x=min(h.x,bo(abs(p)-vec3(2,0,0.5*float(i)),vec3(0.2,0.5,0.2)));
  }
  t.x=min(t.x,0.8*(length(p-vec3(0,0,6))-1.7));
  t=(t.x<h.x)?t:h;
  t.x*=0.5;
  return t;
}
//Map function / scene / Where the geometry is made.
vec2 mp( vec3 p )
{
    p.xy*=r2(sin(p.z*.2)*.5+tt*.5);
      np=p;  
      att=length(p-vec3(0,0,sin(tt*2.)*20.))-5.;
      np.z=mod(p.z+tt*10.,15.)-7.5;  
      for(int i=0;i<3;i++){
        np=abs(np)-vec3(0.2,0.2+att*0.2,0);
        np.xy*=r2((cos(np.z*.2*float(i))));   
      }
      vec2 h,t=fb(np);

      pp=abs(p)-vec3(3.2,1.+sin(p.z*0.2),0)-att*0.2;
      pp.z=mod(pp.z-tt*10.,4.)-2.;
      //hollow cubes - one box minus one sphere
      h=vec2(bo(pp,vec3(0.2+att*0.03)),6);
     h.x=max(-(length(pp)-(0.3+att*0.03)),h.x);
      h.x*=0.7;
      t=(t.x<h.x)?t:h;
      //cubes spline
      h=vec2(bo(pp,vec3(0.1+att*0.01,0.1+att*0.01,30)),5);
      h.x*=0.8;
    t=(t.x<h.x)?t:h;
    return t;
}

/*vec2 tr(vec3 ro, vec3 rd,float p,float m,int it )
{
vec2 h,t;h=t=vec2(.1);
  for(int i=0;i<it;i++){
    h=mp(ro+rd*t.x); //get result of running map function at this ray pos
    if(h.x<p||t.x>m) break; //Get out early if we hit geom (<p=precision) or we hit far plane (t.x>m)
    t.x+=h.x;t.y=h.y; 
  } 
  if(t.x>m) t.x=0.;
  return t;
}*/
vec2 tr( vec3 ro,vec3 rd )
{
    vec2 h,t=vec2(0.1);
    for(int i=0;i<128;i++){
        h=mp(ro+rd*t.x);//get result of running map function at this ray pos
        if(h.x<.0001||t.x>50.) break;//Get out early if we hit geom (<precision which is 0.0001) or we hit far plane (t.x>50)
        t.x+=h.x;t.y=h.y;//t.y=h.y passes the material ID
    }
    if(t.x>50.) t.x=0.;//if we hit far plane then make result 0 to do "some" optimization
    return t;
}

void main(void)
{    
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5; uv /= vec2(resolution.y / resolution.x, 1);//Boilerplate code building uvs by default in BONZOMATIC
    tt=mod(time*.5,100.);
    
       vec3 ro=vec3(14,7.+sin(tt*2.)*15.,5.+cos(tt)*15.), //Camera ro=ray origin, rd=ray direction, co=final color, fo=fog, ld=light direction
    cw=normalize(vec3(0.)-ro),cu=normalize(cross(cw,vec3(0,1,0))),cv=normalize(cross(cu,cw)),
    rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo,bk,ld=normalize(vec3(0.2,.2,-.5));
    su=clamp(dot(ld,rd),0.,1.);
    bk=vec3(1,.5,0)*pow(su,4.)+vec3(0.5,.6,.6)-rd.y*0.4;
    co=fo=bk;
    sc=tr(ro,rd);t=sc.x;
  if(t>0.){
    vec3 po=ro+rd*t,no=normalize(e.xyy*mp(po+e.xyy).x+e.yxy*mp(po+e.yxy).x+e.yyx*mp(po+e.yyx).x+e.xxx*mp(po+e.xxx).x),    
    
    //LIGHTING MICRO ENGINE BROSKI 
    //Default albedo is blue with gradient depending on distance to attractor. (al=albedo)
    al=vec3(0,0.5+att*0.02,1);  
    //Different material id? Changeacolourooo... It's all very black and white, makes the red a little punchindaface
    if(sc.y<5.) al=vec3(0);
    if(sc.y>5.) al=vec3(1);       
    //dif = diffuse because I dont have time to cook torrance
    float dif=max(0.,dot(no,ld)),
    //ao = ambient occlusion, aor = ambient occlusion range
    aor=t/50.,ao=exp2(-2.*pow(max(0.,1.-mp(po+no*aor).x/aor),2.)),    
    fre=pow(1.+dot(no,rd),4.);
    vec3 sss=vec3(.5)*smoothstep(0.,1.,mp(po+ld*0.4).x/0.4),
    //spec=specular with the spo 
    spec=vec3(.5)*pow(max(dot(reflect(-ld,no),-rd),0.),10.);
    co=mix(spec+al*(.2+.8*ao)*(dif+sss),bk,fre);
    co+=0.5*vec3(1,.5,0)*pow(su,3.);//Post processing sunglare effect: much better than being slapped across the face with a fish
    co=mix(co,fo,1.-exp(-.00003*t*t*t));
  }      
  //Add some sort of tone mapping... but just like a Hipster's beard and boating shoes: it's not the real thing
  glFragColor = vec4(pow(co,vec3(0.45)),1);
}
