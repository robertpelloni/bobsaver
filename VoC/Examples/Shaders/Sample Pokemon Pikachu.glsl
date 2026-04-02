#version 420

// original https://www.shadertoy.com/view/ldKfzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define mul(a,b) ((b)*(a))
#define saturate(a) clamp(a,0.0,1.0)

struct ObjectData
{
    float     distance;
    float     materialId;
    mat4      world2LocalMatrix;
};

#define Degree2Raduis(a) ((a) * 3.1415926 / 180.0)
#define Raduis2Degree(a) ((a) * 180.0 / 3.1415926)

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rand2(vec2 p)
{
    return vec2(rand(p.xy),rand(p.yx));
}

float SmoothStep_WithPower(float x,float dist,float pownum)
{
    return clamp(pow(x / dist,pownum),0.0,1.0);
}

float max2(vec2 a)
{
    return max(a.x,a.y);
}

float min2(vec2 a)
{
    return min(a.x,a.y);
}

float max3(vec3 a)
{
    return max(a.x,max(a.y,a.z));
}

float min3(vec3 a)
{
    return min(a.x,min(a.y,a.z));
}

float max4(vec4 a)
{
    return max(a.x,max(a.y,max(a.z,a.w)));
}

float min4(vec4 a)
{
    return min(a.x,min(a.y,min(a.z,a.w)));
}

vec3 RGBtoHSV(vec3 arg1)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 P = mix(vec4(arg1.bg, K.wz), vec4(arg1.gb, K.xy), step(arg1.b, arg1.g));
    vec4 Q = mix(vec4(P.xyw, arg1.r), vec4(arg1.r, P.yzx), step(P.x, arg1.r));
    float D = Q.x - min(Q.w, Q.y);
    float E = 1e-10;
    return vec3(abs(Q.z + (Q.w - Q.y) / (6.0 * D + E)), D / (Q.x + E), Q.x);
}

vec3 HSVtoRGB(vec3 arg1)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 P = abs(fract(arg1.xxx + K.xyz) * 6.0 - K.www);
    return arg1.z * mix(K.xxx, clamp(P - K.xxx,0.0,1.0), arg1.y);
}

void sincos(float a,out float si,out float co)
{
    si = sin(a);
    co = cos(a);
}

mat3 FromQuaternion(vec4 q)
{
    mat3 m;
    vec2 a;
    sincos(q.w,a.x,a.y);

    m[0] = vec3(a.y + q.x*q.x*(1.0-a.y), q.x*q.y*(1.0-a.y), q.y*a.x);
    m[1] = vec3(q.x*q.y*(1.0-a.y), a.y + q.y*q.y*(1.0-a.y), -q.x*a.x);
    m[2] = vec3(-q.y*a.x, q.x*a.x, a.y);
    
    return m;
}

vec3 RotateQuaternion(vec3 p,vec4 q)
{
    return mul(FromQuaternion(q),p);
}

mat3 FromEuler(vec3 ang) 
{   
    vec2 a1,a2,a3;
    sincos(Degree2Raduis(ang.x),a1.x,a1.y);
    sincos(Degree2Raduis(ang.y),a2.x,a2.y);
    sincos(Degree2Raduis(ang.z),a3.x,a3.y);

    mat3 m;
    m[0] = vec3(a3.y*a2.y,-a3.x*a2.y,a2.x);
    m[1] = vec3(a3.x*a1.y + a1.x*a2.x*a3.y,a3.y*a1.y - a1.x*a2.x*a3.x,-a1.x*a2.y);
    m[2] = vec3(a1.x*a3.x - a1.y*a2.x*a3.y,a3.y*a1.x + a1.y*a2.x*a3.x,a1.y*a2.y);
    return m;
}

vec3 RotateEuler(vec3 p,vec3 ang,vec3 scale)
{   
    mat3 rot = FromEuler(ang);
    rot[0] *= 1.0/scale.x;
    rot[1] *= 1.0/scale.y;
    rot[2] *= 1.0/scale.z;

    return mul(rot,p);
}

vec3 RotateEuler(vec3 p,vec3 ang)
{
    return mul(FromEuler(ang),p);
}

float Noise(vec2 v)
{
    vec2 i = floor(v);
    vec2 t = fract(v);
    vec2 u  = t*t*(3.0-2.0*t);

    return mix(mix(rand(i + vec2(0.0,0.0)),rand(i + vec2(1.0,0.0)),u.x),
                mix(rand(i + vec2(0.0,1.0)),rand(i + vec2(1.0,1.0)),u.x),
                u.y);
}

mat3 SetCamera(vec3 ro,vec3 ta)
{
    vec3 rz = normalize(ta - ro);
    vec3 p = vec3(0.0, 1.0, 0.0);
    vec3 rx = normalize(cross(rz,p));
    vec3 ry = normalize(cross(rz,rx));

    return mat3(-rx,ry,rz);
}

//Union
float OpU(float o1,float o2)
{
    return min(o1,o2);
}

//Smooth Union
float OpSU(float o1,float o2,float k)
{
    float h = clamp( 0.5+0.5*(o2-o1) / k, 0.0, 1.0 );
    return mix( o2, o1, h ) - k*h*(1.0-h);
}

//Smooth Intersection
float OpSI(float o1,float o2,float k)
{
    return -OpSU(-o1,-o2,k);
}

//subtract
float OpS(float o1,float o2)
{
    return max(o1,-o2);
}

//Intersection
float OpI(float o1,float o2)
{   
    return max(o1,o2);
}

//Union
vec2 OpU2(vec2 o1,vec2 o2)
{
    return o1.x < o2.x ? o1 : o2;
}

ObjectData OpU_OD(ObjectData o1,ObjectData o2)
{
    if(o1.distance < o2.distance)
    {
        return o1;
    }
    return o2;
}

float sdSphere(vec3 p,float r)
{
    return length(p) - r;
}

float sdBox(vec3 p,vec3 b)
{
    vec3 d = abs(p) - b;
    return min(max3(d),0.0) + length(max(d,0.0));
}

float udBox(vec3 p,vec3 b)
{
    vec3 d = abs(p) - b;
    return length(max(d,0.0));
}

float udRoundBox(vec3 p,vec3 b,float r)
{
    vec3 d = abs(p) - b;
    return length(max(d,0.0)) - r;
}

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdCylinder( vec3 p, vec3 c )
{
    return length(p.xz-c.xy)-c.z;
}

float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float sdPlane( vec3 p, vec4 n )
{
    // n must be normalized
    return dot(p,n.xyz) + n.w;
}

float sdCapsule( vec3 p,vec2 h)
{
    float  d = p.y;
    d = clamp(d,-h.y,h.y);
    p.y -= d;
    return length(p) - h.x;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max2(d),0.0) + length(max(d,0.0));
}

//x:outter radius 
//y:half height 
//z:inner radius
float sdSphericalShell(vec3 p,vec3 h)
{
    float d = length(p);
    float t = smoothstep(0.0,h.y,abs(p.y));
    return mix(max(d - h.x,-(d - (h.x - h.z))),OpS(sdCappedCylinder(p,h.xy),sdCappedCylinder(p,h.xy-vec2(h.z,0))),t);
}

float sdSphericalShell2(vec3 p,vec3 h)
{
    float d = length(p);
    float t = smoothstep(0.0,h.y,p.y);
    return mix(d - h.x,sdCappedCylinder(p,h.xy),t);
}

float sdCosCurve(vec3 p,vec2 h,vec3 c)
{   
    p.x += c.x*cos(p.y / h.y * 3.1415926 * c.y);
    p.z -= c.z*c.x*cos(p.y / h.y * 3.1415926);
    p.y -= c.z*c.x*sin(p.y / h.y * 3.1415926);
    return sdCapsule(p,h);
}

float sdHalfSphere( vec3 p, vec2 h )
{
    return mix(sdCappedCylinder(p,h),length(p) - h.x,float(p.y < 0.0));
}

float sdEllipsoid( vec3 p, vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

mat4 invMaterix(mat4 m)
{
    mat4 m2;
    mat3 m3;
    m3[0] = m[0].xyz;
    m3[1] = m[1].xyz;
    m3[2] = m[2].xyz;
    
    mat3 m1 = transpose(m3);

    vec3 t = mul(m1,vec3(m[0].w,m[1].w,m[2].w));

    m2[0] = vec4(m1[0],-t.x);
    m2[1] = vec4(m1[1],-t.y);
    m2[2] = vec4(m1[2],-t.z);
    m2[3] = vec4(0.0,0.0,0.0,1.0);

    return m2;
}

mat4 trs(vec3 translate,vec3 angle,vec3 scale)
{
    mat3 rot = FromEuler(angle);
    mat4 mat;

    rot[0] *= 1.0/scale.x;
    rot[1] *= 1.0/scale.y;
    rot[2] *= 1.0/scale.z;

    mat[0] = vec4(rot[0],translate.x);
    mat[1] = vec4(rot[1],translate.y);
    mat[2] = vec4(rot[2],translate.z);
    mat[3] = vec4(0.0,0.0,0.0,1.0);

    return mat;
}

vec3 mulMat(mat4 mat,vec3 p)
{
    vec4 p2 = mul(mat,vec4(p.xyz,1.0));
    return p2.xyz;
}

mat4 transMat(mat4 mat,vec3 t)
{
    mat[0].w += t.x;
    mat[1].w += t.y;
    mat[2].w += t.z;
    return mat;
}

mat4 rotMat(mat4 mat,vec3 a)
{
    mat3 rot = FromEuler(a);
    mat4 m;

    m[0] = vec4(rot[0],0.0);
    m[1] = vec4(rot[1],0.0);
    m[2] = vec4(rot[2],0.0);
    m[3] = vec4(0.0,0.0,0.0,1);

    m = mul(m,mat);

    return m;
}

mat4 scaleMat(mat4 mat,vec3 s)
{
    mat[0].xyz *= 1.0 / s.x;
    mat[1].xyz *= 1.0 / s.y;
    mat[2].xyz *= 1.0 / s.z;

    return mat;
}

ObjectData createObject(float d,float m,mat4 w2l)
{
    ObjectData od;
    od.distance = d;
    od.materialId = m;
    od.world2LocalMatrix = w2l;

    return od;
}

ObjectData createObject(float d,float m)
{
    mat4 w2l;
    w2l[0] = vec4(1.0,0.0,0.0,0.0);
    w2l[1] = vec4(0.0,1.0,0.0,0.0);
    w2l[2] = vec4(0.0,0.0,1.0,0.0);
    w2l[3] = vec4(0.0,0.0,0.0,1.0);
    
    return createObject(d,m,w2l);
}

ObjectData PikaHeadObjective(vec3 p)
{   
    float  move = sign(sin(time)) * abs(sin(time*1.0))*0.2;
    move = max(0.0,move);

    vec3 rotate = vec3(0.0,time*100.0,0.0);
    rotate = vec3(0.0,0.0,0.0);
    mat4 w2l = trs(vec3(0.0,move,0.0),rotate,vec3(1.0,1.0,1.0));

    vec3 localPos = mulMat(w2l,p);

    float  earAngle = mix(30.0,50.0,0.5 + 0.5 * sin(time*10.0));
    //earAngle = 45;

    vec3 head1Pos = localPos;
    vec3 head2Pos = localPos + vec3(0.0,-0.11,0.0);
    vec3 leftEar1Pos = RotateEuler(localPos - vec3(0.2,0.0,0.0),vec3(0.0,0.0,earAngle)) + vec3(0.2 - 0.36,0.16,0.0);
    vec3 rightEar1Pos = RotateEuler(localPos - vec3(-0.2,0.0,0.0),vec3(0.0,0.0,-earAngle)) + vec3(-0.2 + 0.36,0.16,0.0);
    vec3 leftEarClipPos = leftEar1Pos + vec3(-0.15,-0.03,0.0);
    vec3 rightEarClipPos = rightEar1Pos + vec3(0.15,-0.03,0.0);
    vec3 nosePos = localPos + vec3(0.0,-0.02,-0.21-0.01);

    vec3 leftEye1Pos = localPos + vec3(-0.1,0.04,-0.21 + 0.065);
    vec3 rightEye1Pos = localPos + vec3(0.1,0.04,-0.21 + 0.065);
    vec3 leftEye2Pos = leftEye1Pos + vec3(-0.01,0.015,-0.05 + 0.015);
    vec3 rightEye2Pos = rightEye1Pos + vec3(0.01,0.015,-0.05 + 0.015);
    vec3 leftFacePos = localPos + vec3(-0.14,-0.07,-0.21 + 0.12);
    vec3 rightFacePos = localPos + vec3(0.14,-0.07,-0.21 + 0.12);

    vec3 mouthPos = RotateEuler(localPos,vec3(0.0,0.0,-90)) + vec3(-0.07,0.0,-0.21 - 0.011);
    vec3 tonguePos = localPos;

    ObjectData head1 = createObject(sdSphere(head1Pos,0.21),8.0,w2l);
    ObjectData head2 = createObject(sdTorus(head2Pos,vec2(0.08,0.07)),8.0,w2l);

    ObjectData leftEar1 = createObject(sdEllipsoid(leftEar1Pos,vec3(0.2,0.05,0.045)),8.0,w2l);
    ObjectData rightEar1 = createObject(sdEllipsoid(rightEar1Pos,vec3(0.2,0.05,0.045)),8.0,w2l);

    ObjectData leftEar2 = leftEar1;
    leftEar2.materialId = 10.0;
    ObjectData rightEar2 = rightEar1;
    rightEar2.materialId = 10.0;

    ObjectData leftEarClip = createObject(sdSphere(leftEarClipPos,0.1),8.0,w2l);
    ObjectData rightEarClip = createObject(sdSphere(rightEarClipPos,0.1),8.0,w2l);

    ObjectData nose = createObject(sdEllipsoid(nosePos,vec3(0.015,0.01,0.01)),2.0,w2l);

    ObjectData leftEye1 = createObject(sdSphere(leftEye1Pos,0.05),2.0,w2l);
    ObjectData rightEye1 = createObject(sdSphere(rightEye1Pos,0.05),2.0,w2l);
    ObjectData leftEye2 = createObject(sdSphere(leftEye2Pos,0.016),3.0,w2l);
    ObjectData rightEye2 = createObject(sdSphere(rightEye2Pos,0.016),3.0,w2l);

    ObjectData leftFace = createObject(sdSphere(leftFacePos,0.08),9.0,w2l);
    ObjectData rightFace = createObject(sdSphere(rightFacePos,0.08),9.0,w2l);

    ObjectData mouse = createObject(sdCosCurve(mouthPos,vec2(0.003,0.06),vec3(0.01,1.5,0.3)),2.0,w2l);

    leftEar1.distance = OpS(leftEar1.distance,leftEarClip.distance);
    rightEar1.distance = OpS(rightEar1.distance,rightEarClip.distance);

    leftEar2.distance = OpI(leftEar2.distance,leftEarClip.distance);
    rightEar2.distance = OpI(rightEar2.distance,rightEarClip.distance);

    head1.distance = OpSU(head1.distance,head2.distance,0.2);
    head1.distance = OpSU(head1.distance,leftEar1.distance,0.04);
    head1.distance = OpSU(head1.distance,rightEar1.distance,0.04);

    head1 = OpU_OD(head1,leftEar2);
    head1 = OpU_OD(head1,rightEar2);
    head1 = OpU_OD(head1,leftEye1);
    head1 = OpU_OD(head1,rightEye1);
    head1 = OpU_OD(head1,leftEye2);
    head1 = OpU_OD(head1,rightEye2);
    head1 = OpU_OD(head1,leftFace);
    head1 = OpU_OD(head1,rightFace);
    head1 = OpU_OD(head1,nose);
    head1 = OpU_OD(head1,mouse);

    ObjectData obj = head1;

    return obj;
}

ObjectData BallObjective(vec3 p)
{
    vec3 rotate = vec3(20.0,60.0,-20.0);
    //rotate = vec3(0,_Time.y*100,0);
    mat4 w2l = trs(vec3(0.0,0.0,0.0),rotate,vec3(3.0,3.0,3.0));

    vec3 localPos = mulMat(w2l,p);

    float  openBallAngle = sign(sin(time)) * abs(sin(time*1.0))*90.0;

    openBallAngle = max(0.0,openBallAngle);

    vec3 p1 = RotateEuler(localPos + vec3(0.2,0.0,0.0),vec3(0.0,0.0,openBallAngle)) - vec3(0.2,0.0,0.0);
    vec3 p2 = RotateEuler(localPos,vec3(0.0,0.0,180.0));
    vec3 p3 = RotateEuler(localPos + vec3(0.2,0.0,0.0),vec3(0.0,0.0,90.0 + openBallAngle)) + vec3(0.0,-0.4,0.0);
    vec3 p4 = RotateEuler(localPos + vec3(0.2,0.0,0.0),vec3(0.0,0.0,90.0 + openBallAngle)) + vec3(0.0,-0.41,0.0);
    vec3 p5 = RotateEuler(localPos + vec3(0.2,0.0,0.0), vec3(0.0,0.0,openBallAngle)) - vec3(0.2,0.0,0.0) + vec3(0.0,0.005,0.0);
    vec3 p6 = RotateEuler(localPos , vec3(0.0,0.0,0.0)) - vec3(0.0,0.005,0.0);

    ObjectData obj1_0 = createObject(sdHalfSphere(p1,vec2(0.2,0.0005)),12.0,w2l);
    ObjectData obj2_0 = createObject(sdHalfSphere(p2,vec2(0.2,0.0005)),11.0,w2l);

    ObjectData obj1_1 = createObject(sdHalfSphere(p1,vec2(0.18,0.0005)),12.0,w2l);
    ObjectData obj2_1 = createObject(sdHalfSphere(p2,vec2(0.18,0.0005)),11.0,w2l);

    ObjectData obj3 = createObject(sdCappedCylinder(p3,vec2(0.03,0.005)),11.0,w2l);
    ObjectData obj4 = createObject(sdCappedCylinder(p4,vec2(0.01,0.002)),11.0,w2l);

    ObjectData obj5 = createObject(sdSphericalShell(p5 ,vec3(0.2005,0.005,0.005)),2.0,w2l);
    ObjectData obj6 = createObject(sdSphericalShell(p6,vec3(0.2005,0.005,0.005)),2.0,w2l);

    obj1_0.distance = OpS(obj1_0.distance,obj1_1.distance);
    obj2_0.distance = OpS(obj2_0.distance,obj2_1.distance);

    ObjectData obj = OpU_OD(obj1_0,obj2_0);
    obj = OpU_OD(obj,obj3);
    obj = OpU_OD(obj,obj4);
    obj = OpU_OD(obj,obj5);
    obj = OpU_OD(obj,obj6);

    return obj;
}

ObjectData ObjectsGroup(vec3 p)
{   
    //return TestObjective(p);
    ObjectData pikahead = PikaHeadObjective(p);
    ObjectData pokemonBall = BallObjective(p);
    //return pikahead;
    return OpU_OD(pikahead,pokemonBall);
}

float SoftShadow(vec3 ro, vec3 rd, float mint, float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i = 0; i < 16; i++ )
    {
        float h = ObjectsGroup( ro + rd*t ).distance;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

#define RAYMARCH_STEP_NUM 256
ObjectData Raymarching(vec3 ro, vec3 rd)
{
    float tmin = 1.0;
    float tmax = 10.0;
    
    float t = tmin;
    float m = -1.0;
    float n = 0.5e-8;
    mat4 w2l;

    for( int i = 0; i < RAYMARCH_STEP_NUM; i++ )
    {
        float precis = n*t;
        ObjectData res = ObjectsGroup( ro + rd*t );
        if( res.distance < precis || t > tmax ) break;
        t += res.distance;
        m = res.materialId;
        w2l = res.world2LocalMatrix;
    }

    if(t > tmax) m = -1.0;

    ObjectData data = createObject(t,m,w2l);

    return data;
}

float Fbm(vec2 p)
{
    int octaves = 12;
    float lacunarity = 0.5;
    float gain = 2.0;
    float sum = 0.0;
    float freq = 2.0, amp = 1.1;
    for(int i = 0; i < octaves; i ++)
    {
        float n = Noise(p * freq);
        sum += n * amp;
        freq *= lacunarity;
        amp *= gain;
    }

    return sum;
}

vec3 CalcNormal(vec3 pos)
{
    vec3 eps = vec3( 0.0005, 0.0, 0.0 );
    vec3 nor = vec3(
        ObjectsGroup(pos+eps.xyy).distance - ObjectsGroup(pos-eps.xyy).distance,
        ObjectsGroup(pos+eps.yxy).distance - ObjectsGroup(pos-eps.yxy).distance,
        ObjectsGroup(pos+eps.yyx).distance - ObjectsGroup(pos-eps.yyx).distance );

    return normalize(nor);
}

vec4 RenderOutline(vec3 position,vec3 normal,vec3 lightDir,vec3 viewDir,vec3 diffuseColor,float shadow)
{
    float aa = 1.0 - saturate(pow(1.0 - max(0.0,dot(normal,viewDir)),16.0));

    return vec4(diffuseColor,1.0);
}

vec4 RenderMaterial0(vec3 localPos,vec3 position,vec3 normal,vec3 lightDir,vec3 viewDir,vec3 diffuseColor,float shadow)
{
    viewDir = normalize(viewDir);
    float wise = 0.1;
    float ndl = ((dot(normal,lightDir)*0.5+0.5) + wise) / (1.0 + wise);

    vec3 ref = reflect(lightDir,normal);

    float rdv = max(0.0,dot(ref,-viewDir));

    float aa = 1.0 - saturate(pow(1.0 - max(0.0,dot(normal,viewDir)),16.0));

    return vec4(diffuseColor * ndl + pow(rdv,35.0),aa);
}

vec4 RenderMaterial1(vec3 localPos,vec3 position,vec3 normal,vec3 lightDir,vec3 viewDir,vec3 diffuseColor,float shadow)
{
    viewDir = normalize(viewDir);
    float wise = 0.1;
    float ndl = ((dot(normal,lightDir)*0.5+0.5) + wise) / (1.0 + wise);

    vec3 p = (localPos);

    diffuseColor = mix(diffuseColor,vec3(1.0,1.0,0.0),Fbm(vec2(length(p.xy),p.z)));

    vec3 ref = reflect(lightDir,normal);

    float rdv = max(0.0,dot(ref,-viewDir));

    float aa = 1.0 - saturate(pow(1.0 - max(0.0,dot(normal,viewDir)),16.0));

    return vec4(diffuseColor * ndl + pow(rdv,35.0),aa);
}

vec4 RenderMaterial2(vec3 localPos,vec3 position,vec3 normal,vec3 lightDir,vec3 viewDir,vec3 diffuseColor,float shadow)
{
    viewDir = normalize(viewDir);
    float wise = 0.1;
    float ndl = ((dot(normal,lightDir)*0.5+0.5) + wise) / (1.0 + wise);

    vec3 p = normalize(localPos);
    diffuseColor = mix(diffuseColor,vec3(1,0,1),Fbm(vec2(length(p.xy),p.z)));

    vec3 ref = reflect(lightDir,normal);

    float rdv = max(0.0,dot(ref,-viewDir));

    float aa = 1.0 - saturate(pow(1.0 - max(0.0,dot(normal,viewDir)),16.0));

    return vec4(diffuseColor * ndl + pow(rdv,35.0),aa);
}

vec4 RenderMaterial4(vec3 localPos,vec3 position,vec3 normal,vec3 lightDir,vec3 viewDir,vec3 diffuseColor,float shadow)
{
    viewDir = normalize(viewDir);
    
    float ndl = dot(normal,lightDir)*0.5+0.5;

    float rampSmooth = 0.005;
    float threshold1 = 0.5;
    float threshold2 = 0.2;
    float rampThresholdBlend = 0.7;

    float ramp1 = smoothstep(threshold1 - rampSmooth, threshold1,ndl);
    float ramp2 = smoothstep(threshold2 - rampSmooth, threshold2,ndl);

    float ramp = mix(0.0,mix(mix(threshold2,threshold1,rampThresholdBlend) ,1.0,ramp1),ramp2);

    vec3 diffuseHsv = RGBtoHSV(diffuseColor);
    vec3 shadowHsv = RGBtoHSV(vec3(0.1,0.3,0.3));

    diffuseColor = HSVtoRGB(vec3(diffuseHsv.rg,mix(shadowHsv.b,diffuseHsv.b,ramp)));

    vec3 ref = reflect(lightDir,normal);

    float rdv = max(0.0,dot(ref,-viewDir));

    float aa = 1.0 - saturate(pow(1.0 - max(0.0,dot(normal,viewDir)),16.0));

    float outline = smoothstep(0.09,0.18,pow(max(0.0,dot(normal,viewDir)*0.9+0.1),1.4478));

    vec3 finalColor = mix(vec3(0.0,0.0,0.0),diffuseColor + 0.15*pow(rdv,35.0),outline);

    return vec4(finalColor*max(shadow,0.4),aa);
}

vec4 RenderMaterial5(vec3 localPos,vec3 position,vec3 normal,vec3 lightDir,vec3 viewDir,vec3 diffuseColor,float shadow)
{
    viewDir = normalize(viewDir);
    
    float ndl = dot(normal,lightDir)*0.5+0.5;

    float ramp = ndl;
    
    vec3 diffuseHsv = RGBtoHSV(diffuseColor);
    vec3 shadowHsv = RGBtoHSV(vec3(0.1,0.3,0.3));

    diffuseColor = HSVtoRGB(vec3(diffuseHsv.rg,mix(shadowHsv.b,diffuseHsv.b,ramp)));

    vec3 ref = reflect(lightDir,normal);

    float rdv = max(0.0,dot(ref,-viewDir));

    float aa = 1.0 - saturate(pow(1.0 - max(0.0,dot(normal,viewDir)),16.0));

    float outline = smoothstep(0.09,0.18,pow(max(0.0,dot(normal,viewDir)*0.9+0.1),1.4478));

    vec3 finalColor = mix(vec3(0,0,0),diffuseColor + 0.65*pow(rdv,35.0),outline);

    return vec4(finalColor*max(shadow,0.4),aa);
}

vec4 Render(vec3 orgPos,vec3 rayDir)
{
    vec4 color = vec4(0,0,0,0) ;

    ObjectData result = Raymarching(orgPos, rayDir);
    float  dist = result.distance;
    float  material = result.materialId;

    if(material >= 0.0)
    {
        mat4 w2l = result.world2LocalMatrix;
        vec3 position = orgPos + rayDir * dist;
        vec3 normal = CalcNormal(position);
        vec3 lightDir = normalize(vec3(0.5*sin(time*2.0),-1,1));
        vec3 diffColor = vec3(1,1,1);
        vec3 uViewDir = -rayDir * dist;
        vec3 localPos = mulMat(w2l,position);
        float  shadow = SoftShadow(position,lightDir,0.02, 2.5);

        mat4 w2l_2nd;
        w2l_2nd[0]=vec4(1,0,0,w2l[0].w);
        w2l_2nd[1]=vec4(0,1,0,w2l[1].w);
        w2l_2nd[2]=vec4(0,0,1,w2l[2].w);
        w2l_2nd[3]=vec4(0,0,0,1);
        

        vec3 localPos_2nd = mulMat(w2l_2nd,position);

        if(material == 1.0)
        {
            diffColor = vec3(1,0,0);
            color = RenderMaterial1(localPos_2nd,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 2.0)
        {
            diffColor = vec3(0,0,0);
            color = RenderOutline(position,normal,lightDir,uViewDir,diffColor,shadow);  
        }
        else if(material == 3.0)
        {
            diffColor = vec3(1,1,1);
            color = RenderOutline(position,normal,lightDir,uViewDir,diffColor,shadow);  
        }
        else if(material == 4.0)
        {
            diffColor = vec3(1,0,0);
            color = RenderMaterial2(localPos_2nd,position,normal,lightDir,uViewDir,diffColor,shadow);
        }
        else if(material == 6.0)
        {
            diffColor = vec3(1,0,0);
            color = RenderMaterial0(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 7.0)
        {
            diffColor = vec3(1,1,1);
            color = RenderMaterial0(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 8.0)
        {
            diffColor = vec3(1,1,0);
            color = RenderMaterial4(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 9.0)
        {
            diffColor = vec3(1,0,0);
            color = RenderMaterial4(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 10.0)
        {
            diffColor = vec3(0,0,0);
            color = RenderMaterial4(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 11.0)
        {
            diffColor = vec3(1,1,1);
            color = RenderMaterial4(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
        else if(material == 12.0)
        {
            diffColor = vec3(1,0,0);
            color = RenderMaterial5(localPos,position,normal,lightDir,uViewDir,diffColor,shadow);   
        }
    }

    return color;
}

void main(void)
{
    vec2 canvasPos = gl_FragCoord.xy / resolution.xy;
    vec2 screenSize = resolution.xy;
    vec2 pos = canvasPos * screenSize;
    vec2 orgPos = canvasPos * 2.0 - 1.0;
    orgPos.y *= screenSize.y/screenSize.x;

    vec3 cameraPos = vec3(0,0,3);
    vec3 lookAtPos = vec3(0,0,0);

    mat3 cameraMatrix = SetCamera(cameraPos,lookAtPos);

    vec3 rayDir = mul(cameraMatrix,normalize(vec3(orgPos,1)));

    vec4 skyBox = mix(vec4(1,1,1,1),vec4(0,0.3,1,1),pow(canvasPos.y,0.4));

    vec4 color = Render(cameraPos,rayDir);

    vec4 finialColor = vec4(mix(skyBox.rgb,color.rgb,color.a),skyBox.a);

    glFragColor = finialColor;
}

