#version 420

// original https://www.shadertoy.com/view/NsjBDW

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarching based from https://www.shadertoy.com/view/wdGGz3
// Gyroid inspiration! https://www.youtube.com/watch?v=b0AayhCO7s8
#define MAX_STEPS 80
#define MAX_DIST 32.
#define SURF_DIST .001
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define MATERIAL0 0
#define MATERIAL1 1
#define SPEED 2.0
#define ZERO (min(frames,0))

vec2 combine(vec2 val1, vec2 val2 ){
    return (val1.x < val2.x)?val1:val2;
}

float B3D(vec3 p, vec3 s) {
    p = abs(p)-s;
    return max(max(p.x,p.y),p.z);
}

vec3 path(float z)
{
    vec3 p = vec3(sin(z) * .6, cos(z * .3), z);
    p.x+=sin(z*0.12)*2.0;
    return p;
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    
    p.xy -= path(p.z).xy;
    
    p.z += time*SPEED;
    
    float d = -length(p.xy) + 3.0;
    d = abs(d)-0.1;
    
    p.yz*=Rot(time*0.0001);
    p*=3.0;
    float d2 = abs(0.5*dot(sin(p),cos(p.yzx))/3.0)-0.15;
    p = prevP;
    
    p.z += time*SPEED;
    p.yz*=Rot(time*0.0001);
    p*=3.5;
    float d3 = abs(0.5*dot(sin(p),cos(p.yzx))/3.5)-0.1;
    p = prevP;
    
    return combine(vec2(0.7*max(-d2,d),MATERIAL0),vec2(0.7*max(-d3,d),MATERIAL1));
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
    for( int i=ZERO; i<4; i++ )
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
    float occ = calcOcclusion(p,n);
    vec3 diffCol = vec3(0.0);
    vec3 lightDir = normalize(vec3(p.x,p.y,-2));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff*occ;
    diffCol += col*vec3(0.9)*skyDiff*occ;
    diffCol += col*vec3(0.7)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 20.)*occ; // spec
        
    return diffCol;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    if(mat == MATERIAL0){
        col = diffuseMaterial(n,rd,p,vec3(0.8,0.3,0.3));
    } else if(mat == MATERIAL1) {
        col = diffuseMaterial(n,rd,p,vec3(0.3,0.3,0.8));
    }
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t = time*SPEED;
    vec3 ro = path(t+1.5);
 
    vec3 rd = R(uv, ro, vec3(0,0.0,0), 1.0);
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(1.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
        col *= exp( -0.0001*d.x*d.x*d.x*d.x );//fog
    } else {
        col = vec3(0.0);   
    }
    
    // gamma correction
    col = pow( col, vec3(0.9545) );    
    
    glFragColor = vec4(col,1.0);
}
