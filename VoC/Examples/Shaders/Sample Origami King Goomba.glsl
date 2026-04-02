#version 420

// original https://www.shadertoy.com/view/Wlsyzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// raymarching based from https://www.shadertoy.com/view/wdGGz3
// The modeling is based on simple plane distance and created a useful custom box distance function that is easy for me to model.
#define USE_MOUSE 0
#define MAX_STEPS 200
#define MAX_DIST 80.
#define SURF_DIST .002
#define GOOMBA_THICKNESS 0.05
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec4 combine(vec4 val1, vec4 val2 ){
    return (val1.w < val2.w)?val1:val2;
}

float customBoxDist(vec3 p, vec4 btm, vec4 top, vec4 rt, vec4 lt, vec4 fw, vec4 b) {
    float p1 = dot(p,btm.xyz) + btm.w;
    float p2 = dot(p,top.xyz) + top.w;
    float p3 = dot(p,rt.xyz) + rt.w;
    float p4 = dot(p,lt.xyz) + lt.w;
    float p5 = dot(p,fw.xyz) + fw.w;
    float p6 = dot(p,b.xyz) + b.w;
    float d = max(-p1,max(-p2,max(-p3,max(-p4,max(-p5,-p6)))));
    return d;
}

// 2D distance box https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec3 origamiPattern(vec2 p, vec3 col, vec3 colA, vec3 colB) {
    mat2 rot = Rot(radians(45.0));
    float d = sdBox(p*rot,vec2(0.1));
    d = max(-p.x,d);
    col = mix(col,colA,S(d,0.0));
    d = sdBox(p*rot,vec2(0.1));
    d = max(p.x,d);
    col = mix(col,colB,S(d,0.0));
    return col;
}

vec3 background(vec2 p, vec3 col){
    p*=2.0;
    p.x+=sin(time*0.5)*1.0;
    vec2 prevP = p;
    vec3 colA = vec3(0.5,0.7,0.8)*1.05;
    vec3 colB = vec3(0.4,0.6,0.7)*1.15;
    
    p.x = mod(p.x,0.29)-0.145;
    p.y = mod(p.y,0.29)-0.145;
    
    col = origamiPattern(p,col,colA,colB);
    p = prevP;
    
    p.x+=0.145;
    p.y+=0.145;
    p.x = mod(p.x,0.29)-0.145;
    p.y = mod(p.y,0.29)-0.145;
    
    col = origamiPattern(p,col,colA,colB);
    
    return col;
}

vec3 floorMat(vec2 p, vec3 col){
    p*=0.3;
    vec2 prevP = p;
    vec3 colA = vec3(0.3,0.5,0.3);
    vec3 colB = vec3(0.3,0.5,0.3)*0.9;
    
    p.x = mod(p.x,0.28)-0.14;
    p.y = mod(p.y,0.28)-0.14;
    
    col = origamiPattern(p,col,colA,colB);
    p = prevP;
    
    p.x+=0.14;
    p.y+=0.14;
    p.x = mod(p.x,0.28)-0.14;
    p.y = mod(p.y,0.28)-0.14;
    
    col = origamiPattern(p,col,colA,colB);
    
    return col;
}

float goombaDist1(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,0.5); // btm
    vec4 a2 = vec4(-3.0,-size,0.0,1.5); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.2); // right     
    vec4 a4 = vec4(-size,1.0,0.0,0.3); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist2(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,0.5); // btm 
    vec4 a2 = vec4(0.0,-size,0.0,1.9); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.7); // right      
    vec4 a4 = vec4(-size,0.0,0.0,0.7); // left         
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward              
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist3(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,0.5); // btm
    vec4 a2 = vec4(-0.5,-size,0.0,0.3); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.5); // right      
    vec4 a4 = vec4(-size,0.7,0.0,0.75); // left           
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward            
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist4(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(-0.7,size,0.0,0.3); // btm
    vec4 a2 = vec4(0.0,-size,0.0,0.3); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.4); // right      
    vec4 a4 = vec4(-size,0.0,0.0,0.0); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward            
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist5(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,0.5); // btm
    vec4 a2 = vec4(0.0,-size,0.0,0.3); // top   
    vec4 a3 = vec4(size,0.0,0.0,0.2); // right       
    vec4 a4 = vec4(-size,0.0,0.0,0.2); // left           
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward               
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return  customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist6(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,0.3); // btm
    vec4 a2 = vec4(-1.0,-size,0.0,0.04); // top   
    vec4 a3 = vec4(size,0.0,0.0,0.1); // right        
    vec4 a4 = vec4(-size,0.0,0.0,0.1); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward               
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist7(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,0.3); // btm
    vec4 a2 = vec4(0.0,-size,0.0,0.105); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.08); // right       
    vec4 a4 = vec4(-size,0.0,0.0,0.08); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward               
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist8(vec3 p) {
    float size = 2.0;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,-1.0); // btm
    vec4 a2 = vec4(-size*2.0,-size,0.0,3.0); // top  
    vec4 a3 = vec4(size,-size*0.5,0.0,1.0); // right     
    vec4 a4 = vec4(-size,1.0,0.0,1.0); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist9(vec3 p) {
    float size = 1.5;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(-0.3,size,0.0,-0.8); // btm
    vec4 a2 = vec4(0.5,-size,0.0,1.0); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.7); // right     
    vec4 a4 = vec4(-size,-1.5,0.0,1.5); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist10(vec3 p) {
    float size = 2.0;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,-1.4); // btm
    vec4 a2 = vec4(-size*2.0,-size,0.0,2.0); // top  
    vec4 a3 = vec4(size,-size*0.5,0.0,1.0); // right     
    vec4 a4 = vec4(-size,1.0,0.0,1.0); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float goombaDist11(vec3 p) {
    float size = 2.0;
    float thickness = GOOMBA_THICKNESS;
    vec4 a1 = vec4(0.0,size,0.0,-1.6); // btm
    vec4 a2 = vec4(0.0,-size,0.0,2.0); // top  
    vec4 a3 = vec4(size,0.0,0.0,0.33); // right     
    vec4 a4 = vec4(-size,0.0,0.0,0.33); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float floorDist(vec3 p) {
    float size = 1.0;
    
    vec4 a1 = vec4(0.0,size,0.0,0.0); // btm
    vec4 a2 = vec4(0.0,-size,0.0,0.05); // top  
    vec4 a3 = vec4(size,0.0,0.0,1.0); // right     
    vec4 a4 = vec4(-size,0.0,-size*0.5,1.0); // left          
    vec4 a5 = vec4(0.0,0.0,-size,1.0); // foward
    vec4 a6 = vec4(0.0,0.0,size,1.0); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

vec4 goomba(vec3 p) {
    vec3 prevP = p;
    
    // face1
    p.x = abs(p.x);
    p.x-=0.6;
    float g1 = goombaDist1(p);
    p = prevP;
    float g2 = goombaDist2(p);
    float resG = min(g1,g2);
    
    vec4 res1 = vec4(vec3(0.7,0.38,0.0),resG*0.5);
        
    // kind of chin, don't know what we call this part.
    p.x = abs(p.x);
    p.x-=0.3;
    
    mat3 rot = matRotateX(radians(-20.0));
    
    g1 = goombaDist3((p-vec3(0.0,0.0,0.2))*rot);
    resG = g1;
    p = prevP;
    vec4 res2 = vec4(vec3(0.7,0.38,0.0),resG*0.5);
    
    // body
    p.x = abs(p.x);
    p.x-=0.4;
    g1 = goombaDist4(p-vec3(0.0,-0.4,0.1));
    p = prevP;
    g2 = goombaDist5(p-vec3(0.0,-0.4,0.1));
    p = prevP;
    resG = min(g1,g2);
    vec4 res3 = vec4(vec3(0.9,0.8,0.5),resG*0.5);
    
    // legs
    p*=0.8;
    p.x = abs(p.x);
    p.x-=0.4;
  
    p.x = abs(p.x);
    p.x-=0.16;
    g1 = goombaDist6(p-vec3(0.0,-0.5,0.05));
    
    p.x+=0.12;
    g2 = goombaDist7(p-vec3(0.0,-0.5,0.05));
    resG = min(g1,g2);
    vec4 res4 = vec4(vec3(0.5,0.2,0.0),resG*0.5);
    p = prevP;
    
    // teeth
    p.x*=2.0;
    p.x = abs(p.x);
    p.x-=0.95;
    g1 = goombaDist8(p-vec3(0.0,-0.7,0.1));
    resG = g1;
    vec4 res5 = vec4(vec3(1.0),resG*0.5);
    p = prevP;
    
    // eyebrow
    p.x = abs(p.x);
    p.x-=0.5;
    g1 = goombaDist9(p-vec3(0.0,0.5,0.1));
    resG = g1;
    vec4 res6 = vec4(vec3(0.3),resG*0.5);
    p = prevP;
    
    // eye
    p.x = abs(p.x);
    p.x -=0.3;
    p.y -= 0.65;
    p.x*=0.9;
    p.y*=1.5;
    p.y = abs(p.y);
    p.y+=0.55;
    g1 = goombaDist10(p-vec3(0.0,0.0,0.1));
    p = prevP;
    p.x = abs(p.x);
    p.x -=0.3;
    p.y -= 0.6;
    g2 = goombaDist11(p-vec3(0.0,-0.85,0.1));
    resG = min(g1,g2);
    vec4 res7 = vec4(vec3(1.0),resG*0.5);
    p = prevP;
    
    // eye ball
    p.x*=2.0;
    p.y*=0.8;
    p.x = abs(p.x);
    p.x -=0.6;
    g1 = goombaDist11(p-vec3(0.0,-0.37,0.13));
    resG = g1;
    vec4 res8 = vec4(vec3(0.1),resG*0.5);
    
    return combine(combine(combine(combine(combine(combine(combine(res1,res2),res3),res4),res5),res6),res7),res8);
}

float fflowerDist1(vec3 p) {
    float size = 3.5;
    float thickness = GOOMBA_THICKNESS;
    
    vec4 a1 = vec4(0.0,size,0.0,0.5); // btm
    vec4 a2 = vec4(-2.0,-size,0.0,1.0); // top  
    vec4 a3 = vec4(size,0.0,0.0,1.0); // right     
    vec4 a4 = vec4(-size,0.0,0.0,0.75); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float fflowerDist2(vec3 p) {
    float size = 3.5;
    float thickness = GOOMBA_THICKNESS;
    
    vec4 a1 = vec4(0.0,size,0.0,1.86); // btm
    vec4 a2 = vec4(0.0,-size,0.0,1.86); // top  
    vec4 a3 = vec4(size,0.0,0.0,1.0); // right     
    vec4 a4 = vec4(-size,0.0,0.0,0.8); // left          
    vec4 a5 = vec4(0.0,0.0,-size,thickness); // foward
    vec4 a6 = vec4(0.0,0.0,size,thickness); // back
    return customBoxDist(p,a1,a2,a3,a4,a5,a6)*0.6;
}

float leafDist(vec3 p) {
    vec3 prevP = p;
    p.x*=0.9;
    p.x = abs(p.x);
    p.x -=0.5;
    p.y = abs(p.y);
    p.y -= 0.1;
    float f1 = fflowerDist1(p);
    p = prevP;
    p.x*=0.9;
    float f2 = fflowerDist2(p);
    
    return min(f1,f2);
}

vec4 fflower(vec3 p) {
    vec3 prevP = p;
    float f1 = leafDist(p-vec3(0,0.6,0.0));
    float resF = f1;
    vec4 res1 = vec4(vec3(0.9,0.0,0.0),resF*0.5);
    p = prevP;
    
    p.xy*=1.3;
    f1 = leafDist(p-vec3(0,0.8,0.05));
    resF = f1;
    vec4 res2 = vec4(vec3(1.0,0.6,0.0),resF*0.5);
    p = prevP;
    
    p.xy*=1.8;
    f1 = leafDist(p-vec3(0,1.1,0.1));
    resF = f1;
    vec4 res3 = vec4(vec3(1.0,0.9,0.0),resF*0.5);
    p = prevP;
    
    // eye
    p.x*=5.0;
    p.y*=4.0;
    p.x = abs(p.x);
    p.x-=1.0;
    f1 = fflowerDist2(p-vec3(0,2.5,0.15));
    resF = f1;
    vec4 res4 = vec4(vec3(0.1),resF*0.5);
    p = prevP;
    
    // branch
    p.x*=2.5;
    f1 = fflowerDist2(p-vec3(0,-0.15,-0.05));
    resF = f1;
    vec4 res5 = vec4(vec3(0.5,0.9,0.0),resF*0.5);
    p = prevP;
    
    // leaf
    mat3 rot = matRotateZ(radians(50.0));
    p.y+=0.2;
    p.x = abs(p.x);
    p.x -=0.5;
    p*=rot;
    p.x *=1.8;
    p.y *=1.2;
    
    p.xy = abs(p.xy);
    p.xy -= vec2(0.2,0.1);
    
    f1 = fflowerDist1((p-vec3(0,0.0,-0.05)));
    resF = f1;
    vec4 res6 = vec4(vec3(0.4,0.9,0.0),resF*0.5);
    
    return combine(combine(combine(combine(combine(res1,res2),res3),res4),res5),res6);
}

vec4 GetDist(vec3 p) {
    
    vec3 prevP = p;
    
    // ground
    p.xz*=0.2;
    p.xz = abs(p.xz);
    p.xz -=1.;

    float _floor = floorDist(p+vec3(0.0,0.7,0.0));
    vec4 f = vec4(floorMat(prevP.xz,vec3(0.5,0.7,0.8)),_floor*0.6);
    
    // goomba
    p = prevP;
    float c = 2.0;
    p.z+=3.0;
    float l = 2.0;
    p.z += -c*clamp(round(p.z/c),-l,l);
    
    float k = sin(time*6.0)*0.1;
    c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    p.xz*=m;
    
    mat3 rot = matRotateX(radians(sin(time*6.0)*5.0));
    vec4 g = goomba((p -vec3(0.0,0.25,0.0))*rot);
    
    // fire flower
    p = prevP;
    p.z+=2.5;
    p.x=abs(p.x);
    p.x-=3.0;
    vec4 ff = fflower(p);
    
    vec4 model = combine(f,combine(g,ff));
    return model;
}

vec4 RayMarch(vec3 ro, vec3 rd) {
    vec4 dO= vec4(0.0);
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO.w;
        vec4 dS = GetDist(p);
        dO.w += dS.w;
        dO.xyz = dS.xyz;
        if(dO.w>MAX_DIST || dS.w<SURF_DIST) break;
    }
    
    return dO;
}

float shadowMap(vec3 ro, vec3 rd){
    float h = 0.0;
    float c = 0.001;
    float r = 1.0;
    float shadow = 0.5;
    for(float t = 0.0; t < 30.0; t++){
        h = GetDist(ro + rd * c).w;
        if(h < 0.001){
            return shadow;
        }
        r = min(r, h * 16.0 / c);
        c += h;
    }
    return 1.0 - shadow + r * shadow;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).w;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).w,
        GetDist(p-e.yxy).w,
        GetDist(p-e.yyx).w);
    
    return normalize(n);
}

vec2 GetLight(vec3 p) {
    vec3 lightPos = vec3(2,8,3);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l).w;
    
    float lambert = max(.0, dot( n, l))*0.1;
    float shadow = shadowMap(p + n * 0.001, l);

    return vec2((lambert+dif),max(0.9, shadow)) ;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 4, -5);
    #if USE_MOUSE == 1
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    #else
    ro.xz *= Rot(radians(180.0)+radians(sin(time*0.5)*60.0));
    ro.yz *= Rot(radians(30.0));
    #endif
    
    vec3 rd = R(uv, ro, vec3(0,1,0), 1.);

    vec4 d = RayMarch(ro, rd);
    
    if(d.w<MAX_DIST) {
        vec3 p = ro + rd * d.w;
    
        vec2 dif = GetLight(p);
        col = vec3(dif.x)*d.xyz;
        col *= dif.y;
        
    } else {
        // background
        col = vec3(0.5,0.7,0.8);
        col = background(uv,col)*1.2;
    }
    
    glFragColor = vec4(col,1.0);
}
