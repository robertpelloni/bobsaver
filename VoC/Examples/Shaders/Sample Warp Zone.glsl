#version 420

// original https://www.shadertoy.com/view/WttXDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
float speed =  15.0;//15.0;
vec3 tpos;

mat2 rotate(float a){
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float hash11(float p){
     return fract(sin(p*12.9898)* 43758.5453123);
}
vec3 hash13(float p){
    return fract(cos(p)*vec3(342.87234,174297.125,8723.924));

}
float hash21( vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233)))* 43758.5453123);
}

vec2 hash22(vec2 p){
    float n = hash21(p);
    return vec2(n,hash21(n+p));
}

vec2 pMod(vec2 pos,float s){
    float a = PI/s - atan(pos.x,pos.y);
    float n = 2.0*PI/s;
    a = floor(a/n) * n;
    pos *= rotate(a);
    return pos;
}

float isectPlane(vec3 n, float d, vec3 org, vec3 dir){
    float t = -(dot(org, n) + d) / dot(dir, n);
    return t;
}

float sdSphere(vec3 pos, float r){
    return length(pos) - r;
}

float sdBox(vec3 pos, vec3 r){
    vec3 d = abs(pos) - r;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

vec2 matMin(vec2 a, vec2 b){
    return (a.x < b.x) ? a : b;
}

vec2 map(vec3 pos){
    vec2 map = vec2(10000.0,-1.0); 
   
    vec3 p = pos;
    p.x += (p.y > 0.0) ? time*4.0 : -time*4.0;
    vec2 id = floor(p.xz/4.0);
    vec2 rand = hash22(id) * 0.5 + 0.2;
    p.xz = mod(p.xz,4.0) - 2.0;
    p.y = abs(p.y) - 10.0;
    //p -= vec3(0.0,hash21(id)*0.2,0.0);
    float d = sdBox(p,vec3(rand.x,9.0 + hash21(id)*0.3,rand.y));
    map = matMin(map,vec2(d,1.0)); 

    p = pos;
    p.x += floor(p.z/3.0);
    p.x += (p.y > 0.0) ? time*4.0 : -time*4.0;
    id = floor(p.xz / 3.0);
    rand = hash22(id) * 0.3 + 0.2;
    p.xz = mod(p.xz,3.0) - 1.5;
    p.y = abs(p.y) - 10.;
    //p -= vec3(0.0,hash21(id)*0.2,0.0);
    d = sdBox(p,vec3(rand.x,9.0 + hash21(id)*0.3,rand.y));
    map = matMin(map,vec2(d,1.0));

    p = pos;
    p.z = mod(p.z,20.0) - 10.0;
    vec3 bPos = (hash13(floor(pos.z/20.0))*vec3(20.0,2.0,5.0)) - vec3(10.0,1.0,2.5);
    bPos.x = (abs(bPos.x) < 1.0) ? bPos.x + sign(bPos.x)*1.5 : bPos.x;
    p = p - bPos;
    p.xy *=rotate(time*hash21(vec2(floor(pos.z/20.0))));
    p.xz *= rotate(time*0.5);
    tpos = p;
    float box = sdBox(p,vec3(1.0));
    map = matMin(map,vec2(box,2.0));
    return map;
}

vec3 calcNorm(vec3 pos){
    float d = 0.0001;
    return normalize(vec3(
        map(pos + vec3(  d, 0.0, 0.0)).x - map(pos + vec3( -d, 0.0, 0.0)).x,
        map(pos + vec3(0.0,   d, 0.0)).x - map(pos + vec3(0.0,  -d, 0.0)).x,
        map(pos + vec3(0.0, 0.0,   d)).x - map(pos + vec3(0.0, 0.0,  -d)).x
    ));
}

vec3 lighting(vec3 pos,vec3 ro,vec2 m){
    vec3 col = vec3(0.0);
    vec3 light = vec3(0.0,0.0,5.0-time*speed);
    vec3 N = calcNorm(pos);
    vec3 L = normalize(light-pos);
    vec3 E = normalize(pos - ro);
    vec3 V = normalize(ro - pos);
    vec3 R  = normalize(reflect(-L,N));

    float diff = clamp(dot(N,L),0.1,1.0);
    float spec = max(0.0,pow(dot(R,V),32.0)); 
    if(m.y == 1.0){
        col = vec3(0.01) + vec3(0.15,0.05,0.05)*diff;
    }else if(m.y == 2.0){  
        col = vec3(0.01) + vec3(0.1,0.1,0.1)*diff + 0.2*vec3(0.7,0.7,0.95)*spec;
    }
    
    return col;
}

vec3 render(vec3 ro,vec3 rd){
    vec3 col = vec3(0.0);
    float t = 0.0;
    float dist = 10000.0;
    float EDGE = 0.03;

    vec3 pos;
    vec2 m; 
    float e = 0.0;
    float lD = 1e10;
    for(int i = 0; i < 128; i++){
        pos = ro + t*rd;
        m = map(pos);
        t += m.x*0.75;

        //edge detection
        //https://www.shadertoy.com/view/MsB3W1
        if(lD < EDGE && m.x > lD + 0.01){
            e = 1.0;
            break;
        }
        if(abs(m.x) < 0.001){
            break;
        }
        if(m.x < lD) lD = m.x;

    }
    pos = ro + t*rd;
    vec3 c;
    if(abs(m.x) < 0.001){
        if(m.y != -1.0)
            col = lighting(pos,ro,m);
    }
    
    col += mix(0.0,1.0,e);
    col *= 1.0 - clamp(((abs(pos.y)-2.5)),0.0,1.0);
    col += vec3(0.4,0.1,0.1)*clamp(((abs(pos.y)-3.0))*0.2,0.0,1.0);
    col += vec3(1.0,0.5,0.5)*length(m.x);

    //https://www.shadertoy.com/view/4sSSWz
    for(int i=0;i<2;i++){
        for(int j = 0;j<1;j++){
        t = isectPlane(vec3(0.0,(i>0)?-1.0:1.0,0.0),300.0+float(j)*20.0,ro,rd);
        if(t > 0.0)continue;
        pos = ro + t*rd;
        float rep = 10.0;
        vec3 pp = floor(pos/rep)*rep;
        float n = pp.x * float(i+1)*100.0 + float(j);
        float q = hash11(n);
        float q2 = hash11(n*q);
        q = sin(pp.z*0.0004+q*10.0-time*0.5);
        q = clamp(q*100.0-100.0+1.0,0.0,1.0)*0.8;
        //q *= saturate(4.0 - 8.0 * abs(-2.5 + pp.y - pos.y) / 100.0);
        q *= 1.0 - clamp(pow(t / 5000.0, 5.0),0.0,1.0);
        if(m.y != 2.0){
            col += q*vec3(0.8,0.1,0.1);
            col += (q2 > 0.5*sin(time)+0.5) ? q : 0.0;
        }
        }
    }
    
    return vec3(col);

}

mat3 cam(vec3 ro, vec3 ta){
    vec3 cUp = vec3(0.0,1.0,0.0);
    vec3 cDir = normalize(ta-ro);
    vec3 cSide = normalize(cross(cDir,cUp));
    cUp = normalize(cross(cSide,cDir));

    return mat3(cSide,cUp,cDir);
}

void main(void) {
    vec2 p = gl_FragCoord.xy*2.0 - resolution.xy;
    p /= min(resolution.x,resolution.y);

    vec3 ro = vec3(0.0,0.0,3.0);
    vec3 ta = vec3(0.0,0.0,0.0);

    ro.z +=  -time*speed;
    ta.z += -time*speed;
    vec3  rd = normalize(vec3(p,2.0)) * cam(ro,ta);

    vec3 col = render(ro,rd);

    glFragColor = vec4(col,1.0);
}
