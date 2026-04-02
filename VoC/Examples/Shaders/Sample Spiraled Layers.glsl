#version 420

// original https://www.shadertoy.com/view/Ns3XWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Spiral SDF testing 2" by Tater. https://shadertoy.com/view/fs3Xzf
// 2021-10-12 11:43:34

// Fork of "Spiral SDF testing" by Tater. https://shadertoy.com/view/fs3SzX
// 2021-10-07 08:34:52

#define pmod(p,x) (mod(p,x)-0.5*(x))
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define STEPS 200.0
#define MDIST 100.0

//Change to 2.0 for AA
#define AA 1.0

vec3 rdg = vec3(0);
float ext(vec3 p, float s, float h){
  vec2 b = vec2(s,abs(p.y)-h);
  return min(max(b.x,b.y),0.)+length(max(b,0.));
}
float h11(float a) {
    a+=0.65343;
    return fract(fract(a*a*12.9898)*43758.5453123);
}
float diplane(vec3 p,vec3 b,vec3 rd){
    p/=b;
    vec3 dir = sign(rd)*.5;   
    vec3 rc = (dir-p)/rd;
    rc*=b;
    float dc = rc.z+0.01;
    return dc;
}
float lim(float p, float s, float lima, float limb){
    return p-s*clamp(round(p/s),lima,limb);
}
float idlim(float p, float s, float lima, float limb){
    return clamp(round(p/s),lima,limb);
}
float lim2(float p, float s,  float limb){
    return p-s*min(round(p/s),limb);
}
float idlim2(float p, float s, float limb){
    return min(round(p/s),limb);
}
//If someone knows of a simpler method to make this SDF please let me know
float spiral(vec2 p, float t, float m, float scale, float size, float expand){
    size-=expand-0.01;
    //Offset Spiral To the left
    t = max(t,0.);
    
    p.x+=pi*-t*(m+m*(-t-1.));
    t-=0.25;
    
    
    vec2 po = p;
    //Move Spiral Up
    p.y+=-t*m-m*0.5;
    
    //Counter the rotation
    p*=rot(t*pi*2.+pi/2.);
    
    //Polar Map
    float theta = atan(p.y,p.x);
    theta = clamp(theta,-pi,pi);
    p = vec2(theta,length(p));
    
    //Create Spiral
    p.y+=theta*scale*0.5;

    //Duplicate Line outwards to fill spiral
    float py = p.y;
    float id = floor((p.y+m*0.5)/m);
    p.y = lim(p.y,m,0.,floor(t));
    
    //float hel = -(theta+pi)/(2.*pi)+id;
    
    //Line SDF of the spiral
    float a = abs(p.y)-size;
    
    //Calcuate moving outer spiral segment
    p.y = py;
    p.x -= pi;
    p.y -= (floor(t)+1.5)*m-m*0.5;
    float b = max(abs(p.y),abs(p.x)-(pi*2.)*fract(t)+size );
    
    //The unrolled Line SDF
    a = min(a,b-size);
    b = abs(po.y)-size;
    b = max(po.x,b);
    //if(b<a) hel = po.x-(pi*-t*(m+m*(-t-1.))-3.);
    //else hel*=id;
    
    //Combine Them
    a = min(a,b);

    return a;
}
vec3 map(vec3 p){
    vec2 a = vec2(1);
    vec2 b = vec2(1);
    float c = 0.;
    float t = time; //Try reversing :)

    float size = 0.062; //Thickness of spiral curls
    float scale = size-0.01; //Space between spiral curls
    float m = pi*scale;
    float expand = 0.04; //Corner Rounding Amount 

    float m2 = size*6.0;
    float ltime = 10.; //How often the spirals rolls repeat
    
    
    //Move everything upwards so it stays in frame
    p.y-=(t/ltime)*size*6.;
    
    //small offset for framing
    p.x-=3.; 
    
    float width = 0.5; //Lane Width
    float count = 6.; //Number of spirals (x2)
    
    float modwidth = width*2.0+0.04+0.06;
    
    float id3 = idlim(p.z,modwidth,-count,count);
    t+=h11(id3*0.76)*8.0;
    p.z = lim(p.z,modwidth,-count,count);
    
    float to = t;
    vec3 po = p;

    float id = 0.;

    //Spiral 1
    float stack = -floor(t/ltime);
    float id2 = idlim2(p.y,m2,stack);
    t+=id2*ltime;
    p.y = lim2(p.y,m2,stack);
    a.x = spiral(p.xy,t,m,scale,size,expand);
    //a.y = id2*3.-2.;
    c = a.x;
    a.x = min(a.x,max(p.y+size*5.,p.x));//Artifact Removal
    
    //Spiral 2
    p = po;
    t = to;
    p.y+=size*2.0;
    t-=ltime/3.0;
    stack = -floor(t/ltime);
    id2 = idlim2(p.y,m2,stack);
    t+=id2*ltime;
    p.y = lim2(p.y,m2,stack);
    
    b.x = spiral(p.xy,t,m,scale,size,expand);
    //b.y = id2*3.-1.;
    c = min(c,b.x);
    a=(a.x<b.x)?a:b;
    a.x = min(a.x,max(p.y+size*5.,p.x));//Artifact Removal
    
    //Spiral 3
    p = po;
    t = to;
    p.y+=size*4.0;
    t-=2.*ltime/3.0;
    stack = -floor(t/ltime);
    id2 = idlim2(p.y,m2,stack);    
    t+=id2*ltime;
    p.y = lim2(p.y,m2,stack);
    b.x = spiral(p.xy,t,m,scale,size,expand);
    //b.y = id2*3.;
    c = min(c,b.x);
    a=(a.x<b.x)?a:b;
    a.x = min(a.x,max(p.y+size*5.,p.x)); //Artifact Removal
    
    
    a.x = ext(po.yzx,a.x,width-expand*0.5+0.02)-expand;
    c = ext(po.yzx,c,width-expand*0.5+0.02)-expand;
    
    //Intersection distance to plane between each lane
    b.x = diplane(po ,vec3(modwidth), rdg); //Artifact Removal
    b.y = 0.;
    
    //a.y-=10.0;
    //a.y+=h11(id3);
    
    a=(a.x<b.x)?a:b; //Artifact Removal
    
    return vec3(a,c);
}
vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void render( out vec4 glFragColor){

    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    float t = time;
    float px = 8./resolution.y;
    vec3 col = vec3(0);

    vec3 ro = vec3(5,1.8,-12)*1.2;
    ro.zx*=rot(0.09);
    
    //Mouse control
    //if(mouse*resolution.xy.z>0.5){
    //ro.yz*=rot(0.5*(mouse*resolution.xy.y/resolution.y-0.5));
    //ro.zx*=rot(-0.5*(mouse*resolution.xy.x/resolution.x-0.5));
    //}
    //Camera Setup
    vec3 lk = vec3(-2.5,0.,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*2.0+uv.x*r+uv.y*cross(f,r));  
    rdg = rd;

    vec3 p = ro;
    vec3 d;
    float dO = 0.;
    bool hit = false;
    
    //Raymarcher
    for(float i = 0.; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x;
        if(d.x<0.001||i==STEPS-1.0){
            hit = true;
            break;
        }
        if(dO>MDIST){
            dO = MDIST;
            break;
        }
    }
    //Color Surface
    if(hit&&d.y!=0.){
        vec3 ld = normalize(vec3(0.5,0.4,0.9));
        vec3 n = norm(p);
        vec3 r = reflect(rd,n);
        rdg = ld;
        float shadow = 1.;
        for(float h = 0.09; h<7.0;){
            vec3 dd = map(p+ld*h+n*0.005);
            if(dd.x<0.001&&dd.y==0.0){break;}
            if(dd.x<0.001){shadow = 0.0; break;}
            shadow = min(shadow,dd.z*30.0);
            h+=dd.x;
        }
        shadow = max(shadow,0.8);

        #define AO(a,n,p) smoothstep(-a,a,map(p+n*a).z)
        float ao = AO(0.05,n,p)*AO(.1,n,p);
        ao = max(ao,0.1);
        n.xz*=rot(4.*pi/3.);
        col = n*0.5+0.5;
        col = col*shadow;
        col*=ao;

    }
    //Color Background
    else{
        col = mix(vec3(0.355,0.129,0.894),vec3(0.278,0.953,1.000),clamp((rd.y+0.05)*2.0,-0.15,1.5));
    }
    //Gamma Approximation
    col = sqrt(col);
    glFragColor = vec4(col,1.0);  
}

//External AA (check render function for usual code)
#define ZERO min(0.0,time)
void main(void) {
    float px = 1.0/AA; vec4 col = vec4(0);
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
