#version 420

// original https://www.shadertoy.com/view/M323RD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float t,det=.005, maxdist=100.,lidist=0., drohit=0., roadhit=0., coneinside=0.,drofract, drodist, drocone, droroty, drorotx;
vec3 from, dronedir, dronepos, licolor=vec3(1.,.85,.7), mcolor=vec3(0.,1.,0.);
vec2 uv;

float hash(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

mat3 lookat(vec3 dir, vec3 up) 
{
    dir=normalize(dir);vec3 rt=normalize(cross(dir,normalize(up)));
    return mat3(rt,cross(rt,dir),dir);
}

mat2 rot(float a)
{
    float s=sin(a), c=cos(a);
    return mat2(c,s,-s,c);
}

vec3 path(float t)
{
    float s=sin(t*.1),c=cos(t*.05);
    vec3 p=vec3(vec2(s*s,c*c*c)*5.,t);
    p.y+=smoothstep(.0,.5,abs(.5-fract(t*.02)))*10.;
    return p;
}

float fractal(vec2 p, float anim, int iter)
{
    p=abs(10.-mod(p,20.))-10.;
    float ot=1000.;
    for (int i=0; i<iter; i++)
    {
        p=abs(p)/clamp(p.x*p.y,.25,1.)-2.;
        ot=min(ot,abs(p.y)+.7*anim*fract(abs(p.x)*.1+time*.5+float(i)*.25));
        
    }
    ot=exp(-5.*ot);
    return ot;
}

float box(vec3 p, vec3 l)
{
    vec3 c=abs(p)-l;
    return length(max(vec3(0.),c))+min(0.,max(c.x,max(c.y,c.z)));
}

float kset(vec3 p)
{
    float m=100.;
    p=fract(p*.2);
    for (int i=0; i<5;i++)
    {
        p=abs(p)/dot(p,p)-.8;
        m=min(m,abs(length(p)-2.));
    }
    return exp(-1.*m);
}

float road(vec3 p)
{
    mat2 rot1=rot(p.z*.01);
    mat2 rot2=rot(radians(-30.*sign(p.y)));
    p.y=-abs(p.y)-3.;
    float z=p.z;
    float d=p.y+3.;
    p.z=mod(p.z,10.)-5.;
    float der=1., sc=1.5;
    float m=100.;
    for (int i=0; i<5; i++)
    {
        p=abs(p);
        p=p-1.;
        p.xz*=rot1;
        p.yz*=rot1;
        p.xy*=rot2;
    }
    d=max(d, -box(p,vec3(5.,5.,20.)));
    return d*.6;
}

float lightcone(vec3 p)
{
    p-=dronepos;
    p=lookat(dronedir,vec3(0.,1.,0.))*p;
    return 1.;
}

float de(vec3 p)
{
    vec3 p2=p;
    p-=dronepos;
    p=lookat(dronedir,vec3(0.,1.,0.))*p;
    p.xz*=rot(drorotx);
    p.yz*=rot(droroty);
    vec3 p3=p;
    drocone=max(length(p.xy)+p.z*.25+.3,p.z+2.8);
    p.yz*=rot(-droroty*step(1.15,abs(p.x)));
    drofract=fractal(p.xy*.5,0.,4);
    float dro=length(p)-3.+pow(drofract,.1)*.3;
    dro=max(dro,-length(p+vec3(0.,0.,3.))+.6);
    p.x=abs(abs(p.x)-1.1)-.1;
    dro=max(dro,-abs(p.x)+.07)*.6;
    p=p3;
    p.z+=2.;
    float drolight=length(p)-.5;
    p=p2;
    p.xy-=path(p.z).xy;
    float roa=road(p);
    float d=min(dro,drolight);
    drocone=max(drocone,-roa+.1);
    d=min(d,drocone);
    d=min(d,roa+.2);
    drohit=step(dro,d);
    roadhit=step(roa,d);
    coneinside=step(drocone,d);
    lidist=.1/(.002+drolight*drolight*2.);
    //dronefract+=lidist*5.;
    if (coneinside>.5 && d<.1) return clamp(abs(d),.2,.25);
    return d;
}

vec3 normal(vec3 p)
{
    vec2 e=vec2(0.,det);
    return normalize(vec3(de(p+e.yxx),de(p+e.xyx),de(p+e.xxy))-de(p));
}

float ao(vec3 p, vec3 n) {
    float st=.05;
    float ao=0.;
    for(float i=0.; i<6.; i++ ) {
        float td=st*i*i;
        float d=de(p+n*td);
        ao+=max(0.,(td-d)/td);
    }
    return clamp(1.-ao*.3,0.,1.);
}

vec3 shade(vec3 p)
{
    vec3 n=normalize(p-dronepos);
    p.xy-=path(p.z).xy;
    float c=0.;
    if(coneinside<.5) c+=(fractal(p.xy,1.,6)*abs(n.z)+fractal(p.xz,1.,6)*abs(n.y)+fractal(p.yz,1.,6)*abs(n.x));
    c=max(coneinside*.05,c*(1.-drohit)+drohit*drofract*.5); // optimizar
    c=c*(1.-drohit)+drohit*drofract*.5; // optimizar
    //c+=.1/(.2+abs(drocone))*roadhit;
    return vec3(c*c,c,c*c*c);
}

vec3 march(vec3 from, vec3 dir)
{
    float lion=1.;
    vec3 p, col=vec3(0.),cl=col;;
    float dl=0.;
    float d, td=0.,f,foff;
    float h=(.5-hash(gl_FragCoord.xy+time*10.))*.2;
    //lion=step(.5,fract(time*10.))+.5;
    for (int i=0; i<100; i++)
    {
        p=from+td*dir;
        d=de(p)*(1.+h);
        if (d<det || td>maxdist) break;
        td+=d;
        f=smoothstep(.2,.3,abs(.5-fract(t*.015-p.z*.005)));
        f=1.;
        det*=1.+td*.00*(1.-f);
        col+=shade(p)/(2.+d*d*30.)*exp(-.001*td*td)*(1.-f)*step(1.,td)*.5;
        //dl+=lidist;
        foff=exp(-.2*distance(p,dronepos));
        cl+=coneinside/(1.+d*d)*mix(mcolor,licolor,f)*foff;
    }
//    licolor.xy*=rot(floor(t*.2)*.3);
//    licolor=normalize(abs(licolor));
    if (d<.1) {
        float fade=exp(-.0001*td*td*td);
    //todo: reflejar en el frente del dron el color de la luz
//        float fr=pow(drofract,.3);
//        float li=lidist;
//        float dhit=drohit;
        //float fcol=kset(p)*.2;
        vec2 e=vec2(0.,.2);
        vec3 n=normal(p);
        float camli=max(0.,dot(dir,-n));
        vec3 cuadp=fract(p*2.);
        float cuad=smoothstep(.1,.0,min(cuadp.z,min(cuadp.x,cuadp.y)));
        //cuad=1.;
        col+=camli*(.3+cuad*.2)*fade*f*roadhit*mix(vec3(1.),licolor,lion);
        col+=f*drohit*.2*camli;
        //g+=n*exp(-.002*td*td)*(1.-drohit);
        float fr=pow(drofract,.3);
        col-=f*smoothstep(.8,.9,fr)*drohit*.2;
        col+=f*smoothstep(.31,.3,fr)*drohit*.2;
        //float ns = dot(n,normal(p+e.yxx));
        //ns += dot(n,normal(p+e.xyx));
        //ns += dot(n,normal(p+e.xxy));
        //col+=smoothstep(3.,2.,ns)*f*(1.-drohit)*licolor*fade*licolor*camli*2.;
        col+=.5/(.0+drocone)*licolor*f*roadhit*lion*foff;
        col+=smoothstep(10.,0.,drocone)*licolor*roadhit*f*lion*3.*foff;
        if (roadhit>.5) col=mix(col,col*max(ao(p,n),max(0.,1.-drocone*.15)),f);
    } 
    return col+cl*lion*.07+lidist*(.01+lion)*licolor;
}

void main(void)
{
    float s=sin(time*.25), c=cos(time*.5);
    //if (mouse*resolution.xy.z<.1) {
        drorotx=s*s*s*s*s*2.;
        droroty=c*c*c;
    //} else {
    //    droroty=(mouse*resolution.xy.y/resolution.y-.5)*4.;
    //    drorotx=(mouse*resolution.xy.x/resolution.x-.5)*5.;
    //}
    // Normalized pixel coordinates (from 0 to 1)
    uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv*=1.5;
    if (abs(uv.y)<1.){
    t=time*7.;
    from=path(t+18.)+vec3(5.,0.,0.);
    vec3 adv=path(t+1.);
    dronepos=path(t+10.);
    vec3 droneadv=path(t+12.);
    dronedir=dronepos-droneadv; 
    //dronedir.yz*=droroty;
    vec3 dir=normalize(vec3(uv,.7));
    dir=lookat(adv-from,vec3(0.,1.,0.))*dir;
    //from.xz*=rot(t);
    //dir.xz*=rot(t);
    
    vec3 col=march(from, dir);
    
    // Output to screen
    glFragColor=vec4(col,1.0);
    }
}