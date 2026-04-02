#version 420

// original https://www.shadertoy.com/view/XtySRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS 0.005
#define FAR 30.0
#define PI 3.1415

float igt = time * 1.0;

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float sdSphere(vec3 rp, vec3 bp, float r) {
    return length(bp - rp) - r;
}

float sdCapsule(vec3 rp, vec3 a, vec3 b, float r) {
    vec3 pa = rp - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

//body joints
vec3 leftHip = vec3(0.0);
vec3 rightHip = vec3(0.0);
vec3 leftKnee = vec3(0.0);
vec3 leftAnkle = vec3(0.0);
vec3 rightKnee = vec3(0.0);
vec3 rightAnkle = vec3(0.0);
vec3 bSpine = vec3(0.0);
vec3 uSpine = vec3(0.0);
vec3 leftShoulder = vec3(0.0);
vec3 rightShoulder = vec3(0.0);
vec3 leftElbow = vec3(0.0);
vec3 leftWrist = vec3(0.0);
vec3 rightElbow = vec3(0.0);
vec3 rightWrist = vec3(0.0);
vec3 leftFinger = vec3(0.0);
vec3 rightFinger = vec3(0.0);
vec3 head = vec3(0.0);

void leg(inout vec3 hip, inout vec3 knee, inout vec3 ankle, float sct, float cct) {
    
    //thigh
    vec3 rHK = normalize(vec3(0.0, -1.0, 0.0)); //rotation hip-knee
    rHK.yz *= rot(sct * 0.4 + 0.25);
    knee = hip + rHK * 0.46;
    
    //shin
    vec3 rKA = normalize(vec3(0.0, -1.0, 0.0)); //rotation knee-ankle
    rKA.yz *= rot(sct * 0.25);
    rKA.yz *= rot(clamp(cct, 0.0, PI) * -0.5); //more lift on way back
    
    //angle between hip-knee, knee-ankle
    float aKA = atan(rHK.y, rHK.z) - atan(rKA.y, rKA.z);
    if (aKA < 0.0) {
        //guard condition
        rKA = rHK;
    }

    ankle = knee + rKA * 0.52;
}

void arm(inout vec3 shoulder, inout vec3 elbow, inout vec3 wrist, inout vec3 finger, float sct, float cct, float fd) {
    
    //upper arm
    vec3 rSE = normalize(vec3(0.0, -1.0, 0.0)); //rotation shoulder-elbow
    rSE.yz *= rot((cct) * 0.4);
    elbow = shoulder + rSE * 0.32;

    //lower arm
    vec3 rEW = normalize(vec3(0.0, -1.0, 0.0) - (rSE * 0.2));
    float aEW = atan(rSE.y, rSE.z) - atan(rEW.y, rEW.z);
    if (aEW > 0.0) {
        //guard
        rEW = rSE;
    }
    wrist = elbow + rEW * 0.28;
    
    //hand
    vec3 rWF = rEW;
    rWF.x += 0.25 * fd;
    finger = wrist + normalize(rWF) * 0.2;

}

void walk(float speed) {
    
    float ct = mod(igt, speed) * 2.0 * PI / speed; //cycle time
    float lsct = sin(ct); //sin of left cycle time 
    float lcct = cos(ct); //cos of left cycle time
    float rsct = sin(ct + PI); //sin of right cycle time
    float rcct = cos(ct + PI); //cos of right cycle time
    
    //hip
    //everything is positioned relative to hip at y = 0
    leftHip = vec3(-0.14, 0.0, 0.0);
    rightHip = vec3(0.14, 0.0, 0.0);

    leg(leftHip, leftKnee, leftAnkle, lsct, lcct); //left leg
    leg(rightHip, rightKnee, rightAnkle, rsct, rcct); //right leg

    //adjust height from floor of model
    //hip to floor is 0.98 (0.46 thigh + 0.52 shin)
    float dif = min(-0.98 - leftAnkle.y, -0.98 - rightAnkle.y);
    leftHip.y += dif;
    rightHip.y += dif;
    leftKnee.y += dif;
    leftAnkle.y += dif;
    rightAnkle.y += dif;
    
    //spine
    bSpine = vec3(0.0, 0.0 + dif, 0.0);
    uSpine = vec3(0.0, 0.6 + dif, 0.0);

    //shoulder
    leftShoulder = vec3(-0.25, 0.6 + dif, 0.0);
    rightShoulder = vec3(0.25, 0.6 + dif, 0.0);
    
    //head
    head = vec3(0.0, 0.85 + dif, 0.0);

    arm(leftShoulder, leftElbow, leftWrist, leftFinger, rsct, rcct, -1.0); //left arm
    arm(rightShoulder, rightElbow, rightWrist, rightFinger, lsct, lcct, 1.0); //right arm
}

float dfScene(vec3 rp) {
    
    float msd = 99.0;
    
    //hip
    msd = min(msd, sdSphere(rp, leftHip, 0.06));
    msd = min(msd, sdSphere(rp, rightHip, 0.06));
    msd = min(msd, sdCapsule(rp, leftHip, rightHip, 0.02));
    //left thigh
    msd = min(msd, sdSphere(rp, leftKnee, 0.05));
    msd = min(msd, sdCapsule(rp, leftHip, leftKnee, 0.02));
    //left shin
    msd = min(msd, sdSphere(rp, leftAnkle, 0.04));
    msd = min(msd, sdCapsule(rp, leftKnee, leftAnkle, 0.015));
    //right thigh
    msd = min(msd, sdSphere(rp, rightKnee, 0.05));
    msd = min(msd, sdCapsule(rp, rightHip, rightKnee, 0.02));
    //right shin
    msd = min(msd, sdSphere(rp, rightAnkle, 0.04));
    msd = min(msd, sdCapsule(rp, rightKnee, rightAnkle, 0.015));
    //spine
    msd = min(msd, sdSphere(rp, bSpine, 0.04));
    msd = min(msd, sdSphere(rp, uSpine, 0.04));
    msd = min(msd, sdCapsule(rp, bSpine, uSpine, 0.02));
    //shoulder
    msd = min(msd, sdSphere(rp, leftShoulder, 0.05));
    msd = min(msd, sdSphere(rp, rightShoulder, 0.05));
    msd = min(msd, sdCapsule(rp, leftShoulder, rightShoulder, 0.02));
    //left upper arm
    msd = min(msd, sdSphere(rp, leftElbow, 0.04));
    msd = min(msd, sdCapsule(rp, leftShoulder, leftElbow, 0.02));
    //left lower arm
    msd = min(msd, sdSphere(rp, leftWrist, 0.03));
    msd = min(msd, sdCapsule(rp, leftElbow, leftWrist, 0.015));
    //left finger
    msd = min(msd, sdSphere(rp, leftFinger, 0.015));
    msd = min(msd, sdCapsule(rp, leftWrist, leftFinger, 0.01));
    //right upper arm 
    msd = min(msd, sdSphere(rp, rightElbow, 0.04));
    msd = min(msd, sdCapsule(rp, rightShoulder, rightElbow, 0.02));
    //right lower arm
    msd = min(msd, sdSphere(rp, rightWrist, 0.03));
    msd = min(msd, sdCapsule(rp, rightElbow, rightWrist, 0.015));
    //right finger
    msd = min(msd, sdSphere(rp, rightFinger, 0.015));
    msd = min(msd, sdCapsule(rp, rightWrist, rightFinger, 0.01));
    //head
    msd = min(msd, sdSphere(rp, head, 0.15));
    
    return msd;
}

vec3 surfaceNormal(vec3 p) { 
    vec2 e = vec2(5.0 / resolution.y, 0);
    float d1 = dfScene(p + e.xyy), d2 = dfScene(p - e.xyy);
    float d3 = dfScene(p + e.yxy), d4 = dfScene(p - e.yxy);
    float d5 = dfScene(p + e.yyx), d6 = dfScene(p - e.yyx);
    float d = dfScene(p) * 2.0;    
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

//IQ
float calcAO(vec3 pos, vec3 nor) {   
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.05*float(i);
        vec3 aopos = pos + nor*hr;
        occ += smoothstep(0.0, 0.7, hr - dfScene(aopos)) * sca;
        sca *= 0.97;
    }
    return clamp(1.0 - 3.0 * occ , 0.0, 1.0);
}

//main march
vec3 marchScene(vec3 ro, vec3 rd) {
    
    vec3 pc = vec3(0.0); //returned pixel colour
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
    vec3 lp = normalize(vec3(5.0, 8.0, -3.0)); //light position
   
    for (int i = 0; i < 50; i++) {
        rp = ro + rd * d;
        float ns = dfScene(rp);
        d += ns;
        if (ns < EPS || d > FAR) break;
    }
    
    if (d < FAR) {

        vec3 sc = vec3(1.0, 0.0, 0.0); //surface colour
        vec3 n = surfaceNormal(rp);
        float ao = calcAO(rp, n);
        
        float diff = max(dot(n, lp), 0.0); //diffuse
        pc = sc * 0.5 + diff * sc * ao;
        float spe = pow(max(dot(reflect(rd, n), lp), 0.), 16.); //specular.
        pc = pc + spe * vec3(1.0);
    }
    
    return pc;
}

void main(void) {
    
    walk(2.0);
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0.0, 0.0, -2.5);
    
    //rotate camera
    ro.yz *= rot(sin(igt) * 0.25);
    rd.yz *= rot(sin(igt) * 0.25); 
    ro.xz *= rot(igt * 0.5);
    rd.xz *= rot(igt * 0.5);
    //*/
    
    glFragColor = vec4(marchScene(ro, rd), 1.0);    
}
