#version 420

// original https://www.shadertoy.com/view/sdcGWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Second shader after watching some tutorials from The Art of Code (AKA BigWIngs) https://www.youtube.com/c/TheArtofCodeIsCool/videos
//and getting some code from Iñigo Quilez (https://iquilezles.org/www/articles/distfunctions/distfunctions.htm)
//Also many thanks to @samlo for his great explanation on how to colorize diferent objects https://www.shadertoy.com/view/wd2SR3
//First steps... totally unoptimized and I still get some artifacts on the feet and the shadows
//Starts dropping frames when in fullscreen @4K
//This one is inspired on a video I saw about the Chinese army
//Play around with Camera Rotation and/or Mouse Rotation
//It's a pitty I can't add a song that matches the rhythm (something seems to be wrong when importing links from SoundCloud) 
//Feedback appreciated!

//Added fog thanks to @FabriceNeyret2!!

#define HEAD_ROTATION 1
#define CAM_ROTATION 1
#define MOUSE_CAM_ROT 0

#define time time*4.

#define MAX_STEPS 120
#define MAX_DIST 60.
#define SURF_DIST 0.001

#define DARK_ID 0.
#define CLOTH1_ID 1.
#define CLOTH2_ID 1.5
#define SKIN_ID 2.
#define WHITE_ID 3.
#define GROUND_ID 4.

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (sqrt(5)*0.5 + 0.5)

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}

mat2 rotMat(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2 (c,-s,s,c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+max3(min(p, vec3(0)))-0.02;
}

float sdPlane( vec3 p, vec3 n, float h )
{
  // n must be normalized
  return dot(p,n) + h;
}

float add (inout vec2 a, vec2 b){
    a = mix(a,b,step(b.x,a.x));
    return 0.;
}
vec3 opRep( in vec3 p, in vec3 c )
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q ;
}

vec2 GetDist (vec3 p){
    
    vec3 armSize = vec3 (.2,.4,.2);                           //Arms Size
    vec3 handSize = vec3 (.2,.2,.13);          
    vec3 legSize = vec3 (.22,.8,.2);
    vec3 bodySize = vec3 (.6,1.,.3);
    vec3 headSize = vec3(.3,.35,.3);
    vec3 footSize = vec3(.2,.1,.43);
    vec3 capSize = vec3(.36,.1,.45);

    vec3 pG = p;
    pG.z += mod(time,4.);                                                //Global Position
    pG = opRep(pG,vec3(3,0,4));
    vec3 pB = pG;                                               //Body Position
    vec3 pH = pG -vec3(0,bodySize.y+headSize.y+0.05,0);         //Head Position
#if HEAD_ROTATION 
    pH.xz *= rotMat(-sin(time)*.5);                               //Head Rotation
#endif
    vec3 pCap = pH - vec3(0,headSize.y+capSize.y-.05,-capSize.z/3.3);                                               
    vec3 pShouldL = pG - vec3 (-(bodySize.x+armSize.x+0.05),bodySize.y,0);   //Shoulder Position
    pShouldL.yz *= rotMat(sin(time));                          //Shoulder Rotation    
    vec3 pArmL = pShouldL + vec3 (0,armSize.y,0);               //Arm Position
    vec3 pForeL = pShouldL-vec3(0,-2.*armSize.y-0.05,0);                       //Forearm Position
    pForeL.xz *= rotMat(radians(90.));                           //Forearm Rotation
    pForeL.yz *= rotMat(clamp(-sin(time)*PI/2.,0.,PI/2.));
    pForeL += vec3(0,armSize.y,0);                             //Forearm Anchor P reposition
    vec3 pHandL = pForeL-vec3(0,-armSize.y-handSize.y-0.05,0);
    pHandL.xz *= rotMat(-1.*clamp(-sin(time)*PI,0.,PI/2.)+PI);    
    vec3 pLegL = pB - vec3(-.4,-bodySize.y-.05,0);
    pLegL.yz *= rotMat(-sin(time));
    pLegL += vec3(0,legSize.y,0);
    vec3 pFootL = pLegL - vec3(0,-legSize.y-footSize.y-0.05,-footSize.z/2.);

    vec3 pShouldR = pG - vec3(bodySize.x+armSize.x+0.05,bodySize.y,0);
    pShouldR.yz *= rotMat(-sin(time));
    vec3 pArmR = pShouldR + vec3 (0,armSize.y,0);;
    vec3 pForeR = pShouldR-vec3(0,-2.*armSize.y-0.05,0);
    pForeR.xz *= rotMat(radians(-90.));
    pForeR.yz *= rotMat(clamp(sin(time)*PI/2.,0.,PI/2.));
    pForeR += vec3(0,armSize.y,0);
    vec3 pHandR = pForeR-vec3(0,-armSize.y-handSize.y-0.05,0);
    pHandR.xz *= rotMat(-1.*clamp(-sin(time)*PI,-PI/2.,0.)+PI);
    vec3 pLegR = pB - vec3(.4,-bodySize.y-.05,0);
    pLegR.yz *= rotMat(sin(time));
    pLegR += vec3(0,legSize.y,0);
    vec3 pFootR = pLegR - vec3(0,-legSize.y-footSize.y-0.05,-footSize.z/2.);

    vec2 body = vec2(sdBox(pB,bodySize),CLOTH1_ID);
    vec2 head = vec2(sdBox(pH,headSize),SKIN_ID);
    vec2 cap = vec2(sdBox(pCap,capSize),CLOTH2_ID);                      
    
    vec2 armL = vec2(sdBox (pArmL,armSize),CLOTH1_ID); 
    vec2 foreL = vec2(sdBox(pForeL,armSize),CLOTH1_ID);
    vec2 handL = vec2(sdBox(pHandL,handSize)*.5,WHITE_ID);
    vec2 legL = vec2(sdBox(pLegL,legSize),CLOTH2_ID);
    vec2 footL = vec2(sdBox(pFootL,footSize),DARK_ID);

    vec2 armR = vec2(sdBox(pArmR,armSize),CLOTH1_ID);
    vec2 foreR = vec2(sdBox(pForeR,armSize),CLOTH1_ID);
    vec2 handR = vec2(sdBox(pHandR,handSize)*.5,WHITE_ID);
    vec2 legR = vec2(sdBox(pLegR,legSize),CLOTH2_ID);
    vec2 footR = vec2(sdBox(pFootR,footSize),DARK_ID);

    vec2 floor = vec2(sdPlane(p,vec3(0,1.,0),3.),GROUND_ID);
    // vec2 floor = vec2(p.y+3,GROUND_ID);

    vec2 result = body;
    // result = mix(result,head,step(head.x,result.x));
    // result = mix(result,cap,step(cap))
    add (result,head);
    add (result,cap);
    add (result,armL);
    add (result,foreL);
    add (result,handL);
    add (result,legL);
    add (result,footL);
    add (result,armR);
    add (result,foreR);
    add (result,handR);
    add (result,legR);
    add (result,footR);
    add (result,floor);

    return result;
}

vec3 calcMaterial (float id) {
    if (id == DARK_ID)      return vec3(.1, .1, .1);
    if (id == CLOTH1_ID)     return vec3(92., 112., 56.)/256.;
    if (id == CLOTH2_ID)    return vec3(61., 74., 37.)/256.;
    if (id == SKIN_ID)     return vec3(0.764,0.6,0.552);
    if (id == WHITE_ID)     return vec3(1.);
    if (id == GROUND_ID)     return vec3(.4);
    return vec3(.2);
}

vec4 RayMarch (vec3 ro, vec3 rd){
    float dO = 0.;
    vec3 color;

    for (int i=0; i<MAX_STEPS; i++){
        vec3 p = ro + rd*dO;
        float dS = GetDist(p).x;
        float matID = GetDist(p).y;
        color = calcMaterial(matID);
        dO += dS;
        if (dO>MAX_DIST || abs(dS)<SURF_DIST) break;

    }    
    
    return vec4(color,dO);
}

vec3 GetNormal (vec3 p){
    vec2 d = GetDist(p);
    vec2 e = vec2(0.01,0);

    vec3 n = d.x - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    return normalize(n);
}

float GetLight(vec3 p){
    vec3 lightPos = vec3 (1.,10.,-10.);
    //lightPos.xz += vec2(sin(time),cos(time));
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal (p);
    float dif = clamp(dot(n,l)*.5+0.5,0.,1.);
    float d = RayMarch(p+n*SURF_DIST*2.,l).w;
    if (d<length(lightPos-p)) dif *= .1;  //Shadows

    return dif;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1.,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m  = mouse*resolution.xy.xy/resolution.xy;
    vec3 col = vec3(0.);        //vec3(0.,.3,.6)*smoothstep(-0.1,1.,length(uv.y));

    vec3 ro = vec3 (0,4,-4.2);
#if CAM_ROTATION
    ro = vec3 (sin(time*.1)*8.,7.+sin(time*.05)*4.,cos(time*.1)*8.);
#endif
#if MOUSE_CAM_ROT
    ro.yz *= rotMat(m.y*3.14);
    ro.xz *= rotMat(-m.x*6.2831);
#endif
    vec3 la = vec3(0,0,1.);
    vec3 rd = R(uv, ro, la,.7);

    float d = RayMarch(ro,rd).w;
    vec3 c = RayMarch(ro,rd).xyz;
    if (d<MAX_DIST){
        vec3 p = ro + rd*d;
        float difuse = GetLight(p);
        difuse = pow(difuse,.4545);
        col= vec3(difuse)*c;

    }

    col = mix(vec3(.8,.9,1.), col, exp(-max(0.,d-12.)/30.)  );  //Thanks to FabriceNeyret2 for the fog!
    //col = mix(vec3(.8,.9,1.), col, exp(-d/90.)  );
    glFragColor = vec4 (col,1.);

}
