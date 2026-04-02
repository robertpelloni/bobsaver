#version 420

// original https://www.shadertoy.com/view/tdSSWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14195265359
#define EPS 0.001

mat2 rotate(float a){
    float s = sin(a); float c = cos(a);
    return mat2(c, -s,s, c);
}

float hash21( vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233)))* 43758.5453123);
}

vec2 hash22(vec2 p){
    float n = hash21(p);
    return vec2(n,hash21(n+p));
}

//http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos( 6.28318*(c*t+d) );
}

float sdCappedCylinder( vec3 pos, vec2 h ){
  vec2 d = abs(vec2(length(pos.xz),pos.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCapsule( vec3 pos, vec3 a, vec3 b, float r ){
    vec3 pa = pos - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdWireBox(vec3 pos,float W,float H, float D){
    float r = 0.01;
    float hw = 0.5*W, hh = 0.5*H, hd = 0.5*D;
    float d= sdCapsule(pos- vec3(-hw,0.0,-hd),vec3(0.0,hh,0.0),vec3(0.0,-hh,0.0),r);
    d = min(d,sdCapsule(pos- vec3(-hw,0.0,hd),vec3(0.0,hh,0.0),vec3(0.0,-hh,0.0),r));
    d = min(d,sdCapsule(pos- vec3(hw,0.0,-hd),vec3(0.0,hh,0.0),vec3(0.0,-hh,0.0),r));
    d = min(d,sdCapsule(pos- vec3(hw,0.0,hd),vec3(0.0,hh,0.0),vec3(0.0,-hh,0.0),r));
    d = min(d,sdCapsule(pos- vec3(0.0,-hh,-hd),vec3(hw,0.0,0.0),vec3(-hw,0.0,0.0),r));
    d = min(d,sdCapsule(pos- vec3(0.0,-hh,hd),vec3(hw,0.0,0.0),vec3(-hw,0.0,0.0),r));
    d = min(d,sdCapsule(pos- vec3(0.0,hh,-hd),vec3(hw,0.0,0.0),vec3(-hw,0.0,0.0),r));
    d = min(d,sdCapsule(pos- vec3(0.0,hh,hd),vec3(hw,0.0,0.0),vec3(-hw,0.0,0.0),r)); 
    d = min(d,sdCapsule(pos- vec3(-hw,-hh,0.0),vec3(0.0,0.0,hd),vec3(0.0,0.0,-hd),r)); 
    d = min(d,sdCapsule(pos- vec3(-hw,hh,0.0),vec3(0.0,0.0,hd),vec3(0.0,0.0,-hd),r)); 
    d = min(d,sdCapsule(pos- vec3(hw,-hh,0.0),vec3(0.0,0.0,hd),vec3(0.0,0.0,-hd),r)); 
    d = min(d,sdCapsule(pos- vec3(hw,hh,0.0),vec3(0.0,0.0,hd),vec3(0.0,0.0,-hd),r)); 
    return d;
}

float sdBox(vec3 pos, vec3 b){
    vec3 d = abs(pos) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdSphere(vec3 pos, float r){
    return length(pos) - r;
}

float sdWall(vec3 pos){
    pos.xz = abs(pos.xz);
    return min(5.0-pos.z,5.0-pos.x);
}

//Roof and Floor
float sdRF(vec3 pos){
    return min(pos.y + 1.0,3.0 - pos.y);
}

vec2 matMin(vec2 a, vec2 b){
    return (a.x < b.x) ? a : b;
}

//https://www.shadertoy.com/view/ldGyWW
vec3 map(vec3 pos){
    vec2 dist = vec2(10000.0,-1.0);//x:dist, y:material
    float light = 10000.0;//light object
    
    vec3 p = pos;
    float rep = 2.5;
    vec3 id = floor(pos/rep);
    p.xz = mod(p.xz,rep) - rep*0.5;
    vec2 rand = 1.2*hash22(id.xz) - vec2(0.6);
    p -= vec3(rand.x,0.0,rand.y); 
    p.xz *= rotate(time);
    p.y += 8.0*fract(-hash21(id.zz)*time*0.7+hash21(id.xz))-4.0; 
    float cube = sdWireBox(p,0.4,0.4,0.4);
    dist = matMin(dist,vec2(cube,1.0));
   
    p = pos;
    rep = 3.0;
    id = floor(pos/rep);
    p.xz = mod(p.xz,rep) - rep*0.5;
    rand = 1.3*hash22(id.zx) - vec2(0.65);
    p -= vec3(rand.x,0.0,rand.y); 
    p.y += 8.0*fract(-hash21(id.xz)*time*0.25+hash21(id.zx))-4.0;
    float sphere = sdSphere(p,0.5);
    dist = matMin(dist,vec2(sphere,2.0));

    p = pos;
    float wall = sdWall(p);
    dist = matMin(dist,vec2(wall,1.0));
    float roof = sdRF(p);
    dist = matMin(dist,vec2(roof,2.0));

    p = pos;
    float tRep = 0.75;
    vec2 tId = floor(pos.xz/tRep); 
    float lam = hash21(hash22(tId))*2.0 + 0.5;
     float speed = 2.0*hash21(tId) - 1.0; 
    p.xz = mod(p.xz,tRep) - tRep*0.5;
    p.y = mod(p.y+speed*time,lam) - lam * 0.5;
    float tile = sdBox(p,vec3(tRep*0.45,lam*0.48,tRep*0.45));
    float mask = clamp(5.0+4.0*sin(time),3.0,4.8);
    tile = max(tile, -sdBox(pos,vec3(mask)));
    dist = matMin(dist,vec2(tile,2.0));

    light = min(cube,wall);
    return vec3(dist,light);
}

vec3 calcNorm(vec3 pos){
    float d = 0.0001;
    return normalize(vec3(
        map(pos + vec3(  d, 0.0, 0.0)).x - map(pos + vec3( -d, 0.0, 0.0)).x,
        map(pos + vec3(0.0,   d, 0.0)).x - map(pos + vec3(0.0,  -d, 0.0)).x,
        map(pos + vec3(0.0, 0.0,   d)).x - map(pos + vec3(0.0, 0.0,  -d)).x
    ));
}

vec3 light = normalize(vec3(0.0,5.0,3.0));

vec3 render(vec3 ro, vec3 rd){
    vec3 col = vec3(0.0);
    float gl =  0.0;
    vec3 col_gl = pal(time*0.1, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67));
    vec3 col_rGl = pal(time*0.1+0.3, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67));

    float t = 0.0;
    vec3 m;
    vec3 pos;
    for(int i = 0; i < 64; i++){
        pos = ro + t*rd;
          m = map(pos);
        if(m.x < EPS) break;
        //t += m.x*0.75;
        //https://qiita.com/ukeyshima/items/221b0384d39f521cad8f
        t += min(min((step(0.0,rd.x)-fract(pos.x))/rd.x, 
            (step(0.0,rd.z)-fract(pos.z))/rd.z)+0.01,m.x)*0.75;
        gl += 0.1 / (m.z*m.z*300.0);
    }
    pos = ro + t*rd;
   
    vec3 norm = calcNorm(pos);
    vec3 v = normalize(ro-pos);
    vec3 l = normalize(light-pos);
    vec3 r = normalize(reflect(-l,norm));
    
    t = 0.0;
    vec3 rRo = pos + norm*0.05;
    vec3 rPos;
    vec3 rM;
    float rGl = 0.0;
    for(int i = 0; i < 32; i++){
        rPos = rRo + t * r;
        rM = map(rPos);
        if(rM.x < EPS) break;
        //t += m.x * 0.75;
        t += min(min((step(0.0,r.x)-fract(rPos.x))/r.x, 
            (step(0.0,r.z)-fract(rPos.z))/r.z)+0.01,rM.x)*0.75;
        rGl += 0.1 / (rM.z*rM.z*300.0);
    }
    
    float diff = clamp(dot(l, norm), 0.1, 1.0);//diffuse
   
    if(m.y == 2.0){
        col = diff*vec3(0.10) + col_gl*gl + col_rGl*rGl;
    }else{//grow object
        col = col_gl * gl;
    }  
    return col;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy*2.0 - resolution.xy)/min(resolution.x,resolution.y);
    
    vec3 up = vec3(0.,1.,0.);
    vec3 lookAt = vec3(0.0,0.5,0.0);
    vec3 ro = vec3(0.0,0.75,3.0);
       ro.xz *= rotate(time*0.25);
    
    vec3 cDir = normalize(lookAt-ro);
    vec3 cSide = normalize(cross(cDir,up));
    vec3 cUp = normalize(cross(cSide,cDir));
     
    vec3 rd= normalize(cSide * p.x + cUp * p.y + cDir * 2.0 );
 
    vec3 col = render(ro,rd);
    glFragColor = vec4(col,1.0);
}
