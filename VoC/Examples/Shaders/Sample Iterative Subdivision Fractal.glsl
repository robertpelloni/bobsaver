#version 420

// original https://www.shadertoy.com/view/7sKGRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MDIST 150.0
#define STEPS 300.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
//iq palette
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos(2.*pi*(c*t+d));
}
float h21 (vec2 a) {
    return fract(sin(dot(a.xy,vec2(12.9898,78.233)))*43758.5453123);
}
float h11 (float a) {
    return fract(sin((a)*12.9898)*43758.5453123);
}
float box(vec3 p, vec3 b){
    vec3 d = abs(p)-b;
    return max(d.x,max(d.y,d.z));
}
float ebox(vec3 p, vec3 b){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float volume(vec3 a){
    return a.x*a.y*a.z;
}
//Based on code from bigwings comment here
//https://www.shadertoy.com/view/Wl3fD2
float dibox(vec3 p,vec3 b,vec3 rd){
    p/=b;
    vec3 dir = sign(rd)*.5;   
    vec3 rc = (dir-p)/rd;
    rc*=b;
    float dc = min(min(rc.x, rc.y), rc.z)+0.001;
    return dc;
}

vec3 rdg = vec3(0);
vec2 blocks(vec3 p, vec3 scl, vec3 rd){
    float t = time;
      
    vec2 xRange = vec2(-0.5,0.5)*scl.x;
    vec2 yRange = vec2(-0.5,0.5)*scl.y;
    vec2 zRange = vec2(-0.5,0.5)*scl.z;
    float id = 0.;
    float seed = floor(t/6.)+0.1;
    
    //Some parameters to play with :D
    float minSize = 0.15;
    float iters = 12.;
    float minIters = 1.;
    float breakChance = 0.0;
    float maxVolume = 5.0;
    float destructionChance = 0.5;
    float maxCenterDist = 4.5;
    float padFact = 1.01;
    
    float xLength=0.;
    float yLength=0.;
    float zLength=0.;
    
    for(float i = 0.;i<iters;i++){
        xLength = xRange.y-xRange.x;
        yLength = yRange.y-yRange.x;
        zLength = zRange.y-zRange.x;
        
        float dividex = h21(vec2(i+id,seed))*(xLength)+xRange.x;
        float dividey = h21(vec2(i+id,seed))*(yLength)+yRange.x;
        float dividez = h21(vec2(i+id,seed))*(zLength)+zRange.x;
        
        dividex= clamp(dividex,xRange.x+minSize*padFact,xRange.y-minSize*padFact);
        dividey= clamp(dividey,yRange.x+minSize*padFact,yRange.y-minSize*padFact);
        dividez= clamp(dividez,zRange.x+minSize*padFact,zRange.y-minSize*padFact);
        
        float mn = min(length(xRange.x-dividex),length(xRange.y-dividex));
        mn = min(mn,min(length(yRange.x-dividey),length(yRange.y-dividey)));
        mn = min(mn,min(length(zRange.x-dividez),length(zRange.y-dividez)));
        bool willBreak = false;
        if(i-1.>minIters && h11(id)<breakChance) willBreak = true;
        if(mn<minSize&&i-1.>minIters||i==iters-1.) willBreak = true;
        if(willBreak) {
        //id = i*0.1*seed;
        break;
        }
        vec3 diff = vec3(0);
        if(p.x<dividex){
            xRange = vec2(xRange.x,dividex);
            diff.x+=dividex;
        }
        else{
            xRange = vec2(dividex,xRange.y);
            diff.x-=dividey;
        }
        if(p.y<dividey){
            yRange = vec2(yRange.x,dividey);
            diff.y-=dividex;
        }
        else{
            yRange = vec2(dividey,yRange.y);
            diff.y+=dividey;
        }
        if(p.z<dividez){
            zRange = vec2(zRange.x,dividez);
            diff.z-=dividex;
        }
        else{
            zRange = vec2(dividez,zRange.y);
            diff.z+=dividez;
        }

        id = length(diff+10.0);
    }
    
    float volume = volume(vec3(xLength,yLength,zLength));
    vec3 center = vec3((xRange.x+xRange.y)/2.,(yRange.x+yRange.y)/2.,(zRange.x+zRange.y)/2.);

    //huge improvment in performance by using distance to intersection of empty cell
    //to remove boxes (instead of using a negative box sdf)
    //But it seems to cause artifacts rarely, idk why
    float b = dibox(p-center,vec3(xLength,yLength,zLength),rd);
    
    float shr = 1.0-abs(pow(abs(cos(mod(t,6.)*pi/6.)),6.0));
    shr = smoothstep(0.,1.,shr);
    vec3 d = abs(center);
    center.y-=yLength*(1.0-shr)*0.5;
    yLength*=shr;
    float a = box(p-center,vec3(xLength,yLength,zLength)*0.5);

    //I found this helps to remove some of the artifacts from using the empty box intersection
    if(abs(p.x)>scl.x*0.5) b=-a;
    if(abs(p.z)>scl.z*0.5) b=-a;
    
    a=min(a,b);
    if(max(d.x,max(d.y*0.5,d.z))>maxCenterDist)a=b;
    else if(volume>maxVolume)a=b;
    else if (h11(id*1.1)<destructionChance)a=b;
    
    id = h11(id)*1000.0;

    return vec2(a,id);
}

vec2 map(vec3 p){
    float t = time;
    p.y-=1.0;
    vec3 po = p;
    vec2 a = vec2(1);
    vec2 b = vec2(2);
    vec3 scl = vec3(10.0,14.,10);
    vec3 rd2 = rdg;
    a = blocks(p,scl,rdg)+0.02;
    
    a.x = max(box(p,vec3(scl*0.49)),a.x);
    
    p.y+=scl.y*0.5+5.2;
    b.x = ebox(p,vec3(5.2))-0.2;
    
    a=(a.x<b.x)?a:b;
    return a;
}
vec3 norm(vec3 p){
    vec2 e = vec2(0.00005,0.);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    float t = time;
    vec3 col = vec3(0);
    vec3 ro = vec3(0,5,-20);
    //if(mouse*resolution.xy.z>0.){
    //ro.zx*=rot(7.0*mouse*resolution.xy.x/resolution.x);
    //}
    //else ro.zx*=rot(time*0.3);
    ro.zx*=rot(time*0.3);
    vec3 lk = vec3(0,0.,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*0.95+uv.x*r+uv.y*cross(f,r));    
    rdg = rd;
    vec3 p = ro;
    float dO = 0.;
    vec2 d = vec2(0);
    bool hit = false;
    for(float i = 0.; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x*0.99;
        if(abs(d.x)<0.0001){
            hit = true;
            break;
        }
        if(d.x>MDIST){
            dO=MDIST;
            break;
        }
    }
    if(hit){
        vec3 ld = normalize(vec3(0.5,1,-1));
        vec3 n = norm(p);
        vec3 r = reflect(rd, n);
        vec3 e = vec3(0.5);
        
        vec3 al = pal(d.y*0.1,e*1.2,e,e*2.0,vec3(0,0.33,0.66));
        if(d.y==2.0) al = vec3(1.);
        col = al;
        
        float diff = length(sin(n*2.)*.5+.8)/sqrt(3.);
        col = al*diff;
        
        float shadow = 1.;
        rdg = ld;
        for(float h = 0.05; h<50.;){
            float dd = map(p+ld*h).x;
            if(dd<0.001){shadow = 0.6; break;}
            h+=dd;
        }     
        col*=shadow;
    }
    vec3 bg = mix(vec3(0.173,0.231,0.686),vec3(0.361,0.753,1.000),rd.y*0.5+0.5);
    col = mix(col,bg,dO/MDIST);
    glFragColor = vec4(col,1.0);
}
/*
#define AA 2.0
#define ZERO min(0.0,time)
void main(void)
{
    float px = 1.0/AA;
    vec4 col = vec4(0);
    
    if(AA==1.0) {render(col,gl_FragCoord.xy); glFragColor = col; return;}
    
    for(float i = ZERO; i <AA; i++){
        for(float j = ZERO; j <AA; j++){
            vec4 col2;
            vec2 coord = vec2(gl_FragCoord.xy.x+px*i,gl_FragCoord.xy.y+px*j);
            render(col2,coord);
            col.rgb+=col2.rgb;
            rdg = vec3(0);
        }
    }
    col/=AA*AA;
    glFragColor = vec4(col);
}
*/
