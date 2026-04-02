#version 420

// original https://www.shadertoy.com/view/MtlcDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/**
 * Truchet with directional flow
 * Truchet code from Shane - Cubic Truchet Pattern
 **/

#define EPS 0.005
#define FAR 20.0 
#define PI 3.1415
#define T time * 0.5

mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

float sdSphere(vec3 rp, vec3 bp, float r) {
    return length(bp - rp) - r;
}

//truchet cell
float truchet(vec3 p, inout vec3 sc, inout vec3 sca, inout vec3 scb, float dir) {

    //torus
    const float radius = .0025;
    //split rail into 4 - trick taken from Shane Mobius Object
    //https://www.shadertoy.com/view/XldSDs
    float tb = length( abs(abs(vec2(length(p.xy) - .5, p.z)) - 0.04) ) - radius;
    
    //marble
    float dt = mod(T, PI * 0.5);
    sc.xy *= rot(dt * dir);
    sca.xy *= rot(dt * dir + PI * 0.5 * dir); //90 degrees in front
    scb.xy *= rot(dt * dir - PI * 0.5 * dir); //90 degrees behind
    
    return tb;
}

//this needs a lot of tidying up
float map(vec3 rp) {
 
    // Random ID for each grid cube.
    float rnd = fract(sin(dot(floor(rp + vec3(111, 73, 27)), vec3(7.63, 157.31, 113.97)))*43758.5453);

    vec3 q = fract(rp) - .5; //breakup space into cells and offset

    //direction of marble travel
    vec3 ip = floor(rp);
    float dir = (fract(dot(ip.xy, vec2(0.5))) > 0.25) ? -1.0 : 1.0; 
    //dir *= mod(ip.z, 2.0) - 0.5 > 0.0 ? 1.0 : -1.0;
    
    //variation
    //float r8 = mod(rp.z, 3.0);
    //if (r8 > 3.0) q = q.zyx;    
    float r5 = mod(rp.z, 4.0);
    if (r5 > 3.0) q = q.yxz; 

    float dir1 = -1.0;
    float dir2 = 1.0;
    float dir3 = 1.0;

    //marbles - 3 spheres used for each to handle rendering discontinuities between borders of cells
    //it seems a bit of a fudge to me
    vec3 sc1 = vec3(0.5, 0.0, 0.0);
    vec3 sc1a = vec3(0.5, 0.0, 0.0);
    vec3 sc1b = vec3(0.5, 0.0, 0.0);
    vec3 sc2 = vec3(0.0, -0.5, 0.0);
    vec3 sc2a = vec3(0.0, -0.5, 0.0);
    vec3 sc2b = vec3(0.0, -0.5, 0.0);
    vec3 sc3 = vec3(-0.5, 0.0, 0.0);
    vec3 sc3a = vec3(-0.5, 0.0, 0.0);
    vec3 sc3b = vec3(-0.5, 0.0, 0.0);
    
    //handles both directions of travel
    if (dir < 0.0) {

        sc1 = vec3(0.0, 0.5, 0.0);
        sc1a = vec3(0.0, 0.5, 0.0);
        sc1b = vec3(0.0, 0.5, 0.0);
        sc2 = vec3(-0.5, 0.0, 0.0);
        sc2a = vec3(-0.5, 0.0, 0.0);
        sc2b = vec3(-0.5, 0.0, 0.0);
        sc3 = vec3(0.0, 0.5, 0.0);
        sc3a = vec3(0.0, 0.5, 0.0);
        sc3b = vec3(0.0, 0.5, 0.0);
        
        dir1 = 1.0;
        dir2 = -1.0;
        dir3 = -1.0;
    }
    
    //rail
    float rail = truchet(vec3(q.xy + .5, q.z), sc1, sc1a, sc1b, dir1); 
    rail = min(rail, truchet(vec3(q.yz - .5, q.x), sc2, sc2a, sc2b, dir2));
    rail = min(rail, truchet(vec3(q.xz - vec2(.5, -.5), q.y), sc3, sc3a, sc3b, dir3));
        
    //marbles
    float r = 0.048;
    float ball1 = sdSphere(vec3(q.xy + .5, q.z), sc1, r);    
    float ball1a = sdSphere(vec3(q.xy + .5, q.z), sc1a, r);    
    float ball1b = sdSphere(vec3(q.xy + .5, q.z), sc1b, r);    
    float ball2 = sdSphere(vec3(q.yz - .5, q.x), sc2, r);    
    float ball2a = sdSphere(vec3(q.yz - .5, q.x), sc2a, r);    
    float ball2b = sdSphere(vec3(q.yz - .5, q.x), sc2b, r);    
    float ball3 = sdSphere(vec3(q.xz - vec2(.5, -.5), q.y), sc3, r);    
    float ball3a = sdSphere(vec3(q.xz - vec2(.5, -.5), q.y), sc3a, r);    
    float ball3b = sdSphere(vec3(q.xz - vec2(.5, -.5), q.y), sc3b, r);    

    float balls = min(ball1, min(ball1a, ball1b));
    balls = min(balls, min(ball2, min(ball2a, ball2b)));
    balls = min(balls, min(ball3, min(ball3a, ball3b)));

    return min(rail, balls);   
}

vec3 normal(vec3 rp, float t) {
    float e = EPS * t;
    return normalize(vec3(map(rp + vec3(e, 0.0, 0.0)) - map(rp - vec3(e, 0.0, 0.0)),
                          map(rp + vec3(0.0, e, 0.0)) - map(rp - vec3(0.0, e, 0.0)),
                          map(rp + vec3(0.0, 0.0, e)) - map(rp - vec3(0.0, 0.0, e))));
}

float occlusion(vec3 rp, vec3 n) {
    
    float fac = 2.5;
    float occ = 0.0;
    
    for (int i = 0; i < 5; i ++) {
        float hr = 0.01 + float(i) * 0.35 / 4.0;        
        float dd = map(n * hr + rp);
        occ += (hr - dd) * fac;
        fac *= 0.7;
    }
    
    return clamp(1.0 - occ, 0.0, 1.0);    
}

float march(vec3 ro, vec3 rd) {
    
    float t = 0.0;
    
    for (int i = 0; i < 100; i++) {
        vec3 rp = ro + rd * t;
        float ns = map(rp);
        //if (ns < EPS || t > FAR) break;
        //suggestion from aeikick
        if (t * t / ns > 7e2 || t > FAR) break;
             
        t += ns;
    }
    
    return t;    
}

void setupCamera(out vec3 ro, out vec3 rd, vec2 gl_FragCoord) {
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 lookAt = vec3(0.0, 0.0, T);
    ro = vec3(sin(T * 0.8) * 0.3, 0.2 + cos(T) * 0.1, T - 4.0);
    
    float FOV = PI / 4.;
    vec3 forward = normalize(lookAt.xyz - ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);    
    rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
}

void main(void) {
    
    vec3 pc = vec3(0.0);
    vec3 ld = normalize(vec3(4.0, 5.0, 2.0));
    
    vec3 ro, rd;
    setupCamera(ro, rd, gl_FragCoord.xy);
    
    float t = march(ro, rd);
    if (t > 0.0 && t < FAR) {
        vec3 rp = ro + rd * t;
        vec3 n = normal(rp, t);
        vec3 rrd = reflect(rd, n);
        float diff = max(dot(n, ld), 0.05);
        float spec = pow(clamp(dot(rrd, ld), 0.0, 1.0), 32.0);
        float occ = occlusion(rp, n);
        
        pc = vec3(1.0) * diff * occ + vec3(0.3, 0.0, 0.05) * clamp(n.y, 0.0, 1.0) * 0.3;
        pc += vec3(1.0) * spec;
    }
    
    float gfog = 1.0 - exp(-t * 0.2);
    pc = mix(pc, vec3(0.7, 0.8, 0.9), gfog);
    
    glFragColor = vec4(pc, 1.0);
}
