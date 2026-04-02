#version 420

// Mirror Fractals by eiffie 
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Original https://www.shadertoy.com/view/lsl3D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int Rays=8,MaxBounces=15;//up these for better quality
const float fov = 1.5,maxDepth=100.0;
const vec3 sunColor=vec3(1.0,0.9,0.8),sunDir=vec3(0.577,0.577,-0.577),skyColor=vec3(0.23,0.14,0.25);

struct material {vec3 color;float difExp,spec,specExp;}mtrl;
struct intersect {float t; int obj; vec3 ro,rd,nor;}intr;

void Sphere(vec3 p, float r, int obj)
{
    p = intr.ro - p;
    float b = dot( -p, intr.rd );
    float inner = b * b - dot( p, p ) + r * r;
    if( inner < 0.0 ) return;
    float d = sqrt( inner );
    float t1 = b - d, t2 = b + d;
    t1 = (t1 >= 0.0) ? t1 : maxDepth;
    t2 = (t2 >= 0.0) ? t2 : maxDepth;
    t1 = min( t1, t2 );
    if(t1 < intr.t ){intr.t = t1; intr.obj = obj; intr.nor = normalize( p + intr.rd * t1 );}
}

void Plane(vec3 n, float d, int obj)
{
    float t = -( dot( n, intr.ro ) + d ) / dot( n, intr.rd );
    if(t >= 0.0 && t < intr.t ){
        if(intr.ro.y+intr.rd.y*t>3.0)return;
        intr.nor=n;intr.obj=obj;intr.t=t;
    }
}

void Box(vec3 p, vec3 s, int obj)
{
    p = intr.ro - p;
    vec3 t0 = (-s - p ) / intr.rd, t1 = ( s - p ) / intr.rd;
    vec3 n = min( t0, t1 ), f = max( t0 ,t1 );
    float tmin = max( n.x, max( n.y, n.z ) ), tmax = min( f.x, min( f.y, f.z ) );
    if( tmin > 0.0 && tmin <= tmax && tmin < intr.t ){
        if( tmin == t0.x )intr.nor=vec3(-1.0,0.0,0.0);
        else if( tmin == t1.x )intr.nor=vec3(1.0,0.0,0.0);
        else if( tmin == t0.y )intr.nor=vec3(0.0,-1.0,0.0);
        else if( tmin == t1.y )intr.nor=vec3(0.0,1.0,0.0);
        else if( tmin == t0.z )intr.nor=vec3(0.0,0.0,-1.0);
        else intr.nor=vec3(0.0,0.0,1.0);
        intr.obj=obj;
        intr.t=tmin;
    }
}

void Trace(){
    intr.t = maxDepth; intr.obj = -1;
    Sphere(vec3(0.0),1.0,2);
    Plane(vec3(0.0,1.0,0.0),1.0,1);
    Box(vec3(0.0,1.0,0.0),vec3(10.0,0.2,0.2),0);
    for(int i=0;i<3;i++){
        float a=float(i)*6.283*0.3333333;
        vec3 p=vec3(8.05,sin(time*3.0)*0.25,0.0);
        p.xz=p.xz*mat2(cos(a),-sin(a),sin(a),cos(a));
        if(time<60.0)Sphere(p,7.0,3+i);
        else Plane(normalize(p),1.25,3+i);
    }
    intr.ro += intr.rd * intr.t;// advance ray position to hit point
}

void getMaterial(){
    if( intr.obj == 2 ){//sphere
        mtrl = material( vec3(0.8,0.6,0.2),65536.0, 0.7, 65536.0 );
    }else if( intr.obj == 1 ){//plane
        mtrl = material(pow(abs(sin(intr.ro*5.0)),vec3(32.0))*vec3(0.8,1.0,0.7),32.0,0.0,32.0);
    }else if( intr.obj == 0){//box
        mtrl = material(mix(vec3(0.2,0.4,0.8),vec3(0.8,0.4,0.2),smoothstep(-1.0,1.0,intr.ro.x)),pow(2.0,7.0),1.0,2048.0);
    }else mtrl = material( vec3(0.5+float(intr.obj)*0.2,0.7,0.75), 65536.0, 0.9, 65536.0 );
}

vec3 getBackground( in vec3 rd ){
    return skyColor+rd*0.15+sunColor*(pow(max(0.0,dot(rd,sunDir)),2.0)+pow(max(0.0,dot(rd,sunDir)),80.0)*4.0);
}

//the code below can be left as is so if you don't understand it that makes two of us :)

//random seed and generator
vec2 randv2;
vec2 rand2(){// implementation derived from one found at: lumina.sourceforge.net/Tutorials/Noise.html
    randv2+=vec2(1.0,1.0);
    return vec2(fract(sin(dot(randv2.xy ,vec2(12.9898,78.233))) * 43758.5453),
        fract(cos(dot(randv2.xy ,vec2(4.898,7.23))) * 23421.631));
}
 
vec3 powDir(vec3 nor, vec3  dir, float power) 
{//creates a biased random sample without penetrating the surface (approx Schlick's)
    float ddn=max(0.01,abs(dot(dir,nor)));
    vec2 r=rand2()*vec2(6.283,1.0);
    vec3 nr=(ddn<0.99)?nor:((abs(nor.x)<0.5)?vec3(1.0,0.0,0.0):vec3(0.0,1.0,0.0));
    vec3 sdir=normalize(cross(dir,nr));
    r.y=pow(r.y,1.0/power);
    vec3 ro= normalize(sqrt(1.0-r.y*r.y)*(cos(r.x)*sdir + sin(r.x)*cross(dir,sdir)*ddn) + r.y*dir);
    return (dot(ro,nor)<0.0)?reflect(ro,nor):ro;
}

vec3 scene(vec3 ro, vec3 rd) {// find color of scene
    vec3 fcol=vec3(1.33);
    intr.ro = ro; intr.rd = rd; intr.obj = 0;
    for(int i=0; i<MaxBounces; i++ ){// bounce loop
        if(intr.obj < 0)continue;
        Trace();//get distance into scene
        if(intr.obj >= 0){//hit something
            getMaterial();//match material properties to item hit
            vec3 refl=reflect(intr.rd,intr.nor);//setting up for a new ray direction and defaulting to a reflection
            if(intr.obj>=2)intr.rd=refl;//these have perfect reflections
            else intr.rd=powDir(intr.nor,refl,mtrl.difExp);//redirect the ray with random slop
            //the next line calcs the amount of energy left in the ray based on how it bounced (diffuse vs specular) 
            fcol*=0.9*mix(mtrl.color,vec3(1.0),min(pow(max(0.0,dot(intr.rd,refl)),mtrl.specExp)*mtrl.spec,1.0));
            intr.ro += intr.rd * 0.0001;//pushs away/thru the surface
            if(dot(fcol,fcol)<0.01)intr.obj = -1;//bail out since light energy is low
        }
    }
    return fcol*getBackground(intr.rd);//light the scene
}    

mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(up)));return mat3(rt,cross(rt,fw),fw);
}

#define time2 time*0.5
#define size resolution
void main() {
    intr.nor=vec3(0.0);
    randv2=fract(cos((gl_FragCoord.xy+gl_FragCoord.yx*vec2(1000.0,1000.0))+vec2(time2)*10.0)*10000.0);
    vec3 clr=vec3(0.0);
    float tim=time2;
    vec3 ro=vec3(cos(tim),sin(tim*0.6)*0.75,sin(tim))*1.05;
    mat3 rotCam=lookat(-ro.zyx,vec3(cos(tim*1.2)*0.2,1.0+sin(tim*0.3)*0.2,sin(tim*0.7)*0.2));
    for(int iRay=0;iRay<Rays;iRay++){
        vec2 pxl=(-size.xy+2.0*(gl_FragCoord.xy+rand2()))/size.y;//+rand2()
        vec3 er = normalize( vec3( pxl.xy, fov ) );
        clr+=scene(ro, rotCam*er);
    }
    clr/=vec3(Rays);
    glFragColor = vec4(clr,1.0);
}
