#version 420

// original https://www.shadertoy.com/view/wllSW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float det = .001;
const float max_dist = 24.;
const vec3 e = vec3(0.,det*2.,0.);
const vec3 luz_dir = vec3(.5,-.63,1.);

float obj_id=0.;
vec3 objetivo=vec3(0.);

mat2 rotar(float a) {
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

vec3 tilear(vec3 p, float t) {
    p=abs(t-mod(p,t*2.));
    return p;
}

float esfera(vec3 p, float r) {
    return length(p)-r;
}

float box(vec3 p, vec3 b) {
    p=abs(p)-b;
    return length(max(vec3(0.),p))+min(max(max(p.x,p.y),p.z),0.);
}

float cilindro(vec3 p, float r, float h){
    return max(length(p.xz)-r,abs(p.y)-h);
}

float dunas(vec3 p) {
    p*=.5;
    float d=(cos(p.x)-cos(p.z));
    d*=smoothstep(0.,8.,length(p.xz));
    p*=1.7;
    d-=(sin(p.x)-sin(p.z))*.1;
    return d;
}

float tex(vec3 p) {
    p+=vec3(.2,.3,.4);
    p=tilear(p,.75);
    for (int i=0; i<10; i++) {
        p=abs(p*1.5)-.5;
        p.xz*=rotar(2.);
        p.xy*=rotar(2.);
    }
    p=abs(p);
    return min(1.,max(p.x,max(p.y,p.z)))*.7;
}

float lineas(vec3 p) {
    p*=2.;
    return abs(1.-fract(min(abs(p.x),abs(p.z)))*2.);
}

float estructura(vec3 p) {
    float caj=box(p,vec3(1.,3.5,1.));
    caj-=lineas(p)*.15+.7*max(0.,1.-length(p.xz));
    caj+=smoothstep(0.,3.,3.-p.y)*.5;
    float hue1=box(p,vec3(5.,3.,.5));
    float hue2=box(p,vec3(.5,3.,5.));
    caj=max(caj,-min(hue1,hue2)-smoothstep(1.,4.,p.y)*.4);
    return caj*.5;
}

float tanque(vec3 p) {
    p.y-=2.3;
    float d=cilindro(p,.85,1.);
    p.y+=1.;
    d=min(d,esfera(p,.85));
    p.x+=.6;
    p.y+=.3;
    d=min(d,cilindro(p.zxy,.15,.5));
    p.x+=.5;
    p.y+=1.;
    d=min(d,cilindro(p,.15,1.));
    p.y-=1.;
    d=min(d,esfera(p,.15));
    d-=length(sin(p*60.))*.002;
    return d*.9;
}

float de(vec3 p) {    
    float esf=esfera(p-objetivo,1.);
    float sue=p.y+1.-dunas(p);
    float est=estructura(p);
    float tnq=tanque(p);
    sue*=.9;
    float d=min(esf,est);
    d=min(d,sue);
    d=min(d,tnq);
      obj_id=step(est,d)+step(esf,d)*2.+step(sue,d)*3.+step(tnq,d)*4.;
    return d;
}    

vec3 normal(vec3 p) {
    return normalize(vec3(de((p)+e.yxx),de((p)+e.xyx),de((p)+e.xxy))-de(p));
}

float sombra(vec3 desde) {
    vec3 ldir=normalize(luz_dir);
    float td=.1,sh=1.,d;
    for (int i=0; i<50; i++) {
        vec3 p=desde-ldir*td;
        d=de(p);
        td+=d;
        sh=min(sh,20.*d/td);
        if (sh<.001) break;
    }
    return clamp(sh,0.,1.);
}

float oclusion(vec3 p, vec3 n) {
    float st=.1;
    float ao=0.;

    for(float i=0.; i<6.; i++ ) {
        float td=st*i;
        float d=de(p+n*td);
        ao+=max(0.,(td-d)/td);
    }
    return clamp(1.-ao*.1,0.,1.);
}

float es_id(float id) {
    return 1.-step(.1,abs(obj_id-id));
}

vec3 color(vec3 p, float id) {
    float t=1.-tex(p);
    vec3 col=vec3(1.,.95,.9)*t*es_id(1.)*1.1;
    col+=es_id(2.);
    col+=es_id(4.);
    col+=vec3(1.,.85,.8)*es_id(3.)*(1.+t*.7);
    return col;
}

vec3 light(vec3 p, vec3 dir, vec3 n, float id) {
    float sp=es_id(1.)*.3+es_id(3.)*.3+es_id(4.)*.6;
    vec3 col=color(p, id);
    vec3 ldir=normalize(luz_dir);
    float sh=sombra(p);
    float ao=oclusion(p,n);
    float dif=max(0.,dot(n,-ldir))*.5*sh;
    vec3 ref=reflect(dir,-n);
    float spe=pow(max(0.,dot(ref,-ldir)),8.)*sp*sh;
    float amb=.5;
    return (col*(dif+amb*ao)+spe)*vec3(1.,.95,.9);
}

vec3 march(vec3 desde, vec3 dir) {
    vec3 p=desde,col=vec3(0.),ref_col=vec3(0.);
    float d=0.,td=0., ref=0., ref_dist=0., rebot=0.;
    float in_trans=0.;
    for (int i=0; i<120; i++) {
        p+=d*dir;
        d=de(p);
        if (d<det && (es_id(2.)+es_id(4.))>.5) {
            rebot++;
            desde=p;
            ref_dist=max(ref_dist,td);
            td=0.;
            ref=es_id(2.)*.3+es_id(4.)*.7;
            float id=obj_id;
            p-=dir*det*2.;
            vec3 n=normal(p);
            ref_col=light(p,dir,n,id);
            dir=reflect(dir,n);
        } else if (d<det) break;
        td+=d;
        if (td>max_dist) break;
    }
    if (d<.3) {
        float id=obj_id;
        p-=dir*det*2.;
        vec3 n=normal(p);
        col=light(p,dir,n,id);
    } else {
        td=max_dist;
        p=desde+dir*td;
    }
    float norm_dist=1.-(max_dist-td)/max_dist;
    float norm_dist_ref=1.-(max_dist-ref_dist)/max_dist;
    vec3 fog=mix(vec3(.8,.85,.9),vec3(.95,.9,.85),smoothstep(0.,5.,5.-p.y));
    vec3 fog_ref=mix(vec3(.8,.85,.9),vec3(.95,.9,.85),smoothstep(0.,5.,5.-desde.y));
    col=mix(col,fog,norm_dist);
    col=mix(col,fog_ref,norm_dist_ref);
    col*=max(0.,1.-rebot*.05);
    ref_col=mix(ref_col,fog,norm_dist_ref);
    col=mix(col,ref_col,min(1.,ref));
    vec3 sol=vec3(1.,.7,.4)*pow(max(0.,dot(dir,-normalize(luz_dir))),300.);
    return col+sol*(1.-min(step(.1,ref),step(td+.1,max_dist)));
}

mat3 alinear(vec3 dir,vec3 up){
    dir=normalize(dir);vec3 rt=normalize(cross(dir,normalize(up)));
    return mat3(rt,cross(rt,dir),dir);
}

void main(void)
{
    vec2 uv=gl_FragCoord.xy/resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;    
    vec3 dir=normalize(vec3(uv,1.5));
    vec3 desde=vec3(0.,2.3+sin(time*.2)*3.,-9.);
    desde.x+=max(0.,20.-mod(time,80.)*2.);
    objetivo=vec3(sin(time),.6+sin(time*.2)*.3,cos(time))*3.5;
    desde.xz*=rotar(-time*.1);
    dir=alinear(normalize(vec3(objetivo.x*.5,objetivo.y, objetivo.z*.5)-desde),vec3(0.,1.,0.))*dir;
    vec3 col=march(desde,dir);
    glFragColor = vec4(pow(col,vec3(1.3)),1.0);
}
