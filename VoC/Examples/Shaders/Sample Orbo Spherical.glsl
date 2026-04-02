#version 420

// original https://www.shadertoy.com/view/3ttGRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define VIEW_DIST 70.0
//change VIEW_DIST for farther or shorter render distance

struct Object
{
     float dist;
    float difVal;
    float specVal;
    float specKs;
    float normEps; //artifacting was occuring for some objects when this value was too high
                   //thus, you can specify a value for each object.
    vec3 color;
    vec3 normal;
};

struct MarchRes
{
     float totalDist;
    vec3 curRay;
    Object obj;
};
    
struct Light
{
    float intensity;
    vec3 color;
    vec3 pos;  
};

//iq
float sdSphere(vec3 pos, float rad)
{
     return length(pos) - rad;
}

//iq
float sdPlaneInf(vec3 pos, float y)
{
     return pos.y - y;   
}

//iq
float sdPlane( vec3 p, vec4 n )
{
      return dot(p,n.xyz) + n.w;
}

//iq
float sdVerticalCapsule( vec3 p, float h, float r )
{
      p.y -= clamp( p.y, 0.0, h );
      return length( p ) - r;
}

//iq
float sdRoundBox( vec3 p, vec3 b, float r )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

//iq
float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

//slightly modified, but IQ
vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayDir,   // camera to point vector
               in vec3  sunDir )  // sun light direction
{
    float fogAmount = 1.0 - exp( -distance*(distance*(0.001 / pow(clamp(VIEW_DIST / 70.0, 0.0, 1.0), 2.0))) );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( vec3(0.5,0.6,0.7), // bluish
                           vec3(0.5,0.6,0.7), // yellowish
                           pow(sunAmount,8.0) );
    return mix( rgb, fogColor, fogAmount );
}

//https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
    
Object map(vec3 pos)
{
    Object o;
    o.difVal = 1.0;
    o.dist = 1000.0;
    o.normEps = 0.00001;
    o.color = vec3(0);
    
    float yOff = 0.05*sin(5.0*time);
    vec3 offset = vec3(0, yOff, 0);
    
    //ground
    vec3 boardPos = pos;
    boardPos.z = mod(boardPos.z, 10.0);
    boardPos.x = mod(boardPos.x, 12.0);
    float dBoard = sdRoundBox(boardPos - vec3(0,-3,0), vec3(12, 0.5, 10.0), 0.1);
    if(dBoard < o.dist)
    {
        o.dist = dBoard;
        o.difVal = 0.9;
        
        //checker board
        vec3 col;
        float modi = 2.0*(round(step(sin(pos.z*1.*PI), 0.0)) - 0.5);
        float goldMod = step(-2.0, pos.x) * step(pos.x, 2.0);
        
        col = vec3(1.0*(1.0-goldMod)) + vec3(0.0,0.4,0.6)*goldMod;
        col *= (round(step((modi)*sin(pos.x*1.0*PI), 0.0)));
        
        o.color = col;
        o.specVal = 200.0;
        o.specKs = 0.5;
    }
    
    //tree 
    vec3 treePos = pos;
    vec2 id = floor(vec2(treePos.x/3.5, treePos.z/5.5));
    treePos.x = abs(treePos.x);
    treePos.z = mod(treePos.z, 5.5);
    treePos.x = mod(treePos.x, 7.0);
    treePos -= vec3(5.5, -4.5, 2.5);
    
    float h = sin(id.x) * 337.0 * sin(id.y) * 43.3;
    h = -1.0 + mod(h, 3.0);
    float timeMod = 0.5 + mod(id.x*123.0 / id.y*1234.0, 1.0);
    h *= sin(time*1.0 + 43.445*id.y + 122.89*id.x);
    treePos.y -= h;
    
    float treeBound = sdVerticalCapsule(treePos, 5.0, 0.75);
    
    if(treeBound < o.dist)
    {
        
        float dTree = sdVerticalCapsule(treePos, 5.0, 0.5);
        dTree = smin(dBoard, dTree, 0.3);
        if(dTree < o.dist)
        {
            o.dist = dTree;   
            o.difVal = 0.9;
            float modi = 2.0*(round(step(sin(pos.z*PI), 0.0)) - 0.5);
            float yStep = smoothstep(0.0, 0.3, treePos.y);

            vec3 colTrunk = vec3(0.4, 0.3, 0) + vec3(sin(10.0*floor(10.0*treePos.y)))*0.05;
            vec3 col = mix(vec3(1)*(round(step((modi)*sin(pos.x*1.0*PI), 0.0))),colTrunk, yStep);

            o.color = col;
            o.specVal = 200.0;
            o.specKs = 0.0;
        }
        //tree leaves
        vec3 leafPos = pos;
        leafPos.x = abs(leafPos.x);
        leafPos.z = mod(leafPos.z, 5.5);
        leafPos.x = mod(leafPos.x, 7.0);
        leafPos -= vec3(5.5, 1.5, 2.5);
        leafPos.y -= h;

        float dLeaf = sdEllipsoid(leafPos, vec3(1.5, 1.0, 1.5));
        dTree = smin(dTree, dLeaf, 0.5);
        if(dLeaf < o.dist)
        {
            o.dist = dTree;   
            o.difVal = 0.9;

            float modi = 2.0*(round(step(sin(pos.z*1.*PI), 0.0)) - 0.5);

            float yStep = smoothstep(-1.0, -0.8, leafPos.y);
            vec3 col = mix(vec3(0.4, 0.3, 0) ,vec3(0, 0.3, 0), yStep);

            o.color = col;
            o.specVal = 200.0;
            o.specKs = 0.0;
        }
    }
    
    //character bounding box
    float dBBChar = sdSphere(pos - vec3(0,-0.9,0), 1.7);     
    if(dBBChar < o.dist)
    {
        //body
        float dSphere = sdSphere(pos - vec3(0,-0.9,0) + offset, 1.0);
        
        //brows
        float ang = 0.0;
        vec3 browPos = pos;
        browPos.x = abs(browPos.x);
        browPos = browPos - vec3(0.35,-0.5,0.85) + offset;  
        browPos.y -= -2.0*browPos.x *(2.0*browPos.x/2.0);
        mat2 browRot = mat2( vec2(cos(ang), -sin(ang)), vec2(sin(ang), cos(ang)) );
        browPos = vec3(browRot * browPos.xy, browPos.z);
        float dBrow = sdEllipsoid(browPos, vec3(0.24, 0.1, 0.16));
        dSphere = smin(dBrow, dSphere, 0.07);
        
        if(dSphere < o.dist)
        {
            o.dist = dSphere;
            float z = pos.y + 1.0;
            vec3 col = vec3(235.0/255.0, 182.0/255.0, 255.0/255.0);
            col = mix(col,vec3(0.2, 0, .3), (z/2.0));
            o.color = col;
            o.specVal = 55.0;
            o.specKs = 0.04;
        }

        //mouth
        vec3 mouthPos = pos - vec3(0, -1.2, 0.9) + offset;
        mouthPos.y -=  2.0*mouthPos.x * (mouthPos.x/2.0);
        float mouthHeight = 0.02 + 0.1*clamp(sin(time/2.0), 0.0, 1.0);
        float dMouth = sdEllipsoid(mouthPos, vec3(0.34, mouthHeight, 0.8));
        if(-dMouth > o.dist)
            o.color = vec3(255.0/255.0, 182.0/255.0, 215.0/255.0) * 0.6;
        o.dist = max(o.dist, -dMouth);
        

        //hair sdRoundBox( vec3 p, vec3 b, float r )
        vec3 hairPos = pos - vec3(0, 0.1, 0);
        hairPos.y -= -hairPos.z * (hairPos.z/2.0);
        hairPos.y -= 0.05*sin(hairPos.z*25.0);
        hairPos += offset;
        float dHair = sdRoundBox(hairPos, vec3(0.1, 0.2, 0.7), 0.05);
        if(dHair < o.dist)
        {
            o.dist = dHair;
            //o.color = vec3(0.5, 1.0, 0.5);
            o.color = vec3(1, 0.5, 0.5) + vec3(0, hairPos.y*1.53, 0);
            o.specVal = 2.0;
            o.specKs = 0.0;
        }

        //add bobbing and swinging animation
        //

        //feet
        ang = -PI/4.0;
        vec3 footPos = pos; 
        footPos.x = abs(footPos.x);
        mat2 footRot = mat2( vec2(cos(ang), -sin(ang)), vec2(sin(ang), cos(ang)) );
        vec2 footXZ = footRot * footPos.xz;
        footPos = vec3(footXZ.x, pos.y, footXZ.y);
        float dFoot = sdEllipsoid(footPos - vec3(0.3,-2.3,0.6), vec3(0.3, 0.3, 0.4));
        if(dFoot < o.dist)
        {
            o.dist = dFoot;
            o.color = vec3(0.5, 0., 0.);
            o.specVal = 2.0;
            o.specKs = 0.4;
        }

        //hands
        float hAng = PI/2.0;
        vec3 handPos = pos;
        float modi = handPos.x / abs(handPos.x);
        handPos.x = abs(handPos.x);
        
        handPos = handPos - vec3(1.35+offset.y,-1.5,0.0);
        //handPos += offset;
        //handPos = opCheapBend(handPos);
        mat2 handRot = mat2( vec2(cos(hAng), sin(hAng)), vec2(-sin(hAng), cos(hAng)) );
        vec2 handXZ = handRot * handPos.xz;
        handPos = vec3(handXZ.x, handPos.y, handXZ.y);
        //handRot = mat2( vec2(cos(hAng), -sin(hAng)), vec2(sin(hAng), cos(hAng)) );
        //handPos = vec3(handPos.x, handRot * handPos.yz);
        float dHand = sdEllipsoid(handPos, vec3(0.3, 0.35, 0.23));
        if(dHand < o.dist)
        {
            o.dist = dHand;
            o.color = vec3(1);
            o.specVal = 50.0;
            o.specKs = 0.4;
        }

        //eyes
        vec3 eyePos = pos;
        eyePos.x = abs(eyePos.x);
        eyePos += offset;
        float dEye = sdSphere(eyePos - vec3(0.34,-0.7,0.8), 0.2);
        if(dEye < o.dist)
        {
            o.dist = dEye;
            o.color = vec3(1);
            o.specVal = 100.0;
            o.specKs = 2.0;
        }

        //pupils
        vec3 pupPos = pos;
        pupPos.x = abs(pupPos.x);
        pupPos += offset;
        float dEyePup = sdSphere(pupPos - vec3(0.32,-0.7,0.94), 0.08);
        if(dEyePup < o.dist)
        {
            o.dist = dEyePup;
            o.color = vec3(0);
            o.specVal = 100.0;
            o.specKs = 2.0;
        }
        
        //eye lid
        vec3 lidPos = pos;
        //lidPos.y = clamp(lidPos.y, -0.8,-0.5);
        lidPos.x = abs(lidPos.x);
        lidPos += offset;
        float dLid = sdSphere(lidPos - vec3(0.34,-0.7,0.8), 0.225);
        
        //consulted IQ's happy jumping for a similar blink rate function
        if(dLid < o.dist && lidPos.y > 1.0 - 2.0*pow(sin(time),40.0))
        {
            o.dist = dLid;
            o.color = vec3(235.0/255.0, 182.0/255.0, 255.0/255.0);
            o.specVal = 55.0;
            o.specKs = 0.04;
        }
    
    }
    
    
    return o;
}

vec3 calcNormal(vec3 pos, float ep)
{
    return normalize(vec3(map(pos + vec3(ep, 0, 0)).dist - map(pos - vec3(ep, 0, 0)).dist,
                        map(pos + vec3(0, ep, 0)).dist - map(pos - vec3(0, ep, 0)).dist,
                        map(pos + vec3(0, 0, ep)).dist - map(pos - vec3(0, 0, ep)).dist));                                
}
    
MarchRes marchRay(vec3 pos, vec3 dir, float speed)
{
     MarchRes res;
    Object o;
    
    res.totalDist = 0.001;

    for(int x=0; x<200; x++)
    {
         res.curRay = pos + (dir*res.totalDist);
        
        o = map(res.curRay);
        if(abs(o.dist) < 0.00001)
        {
            res.obj = o;
            break;
        }
        else if(res.totalDist >= VIEW_DIST) break;
            
        res.totalDist += o.dist*speed; // repalce 0.8 w/ this for trippy mode ;p => (0.3+0.2*(sin(time))); //couldn't handle the hair :' (
    }
    
    if(res.totalDist < VIEW_DIST)
    {
        o.normal = calcNormal(res.curRay, o.normEps);
        res.obj = o;
    }
        
    
    return res;
}

float calcShadow(vec3 pos, Light l)
{
    MarchRes res;
    if(VIEW_DIST > 20.0)
         res = marchRay(pos, normalize(l.pos - pos), 0.3); //march slower to prevent shadow artifacts
    else
        res = marchRay(pos, normalize(l.pos - pos), 1.0);
        
    if(res.totalDist < VIEW_DIST)
        return 0.0;
    return 1.0;
}

vec3 calcDiffuseLight(Object o, Light l, vec3 pos)
{
    vec3 dir = normalize(l.pos - pos);
    return (o.color) * l.intensity * l.color * clamp(dot(o.normal, dir), 0.0, 1.0) * o.difVal;   
}

vec3 calcSpecLight(Object o, Light l, vec3 pos, vec3 camPos)
{
     vec3 dir = normalize(l.pos - pos);  
    vec3 viewDir = normalize(camPos - pos);
    vec3 specR = 2.0*clamp( dot(o.normal, dir), 0.0, 1.0) * o.normal - dir;
    float spec = clamp( dot(viewDir, specR), 0.0, 1.0);
    //lightInt*(lightCol*pow(lightSpec, res.obj.specVal))*res.obj.specKs * lightShadow;
      
    return o.specKs*l.intensity*(l.color*pow(spec, o.specVal));
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    vec3 camEye = vec3(0,-0.5,3.5);
    vec3 dir = normalize(vec3(uv, -1));
    

    float camAng = 0.5;//PI/15.0 + mouse.x*resolution.xy.x/200.0;
    float camAngX = 0.0;//mouse.y*resolution.xy.y/200.0;
    
    mat2 rotCam = mat2( vec2(cos(camAng), -sin(camAng)), vec2(sin(camAng), cos(camAng)) );
    mat2 rotCamX = mat2( vec2(cos(camAng), sin(camAng)), vec2(-sin(camAng), cos(camAng)) );

    vec2 camXZ = rotCam * camEye.xz;
    camEye = vec3(camXZ.x, camEye.y, camXZ.y);
    vec2 dirXZ = rotCam * dir.xz;
    dir = vec3(dirXZ.x, dir.y, dirXZ.y);
    
    Light light;
    light.intensity = 1.00;
    light.pos = vec3(0, 4, 10);
    light.color = vec3(1);
    
    Light lightSky;
    lightSky.intensity = 3.1;
    lightSky.pos = vec3(0, 3, 0);
    lightSky.color = vec3(0.1, 0.1, 0.1);
    
    //add bounce light
    
    MarchRes res = marchRay(camEye, dir, 1.0);
    vec3 pos = res.curRay;  
    
    float y = uv.y + 1.0;
    y = y / 1.62;
    y = clamp(y, 0.7, 1.0);
    vec3 col = (vec3(0.3, 0.6, 0.85)*(y) + vec3(1)*(1.0 - y));
    col += step(pow(dir.x*10.0, 2.0) + pow(dir.z*50.0+50.0, 2.0), 1.0) * vec3(1,0,0) * vec3(sin(dir.x*10.0)*sin(dir.z*50.0));
    //col += vec3(1) * mod(dir*50.0, 2.0) * step(50.0, pos.y);
    
    if(res.totalDist < VIEW_DIST)
    {
        col = calcDiffuseLight(res.obj, light, pos) * calcShadow(pos, light) + calcDiffuseLight(res.obj, lightSky, vec3(0,0,0));
        col += calcSpecLight(res.obj, light,pos, camEye) * calcShadow(pos, light);
        col = applyFog(col, sqrt(pow(pos.x,2.0) + pow(pos.y,2.0) + pow(pos.z,2.0)), normalize(pos), normalize(light.pos - pos));
    }
    
    glFragColor = vec4(col,1.0);
}
