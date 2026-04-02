#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tjGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Parameters 
#define FUZZ 0.99
#define PHASELENGTH 2.50
#define RECURSION_LEVEL 7
#define NUM_STRANDS 3.0
#define TR_RATIO 0.8
#define RADIUS_FACTOR 0.38
#define RIBBONRADIUS 0.012

// comment/uncomment the following defines to toggle effects
//#define FLIPFLOP
#define VARIANCE
//#define WOBBLE

#define PI 3.14159265359
#define TWOPI 6.28318530718
#define EPSILON 0.0005
#define KEPLER_MAXITER 2
#define MAXSTEPS 30
#define MAXDIST 55.0
#define PHASE mod(time/PHASELENGTH,1.0)
#define PHASEN floor(time/PHASELENGTH)

mat4 buildtransform(vec3 point, float off, vec3 trans, bool isNeg) {
    vec3 zaxis = normalize(point);
    vec3 xaxis = normalize(vec3(zaxis.z, 0.0, -zaxis.x));
    if (!isNeg) {
        xaxis *= -1.0;
        zaxis *= -1.0;
        off *= -1.0;
    }
    vec3 yaxis = cross(zaxis, xaxis);
    return mat4(xaxis.x, yaxis.x, zaxis.x, 0,
                xaxis.y, yaxis.y, zaxis.y, 0,
                xaxis.z, yaxis.z, zaxis.z, 0,
                dot(xaxis,trans),dot(yaxis,trans),dot(zaxis,trans)+off,1);
}

   
float solveKeplerHalley(float e,float M) {
    float E =clamp(M+PI,0.00,PI);
    int i=0;
    while(i<KEPLER_MAXITER) {
        float esinE = e*sin(E);
        float k0mM = (E-esinE)-M;
        float k1 = (1.0-e*cos(E));
        E -= (2.0*k0mM*k1)/(2.0*k1*k1-k0mM*(esinE));
        i++;
    }
    return E;
}

float solveKepler(float e, float M) {
    //http://www.jgiesen.de/kepler/kepler.html
    if (e >= 1.0) {
        return solveKeplerHalley(e,M);
    }
    float E = (e < 0.8 ? M : PI);
    float F = E - e*sin(M)-M;
    int i = 0;
    while (i < KEPLER_MAXITER) {
        E -= F/(1.0 - e*cos(E));
        F = E - e*sin(E) - M;
        i++;
    }
    return E;
}

struct HelixHit {
    vec4 p;
    float strand;
    float theta;
};

// Computes the closest point to p on a Helix (R,T) with n strands.
// The returned struct contains the closest point, the strand and the point Theta on the helix.
HelixHit ClosestPointHelix(vec4 p, float R, float T, float n_helices) {
    // Nievergelt 2009
    // doi: 10.1016/j.nima.2008.10.006
    
    //Helix: H(Theta) = [R*cos(Theta), R*sin(Theta), T*Theta]
    //Point: D = (u, v, w) = [r * cos(delta), r * sin(delta), w]
    HelixHit res;
    float delta = atan(p.y, p.x);
    float r = length(p.yx);
    float kt = ((p.z/T)-delta)/TWOPI;
    float inv_n_helices = 1.0/n_helices;
    float n = floor((fract(kt) + 0.5*inv_n_helices)/inv_n_helices);
    float s_offset = -n*inv_n_helices*TWOPI;
    float dktp = delta + round(kt-n*inv_n_helices) * TWOPI; 
    float M = PI + (p.z/T) + s_offset - dktp;
    float e = (r*R)/(T*T);
    float E = solveKepler(e,M);
    float Theta = E - PI + dktp;
    res.theta = (Theta-s_offset);
    res.strand=n;
    #ifdef WOBBLE
        R*= 1.0+0.2*sin(0.01*time/(abs(T))+res.theta*3.0);
    #endif
    res.p = vec4(R*cos(Theta), R*sin(Theta), res.theta*T,1.0);

    return res;
}

float getT(float R, float baseRot, float subphase, bool isNeg) {
    float T = tan(baseRot + pow(subphase,6.0) * (PI*0.5 - baseRot))*R;
    T *= (isNeg ? -1.0 : 1.0);
    return T;
}

struct Result {
    float dist;
    vec4 n;
};

Result HelixRecursive(vec4 pos, float R, float startTR, float Rmult, int iter, float strands) {
    HelixHit hit;
    float baseRot = atan(startTR);
    float phase = PHASE;
    
    mat4 transform = mat4(1.0);
    
    R = R/mix(1.0,Rmult,phase);
    transform[3][0] = pow(phase,1.3)*R;
    
    float rot = 0.5*PI;
    vec2 vrot = vec2(sin(rot),cos(rot));
    
    transform[1].y = vrot.y;
    transform[1].z = -vrot.x;
    transform[2].yz = vrot.xy;
    
    float frac = (1.0/float(iter));
    float subphase = 1.0 - (1.0-phase)*frac;
    
    bool flipflop = false;
    #ifdef FLIPFLOP
        flipflop = true;
    #endif
    
    bool isNeg = flipflop&&(int(PHASEN)%2==0);
    for (int i=0; i<iter-1; i++) {
        float T = getT(R,baseRot,subphase,isNeg);

        subphase -= frac;
        
        hit = ClosestPointHelix(transform*pos,R,T,strands);     
        vec3 lookDir = (vec3(hit.p.y,-hit.p.x,-T));
        float offset = -(hit.theta/TWOPI)*sqrt((T*T+R*R) * 4.0*PI*PI);
        #ifdef MOVE
            offset -= (i>0?abs(PHASE*T):0.0);
        #endif
       
        transform = buildtransform(lookDir,offset,-hit.p.xyz,isNeg) * transform;
            
        #ifdef VARIANCE
        Rmult *= 1.0-mod(hit.strand,strands)*(0.6/strands);
        #endif
        
        R *= Rmult;
        isNeg = flipflop&&!isNeg;
    }
    float T = getT(R,baseRot,subphase,isNeg);
    
    vec4 p = transform*pos;
    hit = ClosestPointHelix(p,R*sqrt(phase),T,strands);
    
    mat4 inv = inverse(transform);
    Result res;
    res.dist = distance(pos,inv * hit.p)-RIBBONRADIUS;
    res.n = inv * normalize(p-hit.p);
    return res;
}

Result ED(vec4 p) {
    float r1 = 7.0;
    return HelixRecursive(p,r1,TR_RATIO,RADIUS_FACTOR,RECURSION_LEVEL,NUM_STRANDS);
}

vec3 getColor(vec4 n) {
    float c = max(0.0,dot(n, normalize(vec4(3,8,2,0))));
    float c2 = max(0.0,dot(n, normalize(vec4(3,-8,-1,0))));
    return vec3(c*0.7+c2*0.3,0,c*0.3+c2*0.7);
}

vec3 raymarch(vec4 orig, vec4 dir) {
    float dist = 0.0;
    float minDist = 1e9;
    int steps = 0;
    vec4 pos = orig;
    Result res;
    res.dist = 1e9;
    
    while (dist < MAXDIST && steps < MAXSTEPS && res.dist >= EPSILON) {
        res = ED(pos);
        minDist = min(minDist,res.dist);
        
        dist += FUZZ*res.dist;
        
        pos = orig + dist*dir;
        steps++;
    }
    if (res.dist < EPSILON) {
         float shadow = (1.0/float(steps))*10.0;
        shadow *= 1.0-pow(dist/MAXDIST,5.0);
            
        return getColor(res.n)*(shadow);   
    }
    return vec3(0,0,0);
    //return vec3(1,1,1) * (1.0-pow(float(steps)/float(MAXSTEPS),0.5)) * 0.5;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv =(gl_FragCoord.xy-.5*resolution.xy)/resolution.x * PI * 0.5;
    
    vec4 raydir = normalize(vec4(sin(uv.x),1.0,-sin(uv.y),0.0));
    vec4 rayorig = vec4(20.0,0.0,-0.0,1);
    
    vec2 rot = vec2(0.3,0.1)*(mouse*resolution.xy.xy / resolution.xy - 0.5) * 2.0 * PI;
    //if (mouse*resolution.xy.x <= 0.0 && mouse*resolution.xy.y <= 0.0)
    //    rot = vec2(0,0);
    rot += vec2(-0.5,1.0)*PI;
    vec2 sins = sin(rot);
    vec2 coss = cos(rot);
    float ry = coss.y*raydir.y+sins.y*raydir.z;
    raydir =  vec4(coss.x*raydir.x-sins.x*ry, sins.x*raydir.x+coss.x*ry, sins.y*raydir.y-coss.y*raydir.z,0.0);
    
    glFragColor = vec4(raymarch(rayorig, raydir),1.0);
}
