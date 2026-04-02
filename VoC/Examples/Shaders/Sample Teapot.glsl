#version 420

// original https://www.shadertoy.com/view/XsSGzG
uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

     #define D dot 
   #define  X  cross
  #define N normalize 
   #define  C  clamp
     #define M mix                  
                                                           vec3 t2[5],t3[5],
                                                          L=N(vec3(-6,7,-5));
                                                         vec2 ep=vec2(.005,0);
                                                             vec2 t1[15];
                                         vec3 cls(in vec2 b0,in vec2 b1,in vec2 b2){float a=
b0.x*b2.y-b2                         .x*b0.y,b=2.*(b1.x*b0.y-b0.x*b1.y),d=2.*(b2.x*b1.y-b1.x*b2.y),
 f = b*d-a*a;                     vec2 d21=b2-b1,d10=b1-b0,d20=b2-b0,gg=2.*(b*d21+d*d10+a*d20),gf=vec2(gg.y,-gg.x),
  d0p =b0+f*gf                   /D(gf,gf);float t=C((d0p.x*d20.y-d20.x*d0p.y+2.*(d10.x*d0p.y-d0p.x*d10.y))/(2.*a+b+d),0.,1.);
   return vec3(                 M(M(b0,b1,t),M(b1,b2,t),t),t);}vec2 bz(vec3 a,in vec3 b,in vec3 c,in vec3 p){vec3 w=N(X(c-b,a-b)
   ),u=N(c-b),v=               N(X(w,u));vec2 a2=vec2(D(a-b,u),D(a-b,v)),c2=vec2(D(c-b,u),D(c-b,v));vec3               p3=vec3(D(p
    -b,u), D(p-b,            v),D(p-b,w)),cp= cls(a2-p3.xy,-p3.xy,c2-p3.xy);return vec2(sqrt(D(cp.xy,cp.                  xy)+ p3.z
    *p3.z),cp.z);}          int ltp(in vec2 s) { t1[0]=vec2(0,0); t1[1]=vec2(16,0); t1[2] = vec2(16,1);t1                  [3]= vec2
    (20,4);t1[4]=         vec2(20,10);t1[5]=vec2(20,16);t1[6]=vec2(16,30);t1[7]=vec2(15,31);t1[8]=vec2(14,                30);t1[9]=
     vec2(14,32);t1[     10]=vec2(3,34);t1[11]=vec2(0,36);t1[12]=vec2(4,37);t1[13]=vec2(5,40);t1[14]=vec2(0              ,40);t2[0]=
     vec3(-15,26,0);t2  [1]=vec3(-29,28,0);t2[2]=vec3(-29,21,0);t2[3]=vec3(-30,14,0);t2[4]=vec3(-18,8,0);t3[             4]=vec3(18,
     14,0);t3[3]=vec3(23,16,0);t3[2]=vec3(25,24,0);t3[1]=vec3(26,30,0);t3[0]=vec3(29,32,0);for(int i=0;i<15;           i++)t1[i]*=
      s;for(int i=0;i<5;i++){t2[i].xy*=s; t3[i].xy*=s;}return 15;}float smin(float a,float b){return a*b/(a+b);        }float map(
      vec3 p){vec2 h=bz(t3[2],t3[3],t3[4],p);float d3=1.e5,r=length(p),e=.08,d1=min(min(bz(t2[0],t2[1],t2[2],p)      .x-.06,bz(t2
      [2],t2[3],t2[4],p).x-.06),max(D(p,vec3(0,1,0))-.9,min(abs(bz(t3[0],t3[1],t3[2],p).x-.07)-.01,(h.x*(1.-.75*h .y)-e))));for
        (int i=0;i<13;i+=2){d3=min(d3,(bz(vec3(t1[i],0),vec3(t1[i+1],0),vec3(t1[i+2],0),vec3(r*sin(acos(p.y/r)),p.y,0)).x-.002
         )/1.5);}return smin(d1,d3);}float ray(in vec3 ro,in vec3 rd,in float maxd){float e=.008,h=e*2.,t=0.,d;for(int i=0;i
          <60;i++) if (abs(h)>e && t<maxd) t+= h =map(ro+rd*t); return abs(h)<=e?t:1e5;} float ssh(in vec3 ro) { float h, 
           res=1.,t=.02; for(int i=0;i<15;i++){ if(t<10.) {h=map(ro+L*t);res=min(res,map(ro+L*t)/t );t+=.015;}}return 
            C(7.*res,0.,1.);}vec3 calcNormal(in vec3 p) {return N(vec3(map(p+ep.xyy)-map(p-ep.xyy),map(p+ep.yxy)-map
             (p-ep.yxy),map(p+ep.yyx)-map(p-ep.yyx)));}float calcAO(in vec3 p,in vec3 n){float hr,dd,t=0.,k=1.; for(
               float aoi=0.;aoi<5.;aoi++){hr=.01+.05*aoi;t-=(map(n*hr+p)-hr)*k;k*=.75;}return C(1.-4.*t,0.,1.);}vec3
                render(in vec3 o,in vec3 d){vec3 p,n,c=vec3(1);float t=ray(o,d,20.);if(t<10.){c=vec3(1,0,0); p=o+t*d;
                  n=calcNormal(p);float ao=calcAO(p,n),am=C(.5+.5*n.y,0.,1.),df=C(D(n,L),0.,1.),sh=1.; if(df>.02)sh=
                   ssh(p);c=ao*pow(C(1.+D(n,d),0.,1.),2.)*(.5+.1*c)+c*(ao*am*.02+sh*df*1.2+sh*pow(C(D(reflect(d,n),L
                     ),0.,1.),16.));}return c;}void main(void){ltp(vec2(.04,.03));vec2 m=mouse.xy/resolution.xy,
                       q=gl_FragCoord.xy/resolution.xy,p=-1.0+2.0*q;p.x*=resolution.x/resolution.y;float t=4.
                         *time; vec3 ro=vec3(3.*cos(t+6.*m.x),1.5+2.*m.y,3.*sin(t+6.*m.x)),cw =N(vec3(
                            0,.4,0)-ro),cu=N(X(cw,vec3(0,1,0))),cv=N(X(cu,cw)),rd=N(p.x*cu+p.y*cv +2.5*cw);
                             
                                            
                                               glFragColor=vec4(sqrt(render(ro,rd)),1.);}
