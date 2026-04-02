#version 420

// original https://www.shadertoy.com/view/7ldXDl

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// raymarching based from https://www.shadertoy.com/view/wdGGz3
#define USE_MOUSE 0
#define MAX_STEPS 64
#define MAX_DIST 64.
#define SURF_DIST .0001
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p.x)-s.x,abs(p.y)-s.y)
#define ZERO (min(frames,0))
#define TRADITIONAL_ASSET0_MAT 0
#define FRAME_MAT0 4
#define FRAME_MAT1 5
#define FRAME_MAT2 6
#define FRAME_MAT3 7
#define FRAME_MAT4 8

// by Dave_Hoskins
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 combine(vec2 val1, vec2 val2 ){
    return (val1.x < val2.x)?val1:val2;
}

float B3D(vec3 p, vec3 s) {
    p = abs(p)-s;
    return max(max(p.x,p.y),p.z);
}

float doorFrame(vec3 p){
    vec3 prevP = p;
    
    p.x = abs(p.x)-0.5;
    float d = B3D(p,vec3(0.02,0.8,0.02));
    p = prevP;
    
    p.y = abs(p.y)-0.78;
    float d2 = B3D(p,vec3(0.5,0.02,0.02));
    
    d = min(d,d2);
    return d;
}

float doorFrameWire(vec3 p){
    p.y-=0.27;
    vec3 prevP = p;
    
    p.y = mod(p.y,0.2)-0.1;
    float d = B3D(p,vec3(0.5,0.01,0.01));
    p = prevP;
    
    p.x = mod(p.x,0.2)-0.1;
    float d2 = B3D(p,vec3(0.01,0.6,0.01));
    d = min(d,d2);
    p = prevP;
    return max(B3D(p,vec3(0.5,0.51,0.03)),d);
}

vec2 doorModel1(vec3 p){
    vec3 prevP = p;
    
    float d = doorFrame(p);
    float d2 = doorFrameWire(p);
    d = min(d,d2);
    
    vec2 model = vec2(d,FRAME_MAT0);
    
    d = B3D(p-vec3(0.0,0.275,0.0),vec3(0.5,0.5,0.001));
    vec2 model2 = vec2(d,FRAME_MAT1);
    
    d = B3D(p-vec3(0.0,-0.5,0.0),vec3(0.5,0.28,0.001));
    vec2 model3 = vec2(d,FRAME_MAT2);
    
    return combine(model,combine(model2,model3));
}

vec2 doorModel2(vec3 p){
    vec3 prevP = p;
    
    float d = doorFrame(p);
    float d2 = doorFrameWire(p);
    
    p.y-=0.27;
    d2 = max((length(abs(p.xy))-0.4),d2);
    d = min(d,d2);
    
    vec2 model = vec2(d,FRAME_MAT0);
    
    p = prevP;
    d = B3D(p-vec3(0.0,0.275,0.0),vec3(0.5,0.5,0.001));
    p.y-=0.27;
    d = max((length(abs(p.xy))-0.4),d);
    
    vec2 model2 = vec2(d,FRAME_MAT1);
    
    p = prevP;
    d = B3D(p-vec3(0.0,-0.5,0.0),vec3(0.5,0.28,0.001));
    vec2 model3 = vec2(d,FRAME_MAT2);
    
    p = prevP;
    d = B3D(p-vec3(0.0,0.275,0.0),vec3(0.5,0.5,0.001));
    p.y-=0.27;
    d = max(-(length(abs(p.xy))-0.4),d);
    
    vec2 model4 = vec2(d,FRAME_MAT3);    
    
    return combine(model,combine(model2,combine(model3,model4)));
}

vec2 doorModel3(vec3 p){
    vec3 prevP = p;
    
    float d = doorFrame(p);
    p.y-=0.1;
    p.y = mod(p.y,0.2)-0.1;
    float d2 = B3D(p,vec3(0.5,0.01,0.01));
    d = min(d,d2);
    
    p = prevP;
    p.x = mod(p.x,0.2)-0.1;
    d2 = B3D(p,vec3(0.01,0.8,0.01));
    d = min(d,d2);
    
    p = prevP;
    d = max(B3D(p,vec3(0.5,0.78,0.03)),d);
    
    vec2 model = vec2(d,FRAME_MAT0);

    d = B3D(p,vec3(0.48,0.76,0.001));
    vec2 model2 = vec2(d,FRAME_MAT1);
    
    return combine(model,model2);
}

vec2 openDoorModel(vec3 p){
    vec3 prevP = p;
    
    float d = doorFrame(p);
    p.x+=0.4;
    float d2 = length(p.xy)-0.035;
    d2 = max(abs(p.z)-0.011,d2);
    d = min(d,d2);
    vec2 model = vec2(d,FRAME_MAT0);
    p = prevP;
    d = B3D(p,vec3(0.48,0.76,0.001));
    vec2 model2 = vec2(d,FRAME_MAT4);
    
    return combine(model,model2);
}

vec2 tatamiFloor(vec3 p){
    vec3 prevP = p;
    float d = B3D(p,vec3(1.0,0.1,5.0));
    vec2 model = vec2(d,-1);
    return model;
}

vec2 doorBlock(vec3 p){
    vec3 prevP = p;
    p.y-=0.1;
    p.x = abs(p.x)-1.0;
    p.xz*=Rot(radians(90.0));
    vec2 model1 = doorModel1(p);
    vec2 model2 = doorModel2(p-vec3(1.0,0.0,0.0));
    vec2 model3 = doorModel3(p-vec3(-1.0,0.0,0.0));
    
    return combine(model1,combine(model2,model3));
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    p.y+=0.8;
    vec2 model = tatamiFloor(p);
    
    p = prevP;
    p.z-=time;
    p.z=mod(p.z,3.0)-1.5;
    vec2 model2 = doorBlock(p);
    
    p = prevP;
    p.y-=0.1;
    p.x = abs(p.x)-(0.75-(sin(time*2.0)*0.2));
    p.z-=time;
    p.z=mod(p.z,4.0)-2.;
    vec2 model3 = openDoorModel(p);
    
    p = prevP;
    p.z-=time;
    p.z=mod(p.z,4.0)-2.;
    float d = B3D(p-vec3(0.0,-0.7,0.0),vec3(1.0,0.03,0.03));
    p.x = abs(p.x)-1.0;
    float d2 = B3D(p,vec3(0.03,1.0,0.03));
    vec2 model4 = vec2(min(d,d2),FRAME_MAT0);
    
    return combine(model, combine(model2,combine(model3,model4)));
}

vec2 RayMarch(vec3 ro, vec3 rd, float side, int stepnum) {
    vec2 dO = vec2(0.0);
    
    for(int i=0; i<stepnum; i++) {
        vec3 p = ro + rd*dO.x;
        vec2 dS = GetDist(p);
        dO.x += dS.x*side;
        dO.y = dS.y;
        
        if(dO.x>MAX_DIST || abs(dS.x)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
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

// https://www.shadertoy.com/view/3lsSzf
float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<3; i++ )
    {
        float h = 0.01 + 0.15*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = GetDist( opos ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 diffuseMaterial(vec3 n, vec3 rd, vec3 p, vec3 col) {
    //float occ = calcOcclusion(p,n);
    vec3 diffCol = vec3(0.0);
    vec3 lightDir = normalize(vec3(1,2,-2));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    //float shadow = step(RayMarch(p+n*0.3,lightDir,1.0, 15).x,0.9);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff;
    diffCol += col*vec3(1.0,1.0,0.9)*skyDiff;
    diffCol += col*vec3(0.3,0.3,0.3)*bounceDiff;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 20.); // spec
        
    return diffCol;
}

vec3 reflectMaterial(vec3 p, vec3 rd, vec3 n) {
    vec3 r = reflect(p+rd*1.6,n);
    vec3 col = r;
    
    return col;
}

float tatami(vec2 p){
    p*=2.0;
    vec2 uv = fract(p)-0.5;
    vec2 prevUV = uv;
    vec2 id = floor(p);
    float n = hash12(id);
    
    float d = 100.0;
    if(n<0.5){
        uv.x-=0.45;
        d = B(uv,vec2(0.05,0.5));
    }
    uv = prevUV;
    uv.y-=0.45;
    float d2 = B(uv,vec2(0.5,0.05));
    return min(d,d2);
}

vec3 tatamiMat(vec2 p, vec3 col){
    float d = tatami(p);
    p.x*=0.1;
    vec2 id = floor(p*500.0);
    float n = hash12(id);
    col = mix(vec3(0.6,0.7,0.6)-(n*n*0.1),vec3(0.15,0.3,0.25)*n,S(d,0.0));
    return col;
}

float texNoise(vec2 p){
    vec2 id = floor(p*500.0);
    float n = hash12(id);
    return n;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    vec3 np = p;
    np.z-=time;
    float nn = texNoise(np.xz);
    if(mat == FRAME_MAT0){
        return diffuseMaterial(n,rd,p,vec3(0.4,0.2,0.1)-(nn*nn*0.1));
    }
    
    if(mat == FRAME_MAT1){
        return diffuseMaterial(n,rd,p,vec3(1.0)-(nn*nn*0.1));
    }
    if(mat == FRAME_MAT2){
        return diffuseMaterial(n,rd,p,vec3(0.8,0.7,0.5)-(nn*nn*0.1));
    }
    if(mat == FRAME_MAT3){
        return diffuseMaterial(n,rd,p,vec3(0.7,0.6,0.4)-(nn*nn*0.1));
    }
    if(mat == FRAME_MAT4){
        np.x = abs(np.x)-(0.75-(sin(time*2.0)*0.2));
        nn = texNoise(np.xz);
        return diffuseMaterial(n,rd,p,vec3(1.2)-(nn*0.05));
    }
    p.z-=time;
    return diffuseMaterial(n,rd,p,tatamiMat(p.xz,col));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec2 m =  mouse*resolution.xy.xy/resolution.xy -.3;
    
    float t = time;

    vec3 ro = vec3(0, 0.0, 1.0);
    #if USE_MOUSE == 1
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    #else
    //ro.yz *= Rot(radians(10.0));
    #endif
    
    vec3 rd = R(uv, ro, vec3(0,0.0,0.0), 0.5);
    rd*=matRotateZ(radians(sin(t*0.5)*15.0));
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(1.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
        col *= exp( -0.038*d.x*d.x*d.x );//fog
    } else {
        col = mix(vec3(0.0),vec3(0.2,0.1,0.3),uv.y);
    }
    
    
    // gamma correction
    col = pow( col, vec3(0.9545) );    
    
    glFragColor = vec4(col,1.0);
}
