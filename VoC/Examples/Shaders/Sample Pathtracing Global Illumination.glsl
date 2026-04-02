#version 420

//this code was derived by eiffie from Inigo Quilez's artical on brute force path tracing found here:
//http://www.iquilezles.org/www/articles/simplepathtracing/simplepathtracing.htm
//http://www.fractalforums.com/fragmentarium/inigo-quilez%27s-brute-force-global-illumination/msg54315/

uniform vec3 sunDirection=vec3(0.25,1.0,-0.25);
uniform vec3 sunColor=vec3(1.0,1.0,0.5);
uniform vec3 skyColor=vec3(0.3,0.6,1.0);
uniform vec3 floorColor=vec3(0.125,0.19,0.12);
uniform vec3 mengerColor=vec3(0.95,0.95,0.95);
uniform float mengerReflect=0.2;
uniform vec3 mandelbulbColor=vec3(0.7,0.7,0.9);
uniform float mandelbulbReflect=0.4; //negative reflection means refract
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;
uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform float random1,random2; //passed random numbers inside textures, these come from voc
uniform int frames;

out vec4 glFragColor;

uniform int RayBounces=5;
uniform int MaxRaySteps=128;
const float maxDepth=10.0;    //depth of scene

float side=1.0; //1.0=outside, -1.0=inside of object
//each object in the scene has an id (0,1,2) so create a material for each
vec4[3] material = vec4[3]
(      //array of materials (color,reflectivity)  negative reflection means refract
    vec4(floorColor,0.1),
    vec4(mengerColor,mengerReflect),
    vec4(mandelbulbColor,mandelbulbReflect)
);

//some simple distance estimate functions
float DESphere(in vec3 z, float radius){return length(z)-radius;}
float DEBox(in vec3 z, float hlen){return max(abs(z.x),max(abs(z.y),abs(z.z)))-hlen;}

const float scale=3.0;//menger constants
const vec3 offset=vec3(1.0,1.0,1.0);
const int iters=5;
const float psni=pow(scale,-float(iters));

float DEMenger(in vec3 z)
{
    for (int n = 0; n < iters; n++) {
        z = abs(z);
        if (z.x<z.y)z.xy = z.yx;
        if (z.x<z.z)z.xz = z.zx;
        if (z.y<z.z)z.yz = z.zy;
        z = z*scale - offset*(scale-1.0);
        if(z.z<-0.5*offset.z*(scale-1.0))z.z+=offset.z*(scale-1.0);
    }
    return DEBox(z,scale*0.5)*psni;
}

float DEBulb(vec3 z0)
{
    vec3 c = z0*4.0,z = z0*4.0;
    float dr = 4.0,r = length(z),zr,zo,zi,p=8.0;
    for (int n = 0; n < 2 && r<2.0; n++) {
        zo = asin(z.z / r) * p;
        zi = atan(z.y, z.x) * p;
        zr = pow(r, p-1.0);
        dr = dr * zr * p + 1.0;
        z=(r*zr)*vec3(cos(zo)*vec2(cos(zi),sin(zi)),sin(zo))+c;
        r = length(z);
    }
    return 0.5 * log(r) * r / dr;
}

//you need to implement this function!!!
vec2 map(in vec3 pos)
{//return distance estimate and object id
    float flr=pos.y+1.0;
    float bal=DEBulb(pos+vec3(0.0,0.0,0.0));
    float mgr=DEMenger(pos);
    float id=1.0;
    if(bal<mgr)id=2.0;
    bal=min(bal,mgr);
    return vec2(min(flr,bal),(flr<bal)?0.0:id);
}

// you don't need to change the following unless you want to :)

vec3 getColor( in vec3 pos, in vec3 nor, in float item )
{//get the color of the surface at a point based on the item hit
    return material[int(item)].rgb;
}

vec3 getBackground( in vec3 rd ){return skyColor;}

vec2 intersect(in vec3 ro, in vec3 rd )
{//march the ray until you hit something or go out of bounds
    float t=0.01;vec2 h;
    side=sign(map(ro+t*rd).x);
    for(int i=0;i<MaxRaySteps && t<maxDepth;i++){
        h=map(ro+t*rd);
        t+=h.x*side;
        if(abs(h.x)<0.001)return vec2(t,h.y);
    }//returns distance, object id
    return vec2(t,(t<maxDepth)?h.y:-1.0);
}

const vec3 ve=vec3(0.0001,0.0,0.0);
vec3 getNormal( in vec3 pos, in float item )
{// get the normal to the surface at the hit point
    return side*normalize(vec3(-map(pos-ve.xyy).x+map(pos+ve.xyy).x,
        -map(pos-ve.yxy).x+map(pos+ve.yxy).x,-map(pos-ve.yyx).x+map(pos+ve.yyx).x));
}

vec3 shadow(in vec3 ro, in vec3 rd )
{//if we hit a transparent object we refract thru it losing alittle light
    float saveSide=side;vec3 shad=vec3(1.0);
    for(int i=0;i<RayBounces && dot(shad,shad)>0.1;i++){
        vec2 h=intersect( ro, rd );
        if(h.y==-1.0)break;
        else {
            float r=material[int(h.y)].a;
            if(r>=0.0){shad=vec3(0.0,0.0,0.0);break;}
            ro+=rd*h.x;
            vec3 nor = getNormal( ro, h.y );
            shad*=getColor(ro, nor, h.y)*abs(r);
            vec3 rdNew=(side>=0.0)?refract(rd,nor,0.75):refract(rd,nor,1.33);
            if(dot(rdNew,nor)<-0.05)rd=rdNew;
            else rd=reflect(rd,nor);
        }
    }
    side=saveSide;
    return shad;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rand2()
{
    vec2 c = gl_FragCoord.xy/resolution.xy;
    //return vec2( (texture2D(random1,c).r+texture2D(random1,c).g+texture2D(random1,c).b)/3.0-0.5 , (texture2D(random2,c).r+texture2D(random2,c).g+texture2D(random2,c).b)/3-0.5 );
    //return vec2(gl_FragData[3].r,gl_FragData[4].r);
    return vec2(rand(c-time),rand(c+time));
}

vec3 cosineDirection(in vec3 nor)
{//return a random direction on the hemisphere
    vec2 r = rand2()*6.283;
    vec3 dr=vec3(sin(r.x)*vec2(sin(r.y),cos(r.y)),cos(r.x));
    return (dot(dr,nor)<0.0)?-dr:dr;
}

vec3 applyLighting( in vec3 pos, in vec3 nor )
{//randomly sample the sun or sky (or add more lights;)
    vec3 liray,dcol=skyColor;
    if(rand2().x<0.5){// sample sun
             liray = normalize(1000.0*sunDirection + 50.0*cosineDirection(nor) - pos );
             dcol = max(0.0, dot(liray, nor)) * sunColor;
         }else{// sample sky
            liray = normalize(1000.0*cosineDirection(nor) - pos );
    }
         return dcol * shadow( pos, liray );
}

vec3 getBRDFRay( in vec3 nor, in vec3 rd, in float item )
{//randomly direct the ray in a hemisphere or cone based on reflectivity
    if( rand2().x > abs(material[int(item)].a) ) return cosineDirection( nor );
    else {//return a cone direction for a reflected or refracted ray
        vec3 p=reflect(rd,nor);
        if(material[int(item)].a<0.0){//refract or reflect perfectly
            if(rand2().x<0.75){
                rd=(side>=0.0)?refract(rd,nor,0.75):refract(rd,nor,1.33);
                if(dot(rd,nor)<-0.05)p=rd;//if the ray is incident to surface just reflect
            }
            return normalize(p);
        } 
        return normalize(p+cosineDirection(p)*0.1);
    }
}

vec3 color(vec3 ro, vec3 rd) 
{// find color of scene
    vec3 tcol = vec3(0.0),fcol = vec3(1.0);
    for( int i=0; i <RayBounces && dot(fcol,fcol)>0.1; i++ )
    {// create light paths iteratively
        vec2 hit = intersect( ro, rd );
            if( hit.y >= 0.0 ){//hit something
                ro+= rd * hit.x;// advance ray position
                vec3 nor = getNormal( ro, hit.y );// get the surface normal
            fcol *= getColor( ro, nor, hit.y ); // modulating surface colors
            tcol += fcol * applyLighting( ro, nor ); // adding modulated color * direct light
            rd = getBRDFRay( nor, rd, hit.y );// prepare ray for indirect light gathering (bounce)
        }else{//hit nothing so bail
            tcol+=fcol*getBackground( rd );
            break;
        }
    }
    return clamp(tcol,0.0,1.0);
}     

void main(){
    
    //vec3 dir = vec3(cos(time*0.2),0,sin(time*0.2));
    vec3 dir = vec3(1.0,0.0,0.0);
    vec3 up = vec3(0,1,0);
    vec3 right = cross(dir, up);
    
    //vec3 pos = dir*-(mouse.y*8.0)+vec3(0,0.01,0);//+right*(mouse.x-0.50001)+up*(mouse.y-0.500002);
    vec3 pos= dir*-1.5+vec3(0.0,0.01,0.0);
    vec3 dir2 = normalize(dir+right*(gl_FragCoord.x / resolution.x - 0.5)+up*(gl_FragCoord.y-resolution.y*0.5)/resolution.x);

    glFragColor=vec4(color(pos,dir2),1.0);
}
