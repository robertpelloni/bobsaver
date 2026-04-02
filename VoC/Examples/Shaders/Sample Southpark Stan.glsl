#version 420

// original https://www.shadertoy.com/view/MtyGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FAR_CLIP 20.0
#define EPS 0.005
#define PI 3.1415
#define NOTHING 0.0
#define HEAD 1.0
#define HAT 2.0
#define BOBBLE 3.0
#define RIM 4.0
#define TORSO 5.0
#define HANDS 6.0
#define LEGS 7.0
#define FEET 8.0

const vec2 DEFDF = vec2(9999.0, NOTHING);
const vec3 light = vec3(2.0, 5.0, 5.0);

float t = time * 2.5;

/* Rotations */

void rX(inout vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    p.y = c * q.y - s * q.z;
    p.z = s * q.y + c * q.z;
}

void rY(inout vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    p.x = c * q.x + s * q.z;
    p.z = -s * q.x + c * q.z;
}

/* Distance functions */

// IQ polynomial smooth min (k = 0.1);
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdSphere(vec3 rp, vec3 bp, float r) {
    return length(bp - rp) - r;
}

float sdBox(vec3 rp, vec3 b) {
    vec3 d = abs(rp) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdTorus(vec3 rp, vec2 t) {
    vec2 q = vec2(length(rp.xz) - t.x, rp.y);
    return length(q) - t.y;
}

float sdEllipsoid(in vec3 rp, in vec3 r) {
    return (length(rp / r) - 1.0) * min(min(r.x, r.y), r.z);
}

float dot2(vec2 v) { 
    return dot(v, v);
}

float sdCappedCone (vec3 rp, vec3 s) {
    vec2 q = vec2(length(rp.xy),rp.z);
    vec2 ba = vec2(s.x - s.y, -2.0*s.z);
    vec2 pa = vec2(q.x - s.y, q.y - s.z);
    vec2 d = pa - ba * clamp(dot(pa,ba) / dot(ba,ba),0.0,1.0);
    vec2 h0 = vec2(max(q.x - s.x,0.0),q.y + s.z);
    vec2 h1 = vec2(max(q.x - s.y,0.0),q.y - s.z);
    return sqrt(min(dot2(d),min(dot2(h0),dot2(h1))))
        * sign(max(dot(pa,vec2(-ba.y, ba.x)), abs(q.y) - s.z));
}

float dfHead(vec3 rp) {
    return sdSphere(rp, vec3(0.0, 0.0, 0.0), 1.5);
}

float dfHat(vec3 rp) {
    float sphere = sdSphere(rp, vec3(0.0, 0.0, 0.0), 1.6);
    rp += vec3(0.0, 1.81, 0.0);
    float box = sdBox(rp, vec3(1.81));
    return max(sphere, -box);
}

float dfRim(vec3 rp) {
    return sdTorus(rp, vec2(1.6, 0.1));
}

float dfBobble(vec3 rp) {
    return sdSphere(rp, vec3(0.0, 1.9, 0.0), 0.5);
}

float dfTorso(vec3 rp) {
    rp += vec3(0.0, 2.7, 0.0);
    float body = sdEllipsoid(rp, vec3(1.4, 2.0, 1.4));
    rp += vec3(0.0, 3.2, 0.0);
    float box = sdBox(rp, vec3(2.41));
    rp += vec3(1.5, -4.0, 0.0);
    float leftArm = sdCappedCone(rp.yzx, vec3(0.44, 0.6, 0.5));
    rp += vec3(-3.0, 0.0, 0.0);
    float rightArm = sdCappedCone(rp.yzx, vec3(0.6, 0.44, 0.5));
    return smin(smin(max(body, -box), leftArm, 0.1), rightArm, 0.1);
}

float dfHands(vec3 rp) {    
    rp += vec3(2.35, 1.9, 0.0);
    float leftHand = sdEllipsoid(rp, vec3(0.6, 0.55, 0.45));
    leftHand = smin(leftHand, sdSphere(rp, vec3(0.0, 0.6, 0.0), 0.2), 0.1);    
    rp += vec3(-4.7, 0.0, 0.0);
    float rightHand = sdEllipsoid(rp, vec3(0.6, 0.55, 0.45));
    rightHand = smin(rightHand, sdSphere(rp, vec3(0.0, 0.6, 0.0), 0.2), 0.1);    
    return min(leftHand, rightHand);
}

float dfLegs(vec3 rp) {
    float crutch = sdSphere(rp, vec3(0.0, -2.8, 0.0), 1.2);
    rp += vec3(0.45, 3.7, 0.0);
    float leg1 = sdCappedCone(rp.xzy, vec3(0.65, 0.85, 0.40));
    rp += vec3(-0.9, 0.0, 0.0);
    float leg2 = sdCappedCone(rp.xzy, vec3(0.65, 0.85, 0.40));
    return smin(crutch, min(leg1, leg2), 0.1);
}

float dfFeet(vec3 rp) {
    rp.y += 4.3;
    rp.x += 0.45;
    float foot1 = sdCappedCone(rp.xzy, vec3(0.8, 0.65, 0.20));
    rp.x -= 0.9;
    return min(foot1,sdCappedCone(rp.xzy, vec3(0.8, 0.65, 0.20)));

}

vec2 minDf(vec2 curDf, float newDist, float newMat) {
    if (newDist < curDf.x) {
        curDf.x = newDist;
        curDf.y = newMat;
    }
    return curDf;
}

//get distance and material of scene
vec2 dfSceneAndMat(vec3 rp) {
    
    vec2 curDf = DEFDF; //distance marched, material
    
    float head = dfHead(rp);
    curDf = minDf(curDf, head, HEAD);
    //rotate hat
    vec3 rrp = rp;
    rX(rrp, 0.65);
    float hat = dfHat(rrp);
    curDf = minDf(curDf, hat, HAT);
    float bobble = dfBobble(rrp);
    curDf = minDf(curDf, bobble, BOBBLE);
    float rim = dfRim(rrp);
    curDf = minDf(curDf, rim, RIM);
    float torso = dfTorso(rp);
    curDf = minDf(curDf, torso, TORSO);
    float hands = dfHands(rp);
    curDf = minDf(curDf, hands, HANDS);
    float legs = dfLegs(rp);
    curDf = minDf(curDf, legs, LEGS);
    float feet = dfFeet(rp); 
    curDf = minDf(curDf, feet, FEET);
    
    return curDf;
}

//simpler version for lighting
float dfScene(vec3 rp) {
    
    float head = dfHead(rp);
    //rotate hat
    vec3 rrp = rp;
    rX(rrp, 0.65);
    float hat = dfHat(rrp);
    float bobble = dfBobble(rrp);
    float rim = dfRim(rrp);    
    float torso = dfTorso(rp);
    float hands = dfHands(rp);
    float legs = dfLegs(rp);
    float feet = dfFeet(rp); 

    return min(min(min(torso, hands), min(head, min(min(hat, rim), bobble))), min(legs, feet));
}

/* Shading */

float mapTo(float x, float minX, float maxX, float minY, float maxY) {
    float a = (maxY - minY) / (maxX - minX);
    float b = minY - a * minX;
    return a * x + b;
}

float shadow(vec3 rp, vec3 lp, float k) {
    vec3 rd = normalize(lp - rp); //ray direction
    float t = 10.0 * EPS; // Start a bit away from the surface
    float maxt = length(lp - rp);
    float f = 1.0;
    for (int i = 0; i < 50; ++i) {
        float d = dfScene(rp + rd * t);
        if (d < EPS) return 0.0;
        // Penumbra factor is calculated based on how close we were to
        // the surface, and how far away we are from the shading point
        f = min(f, k * d / t);
        t += d;
        if(t >= maxt) break;
    }
    return f;
}

vec3 shading(vec3 rp, vec3 n, vec3 lp, vec3 lightColor) { 
    float li = 0.0; //light intensity
    float shad = 0.0; //shadow
    shad = shadow(rp, lp, 16.0);
    if (shad > 0.0) {    //are we visible
        vec3 ld = normalize(lp - rp);
        li = shad * clamp(dot(n, ld), 0.0, 1.0);
    }
    return lightColor * li + vec3(0.5) * (1.0 - li);
}

/*
Banding issues fixed by IQ - see below

float calcAO(vec3 pos, vec3 nor){
    float dd, hr, totao = 0.0;
    float sca = 1.0;
    vec3 aopos; 
    for(int aoi = 0; aoi < 5; aoi++) {
        hr = 0.01 + 0.05 * float(aoi);
        aopos =  nor * hr + pos;
        totao += -(dfScene(aopos) - hr) * sca;
        sca *= 0.75;
    }
    return clamp(1.0 - 4.0 * totao , 0.0, 1.0);
}
//*/

float calcAO(vec3 pos, vec3 nor) {
    
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) 
    {
        float hr = 0.01 + 0.05*float(i);
        vec3 aopos = pos + nor*hr;
        occ += smoothstep(0.0,0.7,hr-dfScene(aopos)) * sca;
        sca *= 0.97;
    }
    return clamp(1.0 - 3.0*occ , 0.0, 1.0);
}
//*/

vec3 surfaceNormal(vec3 rp) {
    float e = 0.001;
    vec3 dx = vec3(e, 0.0, 0.0);
    vec3 dy = vec3(0.0, e, 0.0);
    vec3 dz = vec3(0.0, 0.0, e);
    return normalize(vec3(dfScene(rp + dx) - dfScene(rp - dx),
                          dfScene(rp + dy) - dfScene(rp - dy),
                          dfScene(rp + dz) - dfScene(rp - dz)));
}

vec3 coatColour(vec3 rp) {
    vec3 coatCol = vec3(0.54, 0.27, 0.07);   
    if (rp.z > 0.0) {
        //seam
        if (rp.x > -0.25 && rp.x < -0.2) {
            coatCol = vec3(0.0);    
        }
        //buttons
        if (length(rp.xy - vec2(0.0, -1.6)) < 0.1) {
            coatCol = vec3(0.0);
        }
        if (length(rp.xy - vec2(0.0, -2.3)) < 0.1) {
            coatCol = vec3(0.0);
        }
        if (length(rp.xy - vec2(0.0, -3.0)) < 0.1) {
            coatCol = vec3(0.0);
        }
    }
    return coatCol;
}

vec3 faceColour(vec3 rp) {
    vec3 faceCol = vec3(1.0, 0.9, 0.98);
    if (rp.z > 0.0) {
        //eyes
        if (length(rp.xy - vec2(0.47, 0.15)) < 0.45) {
            faceCol = vec3(0.0);
        }
        if (length(rp.xy - vec2(0.47, 0.15)) < 0.4) {
            faceCol = vec3(1.0);
        }
        if (length(rp.xy - vec2(0.35, 0.05)) < 0.1) {
            faceCol = vec3(0.0);
        }

        if (length(rp.xy - vec2(-0.47, 0.15)) < 0.45) {
            faceCol = vec3(0.0);
        }
        if (length(rp.xy - vec2(-0.47, 0.15)) < 0.4) {
            faceCol = vec3(1.0);
        }
        if (length(rp.xy - vec2(-0.35, 0.05)) < 0.1) {
            faceCol = vec3(0.0);
        }

        //mouth
        if (rp.x > -0.3 && rp.x < 0.3) {
            if (rp.y > -0.7 && rp.y < -0.6) {
                 faceCol = vec3(0.0);   
            }
        }
    }
    return faceCol;
}

/* Marching & Tracing */

float raytraceFloor(vec3 ro, vec3 rd, vec3 n, vec3 o) {
    return dot(o - ro, n) / dot(rd, n);
}

vec3 marchScene(vec3 ro, vec3 rd) {
    
    vec3 pc = vec3(1.0); //pixel colour
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
    vec2 df = vec2(9999.0, NOTHING); //distance function and material
    
    vec3 fn = vec3(0, 1, 0); //floor normal
    float fd = raytraceFloor(ro, rd, fn, vec3(0, -4.51, 0)); //floor distance

    for (int i = 0; i < 80; i++) {
        rp = ro + rd * d;
        df = dfSceneAndMat(rp); //nearest surface and material
        d += df.x;
        if (df.x < EPS || d > FAR_CLIP) break;
    }
    
    if (d < FAR_CLIP) { 
        
        pc = vec3(0.); //feet       
            
        if (df.y == TORSO) {
            pc = coatColour(rp);    
        }
        if (df.y == BOBBLE || df.y == RIM || df.y == HANDS) {
            pc = vec3(1.0, 0.0, 0.0);   
        }
        if (df.y == HAT) {
            pc = vec3(0.0, 0.0, 1.0);   
        }
        if (df.y == LEGS) {
            pc = vec3(0.0, 0.0, 1.0);    
        }
        if (df.y == HEAD) {
            pc = faceColour(rp);;    
        }
        
        vec3 n = surfaceNormal(rp);
        float ao = calcAO(rp, n);
        pc = pc * shading(rp, n, light, vec3(1.0)) * ao; 

    } else if (fd > 0.0 && fd < FAR_CLIP) {
        //shade floor
        rp = ro + rd * fd;
        float ao = calcAO(rp, fn);
        pc = pc * shading(rp, fn, light, vec3(1.0)) * ao;
        //fade
        float z = mapTo(fd, 0.0, FAR_CLIP, 1.0, 0.0);
        pc = mix(vec3(1.0), pc, z * z * (1.2 * z)); 
    } 
    
    return pc;
}

void main(void) {

    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0.0, -1.5, -8.0);
    
    //rotate camera
    rY(ro, t * 0.15 + 2.5); 
    rY(rd, t * 0.15 + 2.5);
    
    //ray marching
    glFragColor = vec4(marchScene(ro, rd), 1.0);
}
