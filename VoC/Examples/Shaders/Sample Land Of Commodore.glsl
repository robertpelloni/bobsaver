#version 420

// original https://www.shadertoy.com/view/tsfBWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// friol 2o2o
// crt effect from https://www.shadertoy.com/view/Ms23DR
// sdf functions and fake AO by iq
// music Clutter by Induktiv
//

const int iterationAmount=256;
const int numBalls=16;
vec4 ballsPositions[numBalls];

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

vec3 rotx(in vec3 p, float a) 
{
    return vec3(p.x,
                cos(a) * p.y + sin(a) * p.z,
                cos(a) * p.z - sin(a) * p.y);
}

vec3 roty(in vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.z,
                p.y,
                cos(a) * p.z - sin(a) * p.x);
}

vec3 rotz(in vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.y,
                cos(a) * p.y - sin(a) * p.x,
                p.z);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdPlane( vec3 p, vec4 n )
{
  return dot(p,n.xyz) + n.w;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCappedCylinder(vec3 p, vec3 a, vec3 b, float r)
{
  vec3  ba = b - a;
  vec3  pa = p - a;
  float baba = dot(ba,ba);
  float paba = dot(pa,ba);
  float x = length(pa*baba-ba*paba) - r*baba;
  float y = abs(paba-baba*0.5)-baba*0.5;
  float x2 = x*x;
  float y2 = y*y*baba;
  float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
  return sign(d)*sqrt(abs(d))/baba;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

vec2 SDF(vec3 r)
{
    vec3 rOrig=r;
    vec3 rDist=rOrig;
    float mat=0.0;
    float t=0.0;
    
    float logoDepth=.5;
    float bendAmt=.2;

    //r=roty(r,r.y*sin(time)*bendAmt);
    r=rotx(r,3.141592/2.0);
    //float cylouter=sdCappedCylinder(r,vec3(0.0,0.0,0.0),vec3(0.0,.6,0.0),1.0);
    //float cylinner=sdCappedCylinder(r,vec3(0.0,-2.0,0.0),vec3(0.0,1.7,0.0),0.58);

    float cylouter=sdRoundedCylinder(r,0.50,0.05,0.3);
    float cylinner=sdCappedCylinder(r,vec3(0.0,-2.0,0.0),vec3(0.0,logoDepth,0.0),0.58);
    
    t=opSubtraction(cylinner,cylouter);
    
    //vec3 rcb=roty(rOrig,rOrig.y*sin(time)*bendAmt);
    vec3 rcb=rOrig;
    float cuttingBox=sdBox(rcb-vec3(0.75,0.0,0.0),vec3(0.5,1.0,logoDepth));
    t=opSubtraction(cuttingBox,t);                           

    //vec3 r2=roty(rOrig,rOrig.y*sin(time)*bendAmt);
    vec3 r2=rotx(rOrig,3.141592);
    float upperVent=sdRoundBox(r2-vec3(.58,0.25,0.0),vec3(0.3,0.16,.3),0.03);
    t=min(t,upperVent);
    float lowerVent=sdRoundBox(r2-vec3(.58,-0.25,0.0),vec3(0.3,0.16,.3),0.03);
    t=min(t,lowerVent);

    //vec3 r3=roty(rOrig,rOrig.y*sin(time)*bendAmt);
    vec3 r3=rotz(rOrig,3.141592/4.01);
    float minusCube=sdBox(r3-vec3(0.8,-0.8,0.0),vec3(.45,.45,.5));
    
    t=opSubtraction(minusCube,t);
    float cbmLogo=t;

    float floorPlane=sdPlane(rDist-vec3(0.0,-0.1*sin(rDist.x)*2.0*cos(rDist.z),0.0),
                             vec4(0.0,1.0,0.0,1.0));
    t=min(floorPlane,t);

    float teeMin=100.0;
    for (int i=0;i<numBalls;i++)
    {
        float amigaBall=sdSphere(rOrig-vec3(2.0+ballsPositions[i].x,
                                            -0.7+abs(sin(time+ballsPositions[i].w)),
                                            ballsPositions[i].z),
                                             0.4+0.2*ballsPositions[i].w);
        t=min(amigaBall,t);
        teeMin=min(t,teeMin);
    }
    
    
    //
    
    if (t==cbmLogo) mat=0.0;
    else if (t==floorPlane) mat=1.0;
    else if (t==teeMin) mat=2.0;
    if (t==upperVent) mat=3.0;
    if (t==lowerVent) mat=4.0;
    
    return vec2(t,mat);   
}

vec3 calcNormal(vec3 pos)
{
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        // iOS fix
        //vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        vec3 e = 0.5773*(2.0*vec3(( mod(float((i+3)/2),2.0) ),(mod(float(i/2),2.0)),(mod(float(i),2.0)))-1.0);
        n += e*SDF(pos+0.0005*e)[0];
    }
    return normalize(n);
}

vec2 castRay(vec3 rayOrigin, vec3 rayDir)
{
    float t = 0.0;
     
    for (int i = 0; i < iterationAmount; i++)
    {
        vec2 res = SDF(rayOrigin + rayDir * t);
        if (res[0] < (0.0001*t))
        {
            return vec2(t,res[1]);
        }
        t += res[0];
    }
     
    return vec2(-1.0,-1.0);
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = SDF( aopos )[0];
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 Sky( vec3 ray )
{
    return mix( vec3(.8), vec3(0), exp2(-(1.0/max(ray.y,.01))*vec3(.4,.6,1.0)) );
}

float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

vec3 fog(vec3 c, float dist, vec3 fxcol)
{
    const float FOG_DENSITY = 0.06;
    vec3 FOG_COLOR = fxcol.xyz;
    
    float fogAmount = 1.0 - exp(-dist * FOG_DENSITY);
        
    return mix(c, FOG_COLOR, fogAmount);
}

vec4 bounceRender(vec3 rayOrigin, vec3 rayDir, vec2 uv)
{
    vec3 col=vec3(.52);
    vec3 L=normalize(vec3(1.0,0.2,-2.0));

    vec2 rayHit = castRay(rayOrigin, rayDir);
    float t=rayHit[0];

    if (t>0.0)
    {
        vec3 pHit=rayOrigin + rayDir * t;
        float mat=rayHit[1];
      
        if (mat==0.0)
        {
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            float NoL = max(dot(N, L), 0.0);
            col=vec3(NoL)*0.75;
            col+=vec3(.15,.15,.15);
        }        
        else if (mat==1.0)
        {
            float occ = calcAO( pHit, vec3(0.0,1.0,0.0) );
            float cdist=pow(distance(pHit,rayOrigin),1.202);
            //col=vec3(1.0)-vec3(.2)*ldist;
            col=vec3(0.5)*occ;
            
            //vec3 sky=Sky(rayDir);
            //col=mix(col,sky,cdist*0.02);
            
            float tee = -rayOrigin.y / rayDir.y;

            vec2 P = rayOrigin.xz + t * rayDir.xz;
            vec2 Q = floor(P);
            P = mod(P, 1.0);

            const float gridLineWidth = 0.1;

            float res = clamp(2048.0 / resolution.y, 1.0, 3.0);
            P = 1.0 - abs(P - 0.5) * 2.0;
            float d = clamp(min(P.x, P.y) / (gridLineWidth * clamp(tee + res * 2.0, 1.0, 2.0)) + 0.5, 0.0, 1.0);

            float shade = mix(hash(120.0 + Q * 0.1) * 0.4, 0.3, min(tee * tee * 0.001, 1.0)) + 0.6;
            vec3 colFloor= vec3(pow(d, 
                           clamp(150.0 / (pow(max(tee - 2.0, 0.1), res) + 1.0), 0.1, 31.0)
                      )) * shade + 0.1;            
            colFloor*=vec3(0.51,0.12,0.23);
            col=mix(colFloor,col,0.5);
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
        }
        else if (mat==2.0)
        {
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            vec3 q=N;
            vec2 matuv = vec2( atan(N.x,N.z), acos(N.y ) );
            vec2 qp = floor(matuv*2.51);
            float intensity=mod( qp.x+qp.y, 2.0 );
            if (intensity==1.0) col=vec3(1.0,0.0,0.0);
            else col=vec3(1.0);
            float NoL = max(dot(N, L), 0.2);
            col*=NoL;

            float cdist=pow(distance(pHit,rayOrigin),1.202);
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
        }
        else if ((mat==3.0)||(mat==4.0))
        {
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            float NoL = max(dot(N, L), 0.0);
            col=vec3(NoL)*0.75;
            if (mat==4.0) col+=vec3(231.0/256.0,12.0/256.0,52.0/256.0);
            else col+=vec3(0.0,112.0/256.0,232.0/256.0);
            float cdist=pow(distance(pHit,rayOrigin),1.202);
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
            col/=4.0;
        }
    }
    else
    {
        vec3 sk=Sky(rayDir);
        col=vec3(clamp(sk.x,0.0,1.0),clamp(sk.y,0.0,1.0),clamp(sk.z,0.0,1.0));
        //col=vec3(1.0,0.0,0.0);
    }

    //col=pow(col,vec3(0.58));
    return vec4(col,1.0);
}

vec4 render(vec3 rayOrigin, vec3 rayDir, vec2 uv)
{
    vec3 col=vec3(0.);
    vec3 L=normalize(vec3(4.0,0.2,-2.0));

    vec2 rayHit = castRay(rayOrigin, rayDir);
    float t=rayHit[0];

    if (t>0.0)
    {
        vec3 pHit=rayOrigin + rayDir * t;
        float mat=rayHit[1];
      
        if (mat==0.0)
        {
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            float NoL = max(dot(N, L), 0.0);
            col=vec3(NoL)*0.75;
            col+=vec3(.15,.15,.15);
            vec4 colReflect=bounceRender(pHit,N,uv);
            col=mix(col,colReflect.xyz,0.8);

            float cdist=pow(distance(pHit,rayOrigin),1.202);
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
        }
        else if (mat==1.0)
        {
            float occ = calcAO( pHit, vec3(0.0,1.0,0.0) );
            float cdist=pow(distance(pHit,rayOrigin),1.202);
            //col=vec3(1.0)-vec3(.2)*ldist;
            col=vec3(0.5)*occ;
            
            //vec3 sky=Sky(rayDir);
            //col=mix(col,sky,cdist*0.02);
            
            float tee = -rayOrigin.y / rayDir.y;

            vec2 P = rayOrigin.xz + t * rayDir.xz;
            vec2 Q = floor(P);
            P = mod(P, 1.0);

            const float gridLineWidth = 0.05;

            float res = clamp(2048.0 / resolution.y, 1.0, 3.0);
            P = 1.0 - abs(P - 0.5) * 2.0;
            float d = clamp(min(P.x, P.y) / (gridLineWidth * clamp(tee + res * 2.0, 1.0, 2.0)) + 0.5, 0.0, 1.0);

            float shade = mix(hash(120.0 + Q * 0.1) * 0.4, 0.3, min(tee * tee * 0.001, 1.0)) + 0.6;
            vec3 colFloor= vec3(pow(d, 
                           clamp(150.0 / (pow(max(tee - 2.0, 0.1), res) + 1.0), 0.1, 31.0)
                      )) * shade + 0.1;            
            
            colFloor*=vec3(0.51,0.12,0.23);
/*
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            float NoL = max(dot(N, L), 0.0);
            NoL=pow(NoL,32.0);
            col*=NoL*4.0;
*/
            col=mix(colFloor,col,0.5);
            
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
        }
        else if (mat==2.0) // amiga balls
        {
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            vec3 q=N;
            vec2 matuv = vec2( atan(N.x,N.z), acos(N.y ) );
            vec2 qp = floor(matuv*2.51);
            float intensity=mod( qp.x+qp.y, 2.0 );
            if (intensity==1.0) col=vec3(1.0,0.0,0.0);
            else col=vec3(1.0);
            float NoL = max(dot(N, L), 0.1);
            col*=NoL;
            col+=pow(NoL,32.0);

            vec4 colReflect=bounceRender(pHit,N,uv);
            col=mix(col,colReflect.xyz,0.7);

            float cdist=pow(distance(pHit,rayOrigin),1.202);
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
        }
        else if ((mat==3.0)||(mat==4.0))
        {
            vec3 N=calcNormal(rayOrigin + rayDir * t);
            float NoL = max(dot(N, L), 0.0);
            col=vec3(NoL)*0.75;
            if (mat==4.0) col+=vec3(231.0/256.0,12.0/256.0,52.0/256.0);
            else col+=vec3(0.0,112.0/256.0,232.0/256.0);
            vec4 colReflect=bounceRender(pHit,N,uv);
            col=mix(col,colReflect.xyz,0.6);

            float cdist=pow(distance(pHit,rayOrigin),1.202);
            col=fog(col,pow(cdist,.7642),Sky(rayDir));
        }
        else
        {
            col=vec3(1.0,1.0,0.0);
        }
        
    }
    else
    {
        col=Sky(rayDir);
    }

    col=pow(col,vec3(0.58));
    return vec4(col,1.0);
}

vec3 getCameraRayDir(vec2 uv, vec3 camPos, vec3 camTarget)
{
    vec3 camForward = normalize(camTarget - camPos);
    vec3 upz=vec3(0.,1.,0.);
    vec3 camRight = normalize(cross(upz, camForward));
    vec3 camUp = normalize(cross(camForward, camRight));
     
    float fPersp = 2.0;
    vec3 vDir = normalize(uv.x * camRight + uv.y * camUp + camForward * fPersp);
 
    return vDir;
}

vec2 normalizeScreenCoords(vec2 screenCoord)
{
    vec2 result = 2.0 * (screenCoord/resolution.xy - 0.5);
    result.x *= resolution.x/resolution.y;
    return result;
}

float onelinerRandom(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void initBalls()
{
    float ballSpread=16.0;
    int seed=234;
    for (int b=0;b<numBalls;b++)
    {
        float x=-ballSpread/2.0+onelinerRandom(vec2(seed))*ballSpread; seed+=0x42;
        float y=onelinerRandom(vec2(seed))*3.141592*2.0; seed+=0x42;
        float z=-ballSpread/2.0+onelinerRandom(vec2(seed))*ballSpread; seed+=0x42;
        float delta=onelinerRandom(vec2(seed));
        ballsPositions[b]=vec4(x,y,z,delta);        
    }
}

vec2 curve(vec2 uv)
{
    uv = (uv - 0.5) * 2.0;
    uv *= 1.1;    
    uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
    uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
    uv  = (uv / 2.0) + 0.5;
    uv =  uv *0.92 + 0.04;
    return uv;
}

void main(void)
{
    initBalls();
    
    float myTime=(time+1.34)/2.0;
    vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);

    vec3 camPos,camTarget;

    float radius=4.0;
    camPos = vec3(radius*sin(myTime),1.0+cos(myTime/4.0)*0.9,-radius*cos(myTime));
    camTarget = vec3(0.0,0.,0.0);
    
    vec3 rayDir = getCameraRayDir(uv, camPos, camTarget);   

    vec4 finalCol = vec4(render(camPos, rayDir,uv).xyz,1.0);
    //vec4 col=finalCol;
    
    vec2 coord = (uv - 0.5) * (resolution.x/resolution.y) * 2.0;
    vec2 uv2 = gl_FragCoord.xy / resolution.xy;
    vec3 col = finalCol.rgb;
    col=clamp(col*0.6+0.4*col*col*1.0,0.0,1.0);
    float vig = (0.0 + 1.0*16.0*uv2.x*uv2.y*(1.0-uv2.x)*(1.0-uv2.y));
    col *= vec3(pow(vig,0.3));
    col *= vec3(0.95,0.90,0.95)*2.7;
    float scans = clamp( 0.35+0.35*sin(3.5*time+uv2.y*resolution.y*1.5), 0.0, 1.0);
    float s = pow(scans,1.7);
    col = col*vec3( 0.4+0.7*s) ;
    col *= 1.0+0.01*sin(110.0*time);
    col*=1.0-0.65*vec3(clamp((mod(gl_FragCoord.xy.x, 2.0)-1.0)*2.0,0.0,1.0));
    float comp = smoothstep( 0.1, 0.9, sin(time) );
    
    //vec3 col2=mix(col,finalCol.rgb,0.5);
    //col=mix(col,finalCol.rgb,(1.0-pow(distance(uv,vec2(0.0,0.0)),0.039))/1.0);
    col=mix(col,finalCol.rgb,0.4);
    
    glFragColor=vec4(col.rgb, 1.0);
}
