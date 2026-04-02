#version 420

// original https://www.shadertoy.com/view/fdfyRH

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
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define ZERO (min(frames,0))

float B3D(vec3 p, vec3 s) {
    p = abs(p)-s;
    return max(max(p.x,p.y),p.z);
}

float dot2( in vec2 v ) { return dot(v,v); }

// https://www.shadertoy.com/view/ftVSDd
float sdSquareStairs( in vec2 p, in float s, in float n )
{
    // constant for a given shape
    const float kS2 = sqrt(2.0);
    float w = 2.0*n+1.0;
    
    // pixel dependent computations
    p = vec2( abs(p.y+p.x), p.y-p.x ) * (0.5/s);

    float x1 = p.x-w;
    float x2 = abs(p.x-2.0*min(round(p.x/2.0),n))-1.0;
    
    float d1 = dot2( vec2(x1, p.y) + clamp(0.5*(-x1-p.y), 0.0, w  ) );
    float d2 = dot2( vec2(x2,-p.y) + clamp(0.5*(-x2+p.y), 0.0, 1.0) );

    return sqrt(min(d1,d2)) *
           sign(max(x1-p.y,(x2+p.y)*kS2)) *
           s*kS2;
}

vec2 GetDist(vec3 p) {
    vec3 prevP2 = p;
    p.xz*=0.9;
    float mask = length(p.xz-vec2(0.,-0.5))-1.39;

    p.y+=time*0.8;
    p.x = abs(p.x)-0.9;
    
    vec3 prevP = p;
    
    p.y = mod(p.y,1.6)-0.8;
    float stepNum = 2.0;
    float s = 0.1;
    float d = sdSquareStairs(p.xy,s,stepNum);
    d = max((abs(p.z)-0.5),d);
    
    float d2 = sdSquareStairs(p.xy-vec2(0.1,-0.1),s,stepNum);
    d = max(-d2,d);
    
    p = prevP;
    p.x*=-1.0;
    p.x+=0.1;
    p.y+=0.7;
    p.z+=0.8;
    p.y = mod(p.y,1.6)-0.8;
    
    d2 = sdSquareStairs(p.xy-vec2(0.1,-0.1),s,stepNum);
    d2 = max((abs(p.z)-0.5),d2);
    
    float d3 = sdSquareStairs(p.xy-vec2(0.2,-0.2),s,stepNum);
    d2 = max(-d3,d2);
    
    d = min(d,d2);
    d = max(mask,d);
    
    p = prevP2;
    
    p.y+=2.0;
    p.y+=time*0.8;
    p.y = mod(p.y,1.6)-0.8;
    p.z+=0.445;
    d2 = B3D(p,vec3(0.65,0.1,1.00));
    d = min(d,d2);
    d = max(mask,d);
    vec2 model = vec2(d,0.0);
    
    return model;
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
    float occ = calcOcclusion(p,n);
    vec3 diffCol = vec3(0.0);
    vec3 lightDir = normalize(vec3(1,2,-2));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    //float shadow = step(RayMarch(p+n*0.3,lightDir,1.0, 15).x,0.9);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff*occ;
    diffCol += col*vec3(1.0,1.0,0.9)*skyDiff*occ;
    diffCol += col*vec3(0.3,0.3,0.3)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 20.); // spec
        
    return diffCol;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    return diffuseMaterial(n,rd,p,vec3(0.9));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec2 m =  mouse*resolution.xy.xy/resolution.xy -.3;
    
    float t = time;

    vec3 ro = vec3(0, 0.0, 2.5);
    #if USE_MOUSE == 1
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    #else
    ro.xz *= Rot(radians(time*20.0));
    #endif
    
    vec3 rd = R(uv, ro, vec3(0,0.0,0.0), 0.5);
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(0.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
        col *= exp( -0.038*d.x*d.x*d.x );//fog
    } else {
        //col = mix(vec3(0.0),vec3(0.2,0.1,0.3),uv.y);
    }
    
    
    // gamma correction
    col = pow( col, vec3(0.9545) );    
    
    glFragColor = vec4(col,1.0);
}
