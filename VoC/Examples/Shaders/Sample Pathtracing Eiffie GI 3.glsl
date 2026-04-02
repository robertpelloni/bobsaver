#version 420
/*this code from eiffie is an example of simple global illumination
includes ideas from Inigo Quilez, Syntopia, rrrola and others
but don't blame them for this questionable code - it came mainly out of my head
the idea is to bounce rays according to the material specification
the materials have 2 components that define the probability a ray bounces a particular way
m.refrRefl = the refraction(-) and reflection(+) probabilty: 0.9 means reflect the ray 90% of the time
    -0.9 means refract for transparency. This has a built in 25% chance of then reflecting (seems about right)
m.gloss = probability of scattering. This gathers indirect light from any direction.
If the ray hasn't reflected or scattered and it has a good probability of being
directly lit it becomes a shadow test ray. This shadow ray acts differently. It "dies" if it hits
non-refracting/reflecting objects to create a shadow while allowing some caustics.
Any ray that happens to hit a light will light the pixel. Running
masks are kept for the color, spec and overall amount of light collected.
The material also has specular components:
m.spec = specularity and m.specExp = specular exponent
These should work about as you expect but the specular
exponent also controls how clear a glass or mirror surface will be.
It seems like you can get a lot of different materials with these simple controls.
There is also an emissive material that will let you create complex lighting.
That's a lot for such a small script!*/

uniform float time;
uniform float timems;
uniform float random1,random2;
uniform vec2 resolution;
uniform vec2 mouse;
uniform int frames;

out vec4 glFragColor;
// environment settings
uniform vec3 sunColor=vec3(1.0,1.0,0.5);
uniform vec3 sunDirection=vec3(0.5,1.0,-1.1);
uniform vec3 skyColor=vec3(0.3,0.6,1.0);
//uniform vec3 skyColor=vec3(0.0,0.0,0.0);
uniform float fog=1.0;
uniform float ambience=0.2;
uniform vec3 floorColor=vec3(0.45,0.64,0.53);
uniform float floorReflection=0.0;
uniform float floorGloss=0.1;
uniform float floorSpec=0.1;
uniform float floorSpecExp=4.0;
// Menger
uniform vec3 mengerColor=vec3(0.85,0.9,0.95);
uniform float mengerRefrRefl=-1.0;
uniform float mengerGloss=0.0;
uniform float mengerSpec=1.5;
uniform float mengerSpecExp=14.0;
// Bulb
uniform vec3 bulbColor=vec3(0.75,0.6,0.5);
//uniform vec3 bulbPosition=vec3(-1.0,0.0,1.6);
uniform vec3 bulbPosition=vec3(0.0,0.0,0.0);
uniform float bulbRefrRefl=0.2;
uniform float bulbGloss=0.15;
uniform float bulbSpec=1.5;
uniform float bulbSpecExp=7.0;
// Emissive
uniform bool UseEmissive=false;
uniform vec3 lightPosition=vec3(-1.3,0.9,0.0);
uniform vec3 lightColor=vec3(1.0,0.8,0.75);
uniform float lightStrength=10.0;
uniform float lightBloom=10.0;
// Raytracer
uniform int RayBounces=6;
uniform int RaySteps=256;
uniform float FudgeFactor=0.9;
uniform float SoftShadows=5.0;
uniform float HitDistance=0.00009;
// Glass
uniform vec3 glassColor = vec3(0.85,0.9,0.95);
uniform float glassRefrRefl = -1;
uniform float glassGloss = 0;
uniform float glassSpec = 2;
uniform float glassSpecExp = 30;
uniform vec3 glassPosition = vec3(-0.05128,0.64104,-1.17948);
uniform vec3 glassDirection = vec3(0.21509,0.04302,-0.1);
uniform float glassRefrIndex = 1.33428;

vec2 rand2()
{
    return vec2(random1,random2);
}

/*
FOV = 0.813
Eye = -0.457,0.408,-2.008
Target = 0.154,0.098,0
Up = 0,1,0
EquiRectangular = false
FocalPlane = 1
Aperture = 0
Gamma = 1
ToneMapping = 1
Exposure = 1
Brightness = 1
Contrast = 1
Saturation = 1
GaussianWeight = 1
AntiAliasScale = 2
sunColor = 1,1,0.5
sunDirection = -1,1,-0.475
skyColor = 0.3,0.6,1
fog = 5
ambience = 4.4898
floorColor = 0.45,0.64,0.53
floorReflection = 0.32877
floorGloss = 0.1
floorSpec = 0.9796
floorSpecExp = 4.0405
bulbColor = 0.75,0.6,0.5
bulbPosition = -1,0,1.7
bulbRefrRefl = 0.6
bulbGloss = 0.25
bulbSpec = 1.5
bulbSpecExp = 7
UseEmissive = true
lightPosition = 2,1.5366,-1.5122
lightColor = 1,0.8,0.75
lightStrength = 16
lightBloom = 10
RayBounces = 6
RaySteps = 128
FudgeFactor = 0.9
HitDistance = 0.0001
SoftShadows = 8
glassColor = 0.85,0.9,0.95
glassRefrRefl = -1
glassGloss = 0
glassSpec = 2
glassSpecExp = 30
glassPosition = -0.05128,0.64104,-1.17948
glassDirection = 0.21509,0.04302,-0.1
glassRefrIndex = 1.33428
*/

const float maxDepth=25.0, OOMD=1.0/maxDepth;
//int iRay=backbufferCounter;//taking the user input and making it ready to use
vec3 sunDir=normalize(sunDirection);
float lBloom=pow(2.,17.-lightBloom)-1.999,lStrength=pow(1.05,17.-lightStrength)-1.04999;
float ShadowExp=pow(2.,17.0-SoftShadows);
float minLiteDist,side=1.0; //1.0=outside, -1.0=inside of object

struct material {vec3 color;float refrRefl,gloss,spec,specExp;};
material Mater0=material(bulbColor,bulbRefrRefl,bulbGloss,bulbSpec,pow(2.,bulbSpecExp));
material Mater1=material(floorColor,floorReflection,floorGloss,floorSpec,pow(2.,floorSpecExp));
material Mater2=material(glassColor,glassRefrRefl,glassGloss,glassSpec,pow(2.,glassSpecExp));
material Mater3=material(vec3(0.2,0.2,0.2),0.4,0.1,1.5,pow(2.,5.));
material Mater4=material(vec3(0.95,0.94,0.93),0.9,0.0,1.5,pow(2.,13.));

vec3 PYR(in vec3 z, in vec3 rot){//vec3(pitch,yaw,roll)
    vec3 c=cos(rot),s=sin(rot);
    return z*mat3(c.z*c.y+s.z*s.x*s.y,s.z*c.x,-c.z*s.y+s.z*s.x*c.y,
    -s.z*c.y+c.z*s.x*s.y,c.z*c.x,
    s.z*s.y+c.z*s.x*c.y,c.x*s.y,-s.x,c.x*c.y);
}

//some simple distance estimate functions
float DESphere(in vec3 z, float radius){return length(z)-radius;}
float DEBox(in vec3 z, float hlen){return max(abs(z.x),max(abs(z.y),abs(z.z)))-hlen;}
float DECylinder(in vec3 z, float hlen, float radius){return max(length(z.zy)-radius,abs(z.x)-hlen);}
float DERRect(in vec3 z, vec4 radii){return length(max(abs(z)-radii.xyz,0.0))-radii.w;}
float DEOcto(in vec3 z, float hlen){return max(abs(z.x+z.y+z.z),max(abs(-z.x-z.y+z.z),max(abs(-z.x+z.y-z.z),abs(z.x-z.y-z.z))))-hlen;}
float Difference(float d1, float d2){return max(d1,-d2);}

//DEBulb(z,8.0,1.0,5);
float DEBulb(vec3 z0, float p, float scale, int iters)
{
    vec3 c = z0*scale,z = c;
    float dr = scale,r = length(z),zr,zo,zi;
    for (int n = 0; n < iters && r<2.0; n++) {
        zo = asin(z.z / r) * p;//+time;
        zi = atan(z.y, z.x) * p;
        zr = pow(r, p-1.0);
        dr = dr * zr * p + 1.0;
        z=(r*zr)*vec3(cos(zo)*cos(zi),cos(zo)*sin(zi),sin(zo))+c;
        r = length(z);
    }
    return 0.5 * log(r) * r / dr;
}

float DEL(in vec3 z){//this is the DE for emissive light (use folding etc. to create multiple lights)
    z-=lightPosition;
    return (length(z)-0.2);
    //return DERRect(z,vec4(vec3(0.2),0.05));
    //return DEBulb(z,3.0,5.0,1);//a larger scale "5" makes it 1/5 scale
}

vec2 min2(vec2 d1, vec2 d2){return (d1.x<d2.x)?d1:d2;}//sorts vectors based on .x

vec2 mapMagGlass(in vec3 z){
    vec2 glass=vec2(max(DESphere(z-vec3(0.0,0.0,1.0),1.1),DESphere(z-vec3(0.0,0.0,-1.0),1.1)),2.0);
    vec2 handle=vec2(DECylinder(z-vec3(0.8,0.0,0.0),0.345,0.075),3.0);
    vec2 rim=vec2(Difference(DECylinder(z.zyx,0.05,0.46),DECylinder(z.zyx,0.1,0.44)),4.0);
    return min2(glass,min2(handle,rim));
}

vec2 map(in vec3 z)
{//return distance estimate and object id 
    vec2 bulb=vec2(DEBulb(z,5.0,1.0,7),0.0);
    vec2 flr=vec2(max(length(z.xz)-2.5,z.y+1.0),1.0);
    vec2 glass=mapMagGlass(PYR(z-glassPosition,glassDirection));
    vec2 lit=vec2((UseEmissive)?DEL(z):1000.0,-2.0);//the id -2 is for emissive light
    minLiteDist=min(minLiteDist,lit.x);//save the closest distance to the light for bloom
    return min2(min2(min2(bulb,glass),lit),flr);//add as many objects as you like this way
}

material getMaterial( in vec3 z0, in vec3 nor, in float item )
{//get material properties (color,refr/refl,gloss,spec,specExp)
    if(item==0.0)return Mater0;
    if(item==1.0)return Mater1;
    if(item==2.0)return Mater2;
    if(item==3.0)return Mater3;
    return Mater4; //you can extend this with a texture lookup etc.
}

vec3 getBackground( in vec3 rd ){
    return skyColor+sunColor*(max(0.0,dot(rd,sunDir))*0.2+pow(max(0.0,dot(rd,sunDir)),256.0)*2.0);
}

//the code below can be left as is so if you don't understand it that makes two of us :)

vec2 intersect(in vec3 ro, in vec3 rd )
{//march the ray until you hit something or go out of bounds
    float t=HitDistance*10.0,d=1000.0;
    side=sign(map(ro+t*rd).x);//keep track of which side you are on
    float mult=side*FudgeFactor;
    for(int i=0;i<RaySteps && abs(d)>HitDistance;i++){
        t+=d=map(ro+t*rd).x*mult;
        if(t>=maxDepth)return vec2(t,-1.0);//-1.0 is id for "hit nothing"
    }
    vec2 h=map(ro+t*rd);//move close to the hit point without fudging
    h.x=t+h.x*side;
    return h;//returns distance, object id
}

vec3 ve=vec3(HitDistance,0.0,0.0);
vec3 getNormal( in vec3 pos, in float item )
{// get the normal to the surface at the hit point
    return side*normalize(vec3(-map(pos-ve.xyy).x+map(pos+ve.xyy).x,
        -map(pos-ve.yxy).x+map(pos+ve.yxy).x,-map(pos-ve.yyx).x+map(pos+ve.yyx).x));
}

vec4 getEmissiveDir( in vec3 pos)
{//get the direction and distance to a DE based light
    vec2 vt=vec2(DEL(pos),0.0);//find emissive light dir by triangulating its nearest point
    return vec4(-normalize(vec3(-DEL(pos-vt.xyy)+DEL(pos+vt.xyy),
            -DEL(pos-vt.yxy)+DEL(pos+vt.yxy),-DEL(pos-vt.yyx)+DEL(pos+vt.yyx))),vt.x);
}
 
vec3 cosPowDir(vec3  dir, float power) 
{//creates a nice biased sampling which I abuse in this code    
    vec2 r=rand2()*vec2(6.2831853,1.0);
    vec3 sdir=cross(dir,((abs(dir.x)<0.5)?vec3(1.0,0.0,0.0):vec3(0.0,1.0,0.0)));
    vec3 tdir=cross(dir,sdir);
    r.y=pow(r.y,1.0/power);
    float oneminus = sqrt(1.0-r.y*r.y);
    return cos(r.x)*oneminus*sdir + sin(r.x)*oneminus*tdir + r.y*dir;
}

vec4 scene(vec3 ro, vec3 rd) 
{// find color and depth of scene
    vec3 tcol = vec3(0.0),acol=vec3(0.0),fcol = vec3(1.0),bcol=vec3(0.),fbcol=vec3(0.);//total color, ambient, mask, background, first bg
    float drl=1.0,spec=1.0,frl=0.0,erl=0.0,smld=0.0;//direct and specular components, fisrt ray length
    minLiteDist=1000.0;//for bloom (sketchy)
    bool bHitLight=false,bLightRay=false; //is this ray used as a shadow check
    for(int  i=0; i <RayBounces && dot(fcol,fcol)>0.001 && drl>0.001; i++ )
    {// create light paths iteratively
        bcol=getBackground(rd);
        vec2 hit = intersect( ro, rd ); //find the first object along the ray march
        acol+=bcol*pow(hit.x,0.1)*OOMD*ambience; //calc some ambient lighting???
        if(i==0){frl=hit.x;fbcol=bcol;}//save the very first length and backcolor for fog cheat
        else erl+=hit.x;//since the emissive light decays keep track of the distance
            if( hit.y >= 0.0 ){//hit something
                ro+= rd * hit.x;// advance ray position
                vec3 nor = getNormal( ro, hit.y );// get the surface normal
            material m=getMaterial( ro, nor, hit.y );//and material
            fcol*=m.color;// modulate the frequency mask
            if(bLightRay)drl*=abs(m.refrRefl);//if we are checking for shadows then decrease the light unless refl/refr
            //this complicated section is just choosing an appropriate but "random" ray direction based on probabilities
            vec3 refl=reflect(rd,nor),newRay=refl;//setting up for a new ray direction and defaulting to a reflection
            float se=m.specExp;//also defaulting to the sample bias for specular light
            vec2 rnd=rand2();//get 2 random numbers
            if(abs(m.refrRefl)>rnd.x){//do we reflect and/or refract
                if(m.refrRefl<0.0){//if the material refracts
                    if(rnd.y<0.85){//only refract most of the time else reflect about 25%
                        rd=(side>=0.0)?refract(rd,nor,1.0/glassRefrIndex):refract(rd,nor,glassRefrIndex);//refract depends on in/out or out/in (bogus indices)
                        if(dot(rd,nor)<-0.05)newRay=rd;//if the ray is incident to surface just reflect
                    }
                }
            }else {//if we didn't reflect/refract then use gloss & light direction to determine how we bounce
                if(UseEmissive){//determine the best light to sample
                    vec4 emld=getEmissiveDir(ro);//get direction and distance to emissive light
                    float pe=max(dot(emld.xyz,nor),0.0)/max(lStrength*emld.w*emld.w,1.0),ps=max(dot(sunDir,nor),0.0);
                    newRay=(pe/(pe+ps)>fract((rnd.x+rnd.y)*213.79))?emld.xyz:sunDir;//probably the best choice
                }else newRay=sunDir;
                if(dot(newRay,nor)*(1.0-m.gloss)>rnd.y){bLightRay=true;se=ShadowExp;smld=minLiteDist;}//switch to a shadow check
                else {se=1.5;newRay=nor;}//checking for ambient light in any direction since direct lighting was improbable
            }
            rd = cosPowDir(newRay,se);//finally redirect the ray
            spec*=pow(max(0.0,dot(rd,refl)),m.specExp)*m.spec;//how much does this new direction contribute to specular lighting?
        }else{//hit a light so light up the pixel and bail out
            if(i==0)spec=0.0;//lights themselves don't have specularity
            if(hit.y==-1.0)tcol=fcol*bcol;//-1 = background lighting
            else tcol=lightColor/max(lStrength*erl*erl,1.0);//we hit a DE light so make it bright!
            tcol*=(fcol+spec)*drl;//this adds the light info we gathered (seems suspicious;)
            bHitLight=true;break;
        }
    }//add an ambient light and fog (cheat! should be added every hit)
    if(!bHitLight)tcol+=acol*fcol;
    tcol=mix(tcol,fbcol,clamp(log(frl*OOMD*fog),0.0,1.0));//fog & ambience
    minLiteDist=max(minLiteDist,smld);//light bloom is OR'd in (could be done in post processing)
    return vec4(clamp(max(tcol,lightColor/max(lBloom*minLiteDist*minLiteDist,0.5)),0.0,1.0),frl/maxDepth);
}        

vec3 color(vec3 ro, vec3 rd){return scene(ro,rd).rgb;}

//for completeness here is an example stand alone main function
void main() {//for slow accumulation (needs texture same size)
    
    
    float fov=35.0;
    vec3 eye = vec3(10.0,2.0,-20);
    vec3 target = vec3(0.0,0.0,0.0);
    vec3 up = vec3(-1.0,0.0,0.0);
    float blurAmount = 0.0;
    float focusDistance=8.0;
    
    vec3 uu=up;
    vec3 ww=normalize(target-eye);
    vec3 vv=cross(uu,ww);
    
    vec3 gammaCorrection=vec3(1.0,1.0,1.0);
    
    
    vec4 clr=vec4(0.0);
    vec2 pxl=(-resolution+2.0*(gl_FragCoord.xy+rand2()))/resolution.y;//size is image resolution
    vec3 ro=eye;//eye=camera position, could move this for motion blur
    vec3 er = normalize( vec3( pxl.xy, fov ) );
    vec3 rd = er.x*uu + er.y*vv + er.z*ww;//uu,vv,ww are up right forward vectors
    vec3 go = blurAmount*focusDistance*vec3( -1.0 + 2.0*rand2(), 0.0 );
    vec3 gd = normalize( er*focusDistance - go );
    ro += go.x*uu + go.y*vv;
    rd += gd.x*uu + gd.y*vv;
    clr+=scene(ro,normalize(rd));
    clr.rgb = vec3(clamp(pow(clr.rgb,gammaCorrection),0.0,1.0));
    //glFragColor = vec4(mix(texture2D(tex,gl_FragCoord.xy/vec2(size.xy)).rgb,clr.rgb,1.0/(iRay+1)),1.0);
    glFragColor=clr;
    //gl_FragDepth = clamp(clr.a,0.01,0.99);
    
    
    /*
    vec3 dir = vec3(1.0,0.0,0.0);
    vec3 up = vec3(0,1,0);
    vec3 right = cross(dir, up);
    //vec3 pos = dir*-(mouse.y*8.0)+vec3(0,0.01,0);//+right*(mouse.x-0.50001)+up*(mouse.y-0.500002);
    vec3 pos= dir*-4.5+vec3(0.0,0.01,0.0);
    vec3 dir2 = normalize(dir+right*(gl_FragCoord.x / resolution.x - 0.5)+up*(gl_FragCoord.y-resolution.y*0.5)/resolution.x);
    glFragColor=vec4(color(pos,dir2),1.0);
    */
}

