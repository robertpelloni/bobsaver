#version 420

// original https://www.shadertoy.com/view/Wt2Szt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Parameters
#define outerT 2.9
#define FUZZ 0.75
#define PHASELENGTH 30.0
#define PI 3.14159265359
#define TWOPI 6.28318530718
#define EPSILON 0.005
#define KEPLER_MAXITER 2
#define MAXSTEPS 150
#define MAXDIST 95.0
#define PHASE mod(time/PHASELENGTH,1.0)

vec3 glow = vec3(0);

// https://www.shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

mat4 rotationX( in float angle ) {
    return mat4(    1.0,        0,            0,            0,
                     0,     cos(angle),    -sin(angle),        0,
                    0,     sin(angle),     cos(angle),        0,
                    0,             0,              0,         1);
}

mat4 rotationY( in float angle ) {
    return mat4(    cos(angle),        0,        sin(angle),    0,
                             0,        1.0,             0,    0,
                    -sin(angle),    0,        cos(angle),    0,
                            0,         0,                0,    1);
}

mat4 rotationZ( in float angle ) {
    return mat4(    cos(angle),        -sin(angle),    0,    0,
                     sin(angle),        cos(angle),        0,    0,
                            0,                0,        1,    0,
                            0,                0,        0,    1);
}

mat4 buildtransform(vec3 point, float off, vec3 trans, bool isNeg) {
    vec3 zaxis = normalize(point);
    vec3 xaxis = normalize(vec3(zaxis.z, 0.0, -zaxis.x));
    if (!isNeg && zaxis.x < 0.0) {
        xaxis *= -1.0;
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
    vec4 stepped_p;
    float stepped_theta;
};

// Computes the closest point to p on a Helix (R,T) with n strands.
// The returned struct contains the closest point, the strand and the point Theta on the helix.
HelixHit ClosestPointHelixStep(vec4 p, float R, float T, float n_helices, float stepsize,float offset,float offsetoffsetlol) {
    // Nievergelt 2009
    // doi: 10.1016/j.nima.2008.10.006
    
    //Helix: H(Theta) = [R*cos(Theta), R*sin(Theta), T*Theta]
    //Point: D = (u, v, w) = [r * cos(delta), r * sin(delta), w]
    HelixHit res;
    float delta = atan(p.y, p.x);
    float r = length(p.yx);
    float kt = ((p.z/T)-delta)/TWOPI;
    float inv_n_helices = 1.0/n_helices;
    float n = floor((fract(kt) + 0.5*inv_n_helices)/inv_n_helices -0.5);
    float s_offset = -(n+0.5)*inv_n_helices*TWOPI;
    float dktp = delta + round(kt-(n+0.5)*inv_n_helices) * TWOPI; 
    float M = PI + (p.z/T) + s_offset - dktp;
    float e = (r*R)/(T*T);
    float E = solveKepler(e,M);
    float Theta = E - PI + dktp;
    
    res.theta = (Theta-s_offset);
    res.strand=n;
    res.p = vec4(R*cos(Theta), R*sin(Theta), res.theta*T,1.0);
        
    offset *= sign(n-0.5);
    offset += offsetoffsetlol;
    Theta = round((Theta-s_offset+offset)/stepsize)*stepsize+s_offset-offset;
    
    res.stepped_theta = (Theta-s_offset);
    res.strand=n;
    res.stepped_p = vec4(R*cos(Theta), R*sin(Theta), res.stepped_theta*T,1.0);
    res.stepped_theta += s_offset;
    
    
    return res;
}

struct TorusHit {
      vec4 p;
      float angle;
};

TorusHit sdTorus(vec4 pos, float r1)
{
      TorusHit hit;
      hit.angle = atan(pos.y,pos.x);
      hit.p = vec4(normalize(pos.xy)*r1,0,1);
    return hit;
}

struct Result {
    float dist;
    vec4 n;
};
    
    
    float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

Result ED(vec4 p) {
    vec3 col = pal( PHASE, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    
    p = rotationZ(-PHASE*TWOPI*1.0)*p;
    float T = outerT;
    HelixHit hit = ClosestPointHelixStep(p,4.0,T,2.0,PI/3.0,2.0*PHASE*TWOPI,-(PHASE*TWOPI)*0.5*2.0);
    
    float dh = distance(p,hit.p)-0.25;
    vec3 nh = normalize(p-hit.p).xyz;
    
    //vec3 col = pal( PHASE, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    //glow += normalize(col) * pow(max(0.0,(1.0-1.0*dh)),3.0) * 0.05;

    Result res;
    
    vec3 lookDir = (vec3(hit.stepped_p.y,-hit.stepped_p.x,-T));
    mat4 transform = buildtransform(lookDir.xyz,0.0,-hit.stepped_p.xyz,true);
    TorusHit hit2 = sdTorus(transform*p,1.7);
    
    /*mat4 invt = inverse(transform);
    float dt = distance(p,invt*hit2.p)-0.1;
    vec3 nt = (invt*normalize(transform*p-hit2.p)).xyz;
    vec3 colt = pal( mod(PHASE+0.5,1.0), vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    if (dt < dh) {
          dh = dt;
          nh = nt;
        //col = pal( mod(PHASE+0.5,1.0), vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    }*/
    
    vec3 lookDir2 = (vec3(hit2.p.y,-hit2.p.x,0));
    transform = buildtransform(lookDir2.xyz,-hit2.angle*1.7,-hit2.p.xyz,false) * transform;
    float T2 = 1.7/5.0;
    HelixHit hit3 = ClosestPointHelixStep(transform*p,0.6,T2,2.0,PI/1.5,-PHASE*TWOPI*5.0,0.0);
    
    
    
    //glow += normalize(vec3(0.8 + 0.4*sin(2.0*PHASE*TWOPI+0.75*PI),1.0,0.6+0.4*sin(PHASE*TWOPI))) * pow(max(0.0,(1.0-1.0*length(hit3.p - transform*p))),2.0) * 0.031;
    //glow += normalize(vec3(1.0,1.0,1.0)) * pow(max(0.0,(1.0-0.5*length(hit3.p - transform*p))),1.0) * 0.021;
    
    
    mat4 inv0 = inverse(transform);
    float d0 = distance(p,inv0*hit3.p)-0.043*2.00;
    vec4 n0 = inv0*normalize(transform*p-hit3.p);
    
    vec3 lookDir3 = (vec3(hit3.stepped_p.y,-hit3.stepped_p.x,-T2));
    transform = buildtransform(lookDir3.xyz,0.0,-hit3.stepped_p.xyz,true) * transform;
    TorusHit hit4 = sdTorus(transform*p,0.15+0.05*hit3.strand*0.0+0.05*sin(15.0*PHASE*PI*2.0+hit3.stepped_theta*2.0+1.0*hit3.strand*3.14159));
    
    
    mat4 inv = inverse(transform);
    res.dist = distance(p,inv*hit4.p)-0.043*1.00;
    res.n = inv*normalize(transform*p-hit4.p);
    
    res.dist = opSmoothUnion(d0,res.dist,0.35);
    
    glow += normalize(vec3(1.0,1.0,1.0)) * pow(max(0.0,(1.0-1.0*res.dist)),2.0) * 0.021;
    
    res.dist = min(dh,res.dist);

    /*if (d0 < res.dist) {
        res.dist = d0; 
           res.n = n0;
    }*/
    
    
    
    float glowmult = 1.0;
    
    if (res.dist < EPSILON) {
      if (dh > res.dist) {
        glowmult = max(0.0,-dot(n0.xyz,nh)) * pow(max(0.0,(1.0-0.3*dh)),2.0) *40.0;
      } else {
          glowmult = 20.0;  
      }
    } else {
        glowmult = pow(max(0.0,(1.0-0.5*dh)),1.0) * 1.0;
    }
    glow += normalize(col)  * 0.01 * glowmult;
    
    return res;
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
    glow = pow(glow,vec3(1.2));
    return 1.0-glow;
    
}

void main(void)
{
    vec2 uv =(gl_FragCoord.xy-.5*resolution.xy)/resolution.x * PI * 0.5;
    
    vec4 raydir = normalize(vec4(sin(uv.x),1.0,-sin(uv.y),0.0));
    vec4 rayorig = vec4(15.0,0.0,0.0,1);
    
    //vec2 rot = (mouse*resolution.xy.xy / resolution.xy - 0.5) * 2.0 * PI;
    //if (mouse*resolution.xy.x <= 0.0 && mouse*resolution.xy.y <= 0.0)
    vec2 rot = vec2(-0.5,-0.5)*PI;
    //rot += vec2(-0.5,-0.5)*PI;
    
    mat4 m = rotationY(-rot.x) * rotationX(rot.y) * rotationY(0.5);
    raydir = m * raydir;

    glFragColor = vec4(raymarch(rayorig, raydir),1.0);
}
