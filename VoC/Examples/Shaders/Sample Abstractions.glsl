#version 420

// original https://www.shadertoy.com/view/NdcGDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 150.0
#define MDIST 100.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
vec3 rdg = vec3(0);
float h21(vec2 p){
    return fract(43757.5453*sin(dot(p, vec2(12.9898,78.233))));
}
float h13(vec3 p3){
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}
float octa( vec3 p, float s){
  p = abs(p);
  return (p.x+p.y+p.z-s)*-tan(5.0*pi/6.0);
}
float box(vec3 p, vec3 b){
    vec3 d= abs(p)-b;
    return max(d.x,max(d.y,d.z));
}
bool filled(vec3 id){
    if(id.y<0.) return true;
    float cyc = floor(time*0.15);
    float hash = h13(id+cyc);
    cyc = mod(cyc,3.0);
    //I had to do this uglyness because compiler keeps tryning to inline everything
    float w1 = max(abs(id.x),abs(id.z));
    float w2 = length(id.y*id.y);
    float w3 = 0.3;
    if(cyc==0.0) w1 = length(id.xz);
    if(cyc==2.0) {w2 = abs(id.y);w3 = 0.4; }
    return(hash+w1*w3+w2*0.01<0.85);
}
vec2 map(vec3 p){
    float t = time;
    vec3 po = p;
    vec2 a = vec2(9999.,1);
    vec2 b = vec2(2);
    
    vec3 id = floor(p);
    //float hash = h13(id+floor(t*0.1));
    vec3 dir = sign(rdg)*.5;
    vec3 q = fract(p)-.5;
    //q = vec3(q.x,q.y,q.z);
    vec3 rc = (dir-q)/rdg;

    float dc = min(rc.x,min(rc.y,rc.z))+0.01;
    bool ifilled = filled(id);
    if(max(id.x,id.z)<5.0){
        if(ifilled)a.x = box(q,vec3(0.5));
        float nbors = 0.;
        vec3 off = vec3(0);
        if(filled(id+vec3(1,0,0))){nbors++;off+=vec3(1,0,0);}
        if(filled(id+vec3(0,1,0))){nbors++;off+=vec3(0,1,0);}
        if(filled(id+vec3(0,0,1))){nbors++;off+=vec3(0,0,1);}
        if(filled(id+vec3(-1,0,0))){nbors++;off+=vec3(-1,0,0);}
        if(filled(id+vec3(0,-1,0))){nbors++;off+=vec3(0,-1,0);}
        if(filled(id+vec3(0,0,-1))){nbors++;off+=vec3(0,0,-1);}
        if(nbors==3.0&&!ifilled)a.x = max(box(q,vec3(0.5)),-(length(q+off*0.5)-1.)*0.6);
        float hh = h13(id+floor(time*0.15));
        if(nbors==2.0&&!ifilled&&hh>0.33){
            vec3 p2 = q+off*0.71;
            p2.xy*=rot((1.0-abs(off.z))*pi/4.);
            p2.yz*=rot((1.0-abs(off.x))*pi/4.);
            p2.zx*=rot((1.0-abs(off.y))*pi/4.);
            float cut = box(p2,vec3(1.0));
            a.x = max(box(q,vec3(0.5)),-cut*0.6)*0.7;
        }
        else if(hh>0.26&&nbors==2.0&&!ifilled)a.x = max(box(q,vec3(0.5)),-(length(q+off*0.5)-1.1)*0.6);
        
        if(nbors==2.0&&!ifilled&&off==vec3(0))a.x = box(q,vec3(0.5));
       // if(nbors==3.0&&!ifilled)a.x = box(q,vec3(0.5));
    }
    b.x = p.y;
    a=(a.x<b.x)?a:b;
    dc = max(dc,box(po,vec3(4,50,4)));
    a.x = min(a.x,dc);
    
    return a;
}
vec3 norm(vec3 p,float s){
    vec2 e = vec2(s,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void render( out vec4 glFragColor){
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    vec3 ro = vec3(0,6,-13);
    //if(mouse*resolution.xy.z>0.){
    //ro.xz*=rot(10.0*mouse*resolution.xy.x/resolution.x);
    //}
    //else ro.xz*=rot(time*0.3);
    ro.xz*=rot(time*0.3);

    vec3 lk = vec3(0,3.5,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = f*1.1+uv.x*r+uv.y*cross(f,r);
    rdg = rd;
    vec3 p = vec3(0);
    vec2 d = vec2(0);
    float dO= 0., shad = 0.;
    bool hit = false;
    
    for(float i = 0.0; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x;
        if((d.x)<0.005){
            hit = true;
            shad = i/STEPS;
            break;
        }
        if(dO>MDIST){
            break;
        }
    }
    if(hit){
        vec3 ld = normalize(vec3(0.5,1.01,-1));
        //ld.xz*=rot(time*0.3);
        vec3 n = norm(p,0.001);
        vec3 h = normalize(ld-rd);
        float spec = pow(max(dot(n,h),0.0),5.0);
        //float fres = pow(1. - max(dot(n, -rd),0.), 5.);
        float diff = dot(n, ld)*0.4+0.6;
        vec3 al = vec3(1);
        ld.xy*=rot(h21(uv)*0.005);
        ld.yz*=rot(h21(uv+1.)*0.005);
        ld.zx*=rot(h21(uv+2.)*0.005);
        float shadow = 1.;
        rdg = ld;
        for(float h = 0.05; h<20.;){
            float dd = map(p+ld*h).x;
            if(dd<0.001){shadow = 0.6; break;}
            h+=dd;
        }
        //shadow = max(shadow,0.8);
        
        //AO & soft shadow doesn't work because of the domain rep tricks, oh well
        
        diff -=(h21(uv)-0.4)*(pow(1.0-diff*shadow,10.0))*3.0;
        col=al*diff+pow(spec,2.0)*0.1*shadow;
        col*=shadow;
    }
    else{
    col = mix(vec3(0.6),vec3(0.647,0.647,0.694),uv.y);
    }
    //col = sqrt(col);
    glFragColor = vec4(col,1.0);
}

//if you have a very good GPU you can crank up the AA and it looks a lot better
#if HW_PERFORMANCE==0
#define AA 1.0
#else
#define AA 2.0 
#endif

#define ZERO min(0.0,time)
void main(void)
{
    float px = 1.0/AA;
    vec4 col = vec4(0);
    
    if(AA==1.0) {render(col); glFragColor = col; return;}
    
    for(float i = ZERO; i <AA; i++){
        for(float j = ZERO; j <AA; j++){
            vec4 col2;
            vec2 coord = vec2(gl_FragCoord.xy.x+px*i,gl_FragCoord.xy.y+px*j);
            render(col2);
            col.rgb+=col2.rgb;
        }
    }
    col/=AA*AA;
    glFragColor = vec4(col);
}

