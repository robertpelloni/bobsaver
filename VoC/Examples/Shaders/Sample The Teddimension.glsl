#version 420

// original https://www.shadertoy.com/view/cdSyRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// utils
float lerp(in float a, in float b, in float t) {
    return a * (1.0 -t) + b * t;
}

vec3 lerp(in vec3 a, in vec3 b, in float t) {
    return a * (1.0 -t) + b * t;
}

// material
struct Material {vec3 diffuse; float sheen; float specular; float specE;};
Material lerp(in Material a, in Material b, in float t) {
    return Material(lerp(a.diffuse, b.diffuse, t), 
    lerp(a.sheen, b.sheen, t),
    lerp(a.specular, b.specular, t),
    lerp(a.specE, b.specE, t)
    );
}

// polynomial smooth min
float smoothmin(in  float a, in float b, in float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float smoothmax(in  float a,in  float b,in  float k )
{
    return -smoothmin(-a,-b,k);
}

float smoothmin2(in  float a, in  float b, in  float r) {
    return - log(exp(-r*a) + exp(-r*b)) / r;
}

float smoothmax2(in  float a, in  float b, in  float r) {
    return log(exp(r*a) + exp(r*b)) / r;
}

float sdfSphere(in  vec3 pos,  in float radius) {
    return length(pos) - radius;
}

float sdfPrimXLine(in vec3 pos) {
    if(pos.x > 1.)
        return length(pos - vec3(0.,0.,1.));
    if(pos.x < 0.)
        return length(pos);
    return length(pos.yz); 
}

float length2(vec3 v) {
    return v.x*v.x + v.y*v.y + v.z*v.z;
}

float sdfPrimLine(in vec3 pos, in vec3 a, in vec3 b) {
    vec3 u = b-a;
    vec3 x = pos-a;
    if(dot(x, u) < 0.)
        return length(x);
    x = pos-b;
    if(dot(x, u) > 0.)
        return length(x);
    vec3 proj = cross(u, cross(u, x));
    return abs(dot(x,normalize(proj))); 
}

float sdfPrimCircle(in vec3 pos, in vec3 o, in float r, in vec3 n) {
    pos -= o;
    vec3 u = -cross(n, cross(n,pos));
    u = normalize(u);
    return length(pos-r*u);
}

float sdfPrimCone(in vec3 pos, in float slope, in vec3 axis, in vec3 origin) {
    pos -= origin;
    axis = normalize(axis);
    if(dot(axis,pos) < 0.) axis = -axis;
    // normal to the plane that contains the axis and pos
    vec3 n = cross(pos,axis);
    n = normalize(n);
    
    vec3 u = cross(axis, n);
    if(dot(pos,u) < 0.) u = -u;
    // tangent to the cone in that plane
    vec3 t = axis + slope * u;
    // normal to the cone in that plane
    vec3 proj = cross(t, n);
    return dot(pos, normalize(proj));
}

float sdfPrimPlane(in vec3 pos, in vec3 n) {
    return dot(pos, normalize(n));
}

vec3 bendCoords(in vec3 pos, in vec3 origin, in vec3 t, in vec3 n, in float amount) {
    vec3 p = pos-origin;
    n = normalize(n);
    t = normalize(t);
    mat3 mat = mat3(t,n,cross(t,n));
    mat3 inv = inverse(mat);
    p = inv * p;
    float c = cos(amount*p.x);
    float s = sin(amount*p.x);
    mat2  m = mat2(c,-s,s,c);
    return  mat * vec3(m*p.xy,p.z) + origin;
}

float sdfOutsideEar(in vec3 pos) {
    float radius = 0.07;
    vec3 center = vec3(0.12,1.14,-0);
    return sdfSphere(pos - center, radius);
}

float sdfInsideEar(in vec3 pos) {
    float radius = 0.07;
    vec3 center = vec3(0.12,1.14,-0);
    return sdfSphere(pos - center + vec3(0.,0.02,radius), radius*0.5);
}

float sdfEars(in vec3 pos) {
    float insideEar = sdfInsideEar(pos);
    float outsideEar = sdfOutsideEar(pos);
    return smoothmax(outsideEar, -insideEar, .1);
}

float sdfHead(in vec3 pos) {
    // sphere
    vec3 headPos = vec3(0.0,1.02,0.0);
    vec3 conePos = vec3(0.,1.5,0);
    float cone = sdfPrimCone(pos, .4, headPos-conePos, conePos);
    pos -= headPos;
    float isoSmooth= .4;
    float size = .2;
    float scale = 1. + isoSmooth/size;
    pos *= vec3(scale);

    float sd = sdfSphere(pos , size);
    
    
    // cutoff front and back
    sd = smoothmax(sd, pos.z - size * .5, size * 2.5);
    sd = smoothmax(sd, -pos.z - size * .5, size * 2.5);
    sd = smoothmax(sd, -pos.y + size * .1, size * 5.5);
    
    sd = (sd - isoSmooth) / scale;
    
    sd = smoothmax(sd, cone, .1);
    
    return sd;
}

float sdfFulcrum(in vec3 pos) {
    vec3 snoutCenter = vec3(0.0,1.05,-0.08);
    float snoutSize = .1;
    float fulcrum = sdfPrimCircle(pos, snoutCenter + vec3(.0,.00,+.11), snoutSize + .1, vec3(1.,0.,0.) - 0.001);
    fulcrum = sdfPrimLine(pos,vec3(0.,.99,-.16),vec3(0.,1.1,-.22)) -0.001;
    fulcrum = smoothmin(fulcrum, sdfPrimLine(pos,vec3(0.,.99,-.165),vec3(0.2,.88,-.02)) -0.001, 0.01);
    fulcrum = smoothmin(fulcrum, sdfPrimLine(pos,vec3(0.,.99,-.165),vec3(-0.2,.88,-.02)) -0.001, 0.01);
    return fulcrum;
}

float sdfSnout(in vec3 pos) {
    vec3 snoutCenter = vec3(0.0,1.05,-0.08);
    float snoutSize = .1;
    float snout = sdfSphere(pos-snoutCenter, snoutSize);
    snout = smoothmax(snout, pos.y-(snoutCenter.y+snoutSize * .1), snoutSize);
    float fulcrum = sdfFulcrum(pos);
    snout = smoothmax(snout, -fulcrum, 0.03); 
    return snout;
}

float sdfNose(in vec3 pos) {
    float nose = sdfSphere(pos-vec3(0.0,1.04,-0.16), .02);    
    float nostril = sdfSphere(pos-vec3(0.015,1.03,-0.168), .01);
    nose = smoothmax(nose, -nostril, 0.01);
    return smoothmax(nose, pos.y-1.055, 0.01);
}

float sdfEyes(in vec3 pos) {
    return sdfSphere(pos-vec3(0.06,1.07,-0.115), .015);
}

float sdfBelly(in vec3 pos) {
    float body= sdfSphere(pos-vec3(0.,0.7,0.02), .22);
    return smoothmin(body, sdfSphere(pos-vec3(0.,0.85,0.03), .12), 0.2);
}

float sdfArm(in vec3 pos) {
    float arm = sdfPrimCircle(pos, vec3(0.1,0.8,-0.05), .14, vec3(0.,1.,-.7)) - .065;
    arm = smoothmax(arm, -sdfPrimPlane(pos, vec3(1.5,1.2,.1)) + .62, .12);
    return arm;
}

float sdfLeg(in vec3 pos) {
    vec3 footPos = vec3(0.2,0.6,-0.28);
    vec3 legOri = vec3(0.1,0.6,0.);
    float leg=sdfPrimLine(pos, legOri, footPos) - .08;
    float foot = sdfSphere(pos-(footPos+vec3(0.,0.02,0.)), 0.11);
    foot = smoothmax(foot,sdfPrimPlane(pos, footPos-legOri) - 0.37, 0.06);
    
    //foot = smoothmax(foot,-sdfPrimCircle(mirrorXPos,footPos+vec3(.01,.025,-.018),0.1,footPos-legOri) + 0.002, 0.01);
    
    foot= smoothmax(foot, sdfPrimPlane(pos, vec3(1.1,0.,0.2)) - .27, 0.12);
    foot= smoothmax(foot, sdfPrimPlane(pos, -vec3(1.1,0.,0.2)) + .03, 0.12);
    
    leg = smoothmax(leg,sdfPrimPlane(pos, footPos-legOri) - 0.32, 0.035);
    leg = smoothmin(leg,foot,.01);
    return leg;
}

float sdfPaw(in vec3 pos) {
    vec3 footPos = vec3(0.2,0.6,-0.28);
    vec3 legOri = vec3(0.1,0.6,0.);
    float paw = sdfSphere(vec3(1.,0.98,1.) * (pos-(footPos+vec3(0.,0.04,0.))), 0.08);
    return paw;
}

float sdfPawPrint(in vec3 pos) {
    vec3 footPos = vec3(0.2,0.6,-0.28);
    vec3 legOri = vec3(0.1,0.6,0.);
    float pawPrint = sdfSphere(vec3(1.,1.5,1.) * (pos-(footPos+vec3(0.005,0.,-0.02))), 0.04);
    float dots = sdfSphere(vec3(1.,0.9,1.) * (pos-(footPos+vec3(0.015,0.08,-0.04))), 0.016);
    pawPrint = min(pawPrint, dots);
    dots = sdfSphere(vec3(1.,0.9,1.) * (pos-(footPos+vec3(0.053,0.055,-0.02))), 0.015);
    pawPrint = min(pawPrint, dots);
    dots = sdfSphere(vec3(1.,0.9,1.) * (pos-(footPos+vec3(-0.03,0.06,-0.05))), 0.015);
    pawPrint = min(pawPrint, dots);
    return pawPrint;
}

float sdfGround(vec3 pos){
    return pos.y - 0.54;
}

mat2x2 rot2(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c,s,-s,c);
}

vec3 sceneSymmetries(in vec3 pos) {
    vec3 symPos = pos.xyz;
    float tile = 1.7;
    symPos = mod(symPos + tile, 2. * tile) - tile;
    
    vec3 n = pos - symPos;
    mat2x2 rot = rot2(fract(6.5*sin(n.x) + 7.3 * sin(n.y) + 1.219 * sin(n.z)) * 4.);
    symPos.xz = rot * symPos.xz;
    
    symPos.x = abs(symPos.x); 
    
    
    return symPos;
}

vec4 sceneSDF(in vec3 pos) {
    vec3 symPos = sceneSymmetries(pos);
    
    // head
    float sd = sdfHead(symPos);
    
    // ears
    float ears = sdfEars(symPos);
    sd = smoothmin(sd, ears, 0.02);
    
    
    //snout
    
    float snout = sdfSnout(symPos);
    sd = smoothmin(sd, snout, 0.008);
    
    
    //nose
    float nose = sdfNose(symPos);
    
    
    sd = smoothmin(sd, nose, 0.005);
    
    
    // eyes
    float eyes = sdfEyes(symPos);
    sd = smoothmax(sd, -eyes - .0145, .05);
    sd = smoothmin(sd, eyes, .002);
    
    
    // body
    float belly = sdfBelly(symPos);
    sd = smoothmin(sd, belly, 0.02);
    
    // arm
    float arm = sdfArm(symPos);
    sd = min(sd, arm);
    
    // leg
    float leg = sdfLeg(symPos);       
    sd = smoothmin(sd, leg, 0.01);
    sd = smoothmax(sd, -pos.y + .5, 0.2);
    
    // ground
    float ground = sdfGround(pos);
    sd = min(sd,ground);
    
    return vec4(sd, pos);
}

vec4 rayMarch(in vec3 rayOrigin, in vec3 rayDir) {
    vec4 res = vec4(-1.0);
    
    float t = 0.001;
    float tmax = 100000.0;
    
    for(int i=0; i<1024 && t<tmax; i++) {
        vec4 h = sceneSDF(rayOrigin + t*rayDir);
        if( h.x < 0.001 ) { res = vec4(t, h.yzw); break; }
        t += h.x;
    }
    
    return res;
}

vec3 camToScene(in vec3 dir, in vec3 camDir, in vec3 camUp) {
    vec3 cZ = normalize(camDir);
    vec3 cX = normalize(cross(camUp, cZ));
    vec3 cY = cross(cZ,cX);
    mat3 camToSceneMat = mat3(cX,cY,cZ);
    return camToSceneMat * dir;
}

vec4 rayMarch(in vec2 pixel, in vec3 camPos, in vec3 camDir, in vec3 camUp, in float fov) {
    // vec3 dir = vec3( tan(fov) / resolution.x * pixel, 1.0); // pixel direction in camera space 
    vec3 dir = vec3( tan(fov * 3.14159 / 180.0) * (pixel - vec2(resolution.xy / 2.0)), resolution.x); // pixel direction in camera space 
    dir = camToScene(dir, camDir, camUp);
    return rayMarch(camPos, normalize(dir));
}

vec3 camPos(in float time) {
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    float angle = (time + 0.) * 0.05 + mouse.x * 10.;
    float radius = 3.;
    float height = 0.7;
    return vec3(radius*sin(angle), height, -radius*cos(angle));
}

vec3 calcNormal(in vec3 pos) {
    vec3 n = vec3(0.0);
    for (int i = 0; i<4; i++) {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e* sceneSDF(pos+0.0005*e).x;
    }
    return normalize(n);    
}

float calcAO( in vec3 pos, in vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.02 * float(i);
        float d = sceneSDF( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 1.*occ, 0.0, 1.0 );
}

float calcSoftShadow( in vec3 origin, in vec3 dir, in float tmin, in float tmax )
{
    float res = 1.0;
    float t = tmin;
    for( int i=0; i<32; i++ )
    {
        float h = sceneSDF( origin + dir*t ).x;
        float s = clamp(32.0*h/t,0.0,1.0);
        res = min( res, s );
        t += clamp( h, 0.01, 100.9 );
        if( res<0.001 || t>tmax ) break;
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

const Material MAT_BG           = Material(vec3(0.65,0.95,0.90), 0.0, 0.0, 1.0);
const Material MAT_FELT         = Material(vec3(0.70,0.50,0.30), 1.0, 0.0, 1.0);
const Material MAT_FELT_LIGHT   = Material(vec3(0.95,0.80,0.60), 1.0, 0.05, 1.0);
const Material MAT_FELT_DARK    = Material(vec3(0.55,0.35,0.20), 1.0, 0.1, 1.);
const Material MAT_FLOOR_DARK   = Material(vec3(0.55,0.75,0.65), 0.0, 0.0, 1.0);
const Material MAT_FLOOR_BRIGHT = Material(vec3(0.60,0.80,0.70), 0.0, 0.0, 1.0);
const Material MAT_EYES         = Material(vec3(0.10,0.10,0.10), 0.5, 1.0, 8.);
const Material MAT_NOSE         = Material(vec3(0.55,0.35,0.20), 1.0, 0.4, 4.0);

Material getMaterial(in vec3 pos) {
    if(pos.y < 0.545) {
        if (int(floor(pos.x) + floor(pos.z)) % 2 == 0 ) 
            return MAT_FLOOR_DARK;
        else return MAT_FLOOR_BRIGHT;
    }
    vec3 symPos = sceneSymmetries(pos);
    
    Material mat = MAT_FELT;
    float eyes = smoothstep(0.001, 0.0025, sdfEyes(symPos));
    mat = lerp(MAT_EYES, mat, eyes);
    
    float snout = smoothstep(-.01, 0.01, sdfSnout(symPos));
    mat = lerp(MAT_FELT_LIGHT, mat, snout);
        
    float fulcrum = smoothstep(0.005, 0.01, max(sdfFulcrum(symPos), sdfSnout(symPos)));
    mat = lerp(MAT_FELT_DARK, mat, fulcrum);
   
    float nose = smoothstep(0.002, 0.003, sdfNose(symPos));
    mat = lerp(MAT_NOSE, mat, nose);
    
    float insideEar = 1. - smoothstep(.005, 0.025, sdfInsideEar(symPos));
    insideEar *= smoothstep(.002, 0.015, sdfHead(symPos));
    mat = lerp(MAT_FELT_LIGHT, mat, 1.-insideEar);
    
    float paw = smoothstep(.001, 0.005, sdfPaw(symPos));
    mat = lerp(MAT_FELT_LIGHT, mat, paw);
    
    float pawPrint = smoothstep(.001, 0.008, sdfPawPrint(symPos));
    mat = lerp(MAT_FELT_DARK, mat, pawPrint);
    return mat;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 camPos = camPos(time);
    vec3 camDir = vec3(0,.85,0) - camPos;
    vec3 camUp = vec3(0,1,0);
    float fov = 30.0;

    // background
    Material material = MAT_BG;

    
    // ray march scene
    vec4 rayMarch = rayMarch(gl_FragCoord.xy, camPos, camDir, camUp, fov);
    
    vec3 col = material.diffuse;
    if(rayMarch.x > 0.0) {
        float zDepth = rayMarch.x;
        float depthMask = pow(max(0.0, zDepth-5.0)*0.005,0.4);
        depthMask = clamp(1.0-depthMask, 0., 1.);
        vec3 normal = calcNormal(rayMarch.yzw);
        float ao = calcAO(rayMarch.yzw, normal);
        
        //vec3 mat = rayMarch.z > .01 ? vec3(.7,.5,.3) : vec3(0.5+0.01*float((int(floor(rayMarch.y) + floor(rayMarch.w)) % 2) == 0));
        material = getMaterial(rayMarch.yzw);
        vec3 mat = material.diffuse;
        
        // ambiant
        vec3 ambient = vec3(0.50,0.50,1.00);
        col = ambient * .5 * mat;
        
        //  directional light
        vec3 directionalLight = normalize(vec3(1.,-2.,2.));
        float directionalDiffuse = clamp(dot(-directionalLight,normal), 0., 1.);
        float directionalShadow = calcSoftShadow(rayMarch.yzw, -1.*directionalLight, 0.0001, 3.5);
        col += mat * 1.0 * directionalDiffuse * directionalShadow; 
        
        // add Fresnel sheen to Teddy
        if(rayMarch.z > .01) {
            float sheen = 0.2 - .2 * clamp(dot(normal, normalize(camPos-rayMarch.yzw)), 0., 1.);
            col += sheen * material.sheen;
            col = clamp(col, 0., 1.);
        }
        
        // Phong specular
        float spec = dot(reflect(-directionalLight,normal), normalize(rayMarch.yzw - camPos));
        col = lerp(col, vec3(1.) * pow(clamp(spec,0.,1.), material.specE), material.specular);
        
        // AO
        col = lerp(col*col*ao, col, pow(ao, 1.));
        
        // atmospheric fog
        col = lerp(MAT_BG.diffuse, col, depthMask);
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
