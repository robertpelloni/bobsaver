#version 420

//Cole Kissane 9-12-2017
//Mandelbrot 3d?
//coler706@gmail.com
//coler706.github.io

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCHING_STEPS 250
#define NEAR 0.0
#define FAR 20.0
#define EPSILON 0.01
#define maxSteps 20
float sphereSDF(vec3 p, float radius)
{
    return length(p) - radius;
}
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
vec4 juliaSDF(vec4 p,float slice)
{
    float steps=float(maxSteps);
    float poP=2.0;
 vec2 pc=vec2(-max((p.x),max((p.y),max((p.z),(p.w)))),p.x*p.y*p.z*p.w);//pow(pow(abs(p.x),poP)+pow(abs(p.y),poP)+pow(abs(p.z),poP)+pow(abs(p.w),poP)-pow(abs(max((p.x),max((p.y),max((p.z),(p.w))))),poP),1.0/poP))*1.0;
    vec4 p2=p;//vec4(pc,pc);
    vec2 c=vec2(p2.x,p2.y);
    vec2 z=vec2(p2.z,p2.w);
    
    for(int i=0;i<maxSteps;i++){
        if(length(z)>2.0){
        steps=(min(float(steps),float(i)));
            if ( steps < float(maxSteps) ) {
    // sqrt of inner term removed using log simplification rules.
    float log_zn = log( length(z) ) ;
    float nu =  log(log( length(z) )/log(4.0)) ;
    // Rearranging the potential function.
    // Dividing log_zn by log(2) instead of log(N = 1<<8)
    // because we want the entire palette to range from the
    // center to radius 2, NOT our bailout radius.
    steps = steps;// +1.0-nu;
  }
            break;
        }
        vec2 po=vec2(length(z),atan(z.y,z.x));
        float zPow=2.0;
        po=vec2(pow(po.x,zPow),po.y*zPow);
        z=vec2(cos(po.y)*po.x,sin(po.y)*po.x)+c;
    }
    
    //vec3 color=vec3(sin(steps)/2.0+0.5,cos(steps)/2.0+0.5,0.5-sin(steps)/2.0);//min(abs(z.x),1.0),min(abs(z.y),1.0),0.0);
    vec3 color= vec3(min(abs(z.x),1.0),min(abs(z.y),1.0),0.0);
    
    //color.z=sin(steps)/2.0+0.5;//min(1.0-length(color),1.0);
    //color.z=min(1.0-length(color),1.0);
    //color=normalize(normalize(color)-vec3(0.1));
    //color.x=floor(sin(z.x)*0.5+1.0);
    //color.y=floor(sin(z.y)*0.5+1.0);
    color=hsv2rgb(vec3(atan(z.y,z.x)/atan(0.0,-1.0)/2.0,0.5,0.5));
    color=color*(((floor(sin(z.y*10.0)*0.5+1.0)-0.5)*(floor(sin(z.x*10.0)*0.5+1.0)-0.5)*4.0+0.5)*0.1+0.9);
    color=hsv2rgb(vec3(mod(abs(steps/10.0),1.0),0.5,0.5));
 return vec4(color,(float(maxSteps)-0.0)/float(steps+1.0)*EPSILON/2.0);//vec4(color,(max(abs(p.x),max(abs(p.y),max(abs(p.z),abs(p.w))))-1.0)/2.0);//EPSILON*(float(maxSteps)-0.0)/float(steps+1.0));
}
vec4 crazySDF(vec4 p,float slice)
{
    float steps=float(maxSteps);
    float poP=2.0;
 vec2 pc=vec2(-max((p.x),max((p.y),max((p.z),(p.w)))),p.x*p.y*p.z*p.w);//pow(pow(abs(p.x),poP)+pow(abs(p.y),poP)+pow(abs(p.z),poP)+pow(abs(p.w),poP)-pow(abs(max((p.x),max((p.y),max((p.z),(p.w))))),poP),1.0/poP))*1.0;
    vec4 p2=p;//vec4(pc,pc);
 vec3 c=vec3(p.x,p.y,p.z);
    vec3 z=vec3(p.x,p.y,p.z);
    
    for(int i=0;i<maxSteps;i++){
        if(length(z)>2.0){
        steps=(min(float(steps),float(i)));
            if ( steps < float(maxSteps) ) {
    // sqrt of inner term removed using log simplification rules.
    float log_zn = log( length(z) ) ;
    float nu =  log(log( length(z) )/log(4.0)) ;
    // Rearranging the potential function.
    // Dividing log_zn by log(2) instead of log(N = 1<<8)
    // because we want the entire palette to range from the
    // center to radius 2, NOT our bailout radius.
    steps = steps;// +1.0-nu;
  }
            break;
        }
        vec4 po=vec4(length(z),atan(z.x,length(z.yz)),atan(z.y,length(z.xz)),atan(z.z,length(z.xy)));
        float zPow = 5.0;
        po=vec4(pow(po.x,zPow),po.y*zPow,po.z*zPow,po.w*zPow);
        z=vec3(sin(po.y)*po.x,sin(po.z)*po.x,sin(po.w)*po.x)+c;
    }
    
    //vec3 color=vec3(sin(steps)/2.0+0.5,cos(steps)/2.0+0.5,0.5-sin(steps)/2.0);//min(abs(z.x),1.0),min(abs(z.y),1.0),0.0);
    vec3 color= vec3(min(abs(z.x),1.0),min(abs(z.y),1.0),0.0);
    
    //color.z=sin(steps)/2.0+0.5;//min(1.0-length(color),1.0);
    //color.z=min(1.0-length(color),1.0);
    //color=normalize(normalize(color)-vec3(0.1));
    //color.x=floor(sin(z.x)*0.5+1.0);
    //color.y=floor(sin(z.y)*0.5+1.0);
 return vec4(vec3(1.0,1.0,1.0),(float(maxSteps)-0.0)/float(steps+1.0)*EPSILON/2.0);//vec4(color,(max(abs(p.x),max(abs(p.y),max(abs(p.z),abs(p.w))))-1.0)/2.0);//EPSILON*(float(maxSteps)-0.0)/float(steps+1.0));
}
vec4 un(vec4 a,vec4 b){
    if(b.w<a.w){
        return b;
    }
    return a;
}
vec4 intersect(vec4 a,vec4 b){
    if(b.w>a.w){
        return b;
    }
    return a;
}
float ScTP(vec3 a, vec3 b, vec3 c){
    return dot(cross(a,b),c);
}
vec4 bary_tet(vec3 a, vec3 b, vec3 c, vec3 d, vec3 p)
{
    vec3 vap = p - a;
    vec3 vbp = p - b;

    vec3 vab = b - a;
    vec3 vac = c - a;
    vec3 vad = d - a;

    vec3 vbc = c - b;
    vec3 vbd = d - b;
    // ScTP computes the scalar triple product
    float va6 = ScTP(vbp, vbd, vbc);
    float vb6 = ScTP(vap, vac, vad);
    float vc6 = ScTP(vap, vad, vab);
    float vd6 = ScTP(vap, vab, vac);
    float v6 = 1.0 / ScTP(vab, vac, vad);
    return vec4(va6*v6, vb6*v6, vc6*v6, vd6*v6);
}
vec4 sceneSDF(vec3 p,float slice)
{
    float sect=0.0;
    //return juliaSDF(vec4(0.4,0.5,p.x,p.z))+vec4(0.0,0.0,0.0,p.y/20.0);//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //return juliaSDF(vec4(p.x,p.z,p.x,p.z))+vec4(0.0,0.0,0.0,p.y/10.0);//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //+++
    if(p.y*1.0-p.z*sect>mouse.y*2.0-1.0){
        //return vec4(vec3(0.0),p.y*1.0-p.z*sect+EPSILON-(mouse.y*2.0-1.0));
    }
    
    //return juliaSDF(vec4(p.x,p.z,p.y*1.0-p.z*sect,sect));//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //+++
    //return un(juliaSDF(vec4(p.x,p.z,p.y*1.0-p.z*sect,sect)),juliaSDF(vec4(p.x,p.z,sect,p.y*1.0-p.z*sect)));//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //return un(juliaSDF(vec4(p.x-1.0,p.z,p.y*1.0-p.z*sect,sect)),juliaSDF(vec4(p.x+1.0,p.z,sect,p.y*1.0-p.z*sect)));//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //return un(intersect(juliaSDF(vec4(p.x,p.z,p.y*1.0-p.z*sect,sect)),vec4(vec3(0.0),p.y*1.0-p.z*sect+EPSILON-(mouse.y*2.0-1.0))),intersect(juliaSDF(vec4(p.x,p.y-(mouse.y*2.0-1.0),sect,p.z*1.0-p.y*sect-(mouse.y*2.0-1.0))),vec4(vec3(0.0),p.z*1.0-p.y*sect+EPSILON)));//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //return juliaSDF(vec4(p.x+2.0*mouse.x*0.0-1.0+p.y*1.0,p.z+2.0*mouse.y*0.0-0.0,p.x,p.z));//-(-p.y*30.0)*EPSILON;//sphereSDF(p, 1.0);
    //return juliaSDF(vec4(p.x,p.z,p.x+sin(time/10.0)*1.0,p.z))-(-p.y/10.0);//sphereSDF(p, 1.0);
    vec3 a=vec3(1.0,0.0,-1.0/sqrt(2.0));
    vec3 b=vec3(-1.0,0.0,-1.0/sqrt(2.0));
    vec3 c=vec3(0.0,1.0,1.0/sqrt(2.0));
    vec3 d=vec3(0.0,-1.0,1.0/sqrt(2.0));
    vec4 coord=bary_tet(a,b,c,d,p);
 vec2 np=(vec2(clamp(coord.x,-1.0,1.0)+clamp(coord.y,-1.0,1.0),clamp(coord.z,-1.0,1.0)+clamp(coord.w,-1.0,1.0)));
 return crazySDF(vec4(p,1.0),slice);
 //return juliaSDF(coord-vec4(0.5,0.5,0.5,0.5),slice);//juliaSDF((coord-vec4(1.0,1.0,1.0,1.0)/2.0)*2.0,slice);//-(-p.y*30.0)*EPSILON;//sphereSDF(p,1.0);
}

vec3 getNormal(vec3 p,float slice) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z),slice).w - sceneSDF(vec3(p.x - EPSILON, p.y, p.z),slice).w,
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z),slice).w - sceneSDF(vec3(p.x, p.y - EPSILON, p.z),slice).w,
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON),slice).w - sceneSDF(vec3(p.x, p.y, p.z - EPSILON),slice).w
    ));
}

vec4 getDistance(vec3 eye, vec3 ray,float slice) {
    float depth = NEAR;

    for(int i = 0; i < MAX_MARCHING_STEPS; i++) {
        vec4 dist = sceneSDF(eye + depth * ray,slice);
        if(dist.w < EPSILON) {
            return vec4(dist.xyz,depth);
        }

        depth += dist.w;

        if(depth >= FAR) {
            return vec4(vec3(0.0),FAR);
        }
    }

    return vec4(vec3(0.0),FAR);
}

vec3 getRay(vec2 p, float fov, vec3 eye, vec3 target, vec3 up)
{
    vec3 dir = normalize(eye - target);
    vec3 side = normalize(cross(up, dir));
    float z = - up.y / tan(radians(fov) * 0.5);
    return normalize(side * p.x + up * p.y + dir * z);
}

vec4 render(float t, vec2 p)
{
    float fov = 20.0;
    float speed=atan(1.0,0.0);
    float angle=time*speed;
    vec3 eye = 10.0*vec3(sin(angle), 0.5, cos(angle));
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 up = vec3(0.0, 1.0, 0.0);

    vec3 ray = getRay(p, fov, eye, target, up);
    vec3 color=vec3(0.0);
    float tot=0.0;
    
float slice=0.0;//sin(time*100.0+sin(time*100.0+sin(time*100.0)));
    vec4 dist = getDistance(eye, ray,slice);

    if(dist.w == FAR) {
        return vec4(1.0, 1.0, 1.0, 1.0);
    }else{

    vec3 normal = getNormal(eye + dist.w * ray,slice);

    float diff = dot(normal, normalize(vec3(1.0, 1.0, 1.0)));

   // color=color+dist.xyz*(diff*0.5+0.5);//vec4(vec3(-(eye + dist.w * ray).y*1.0,1.0+(eye + dist.w * ray).y,0.0)*diff*0.0+vec3(diff/2.0+0.5,(diff/2.0+0.5)/2.0,(diff/2.0+0.5)/1.5), 1.0);
        //tot=tot+1.0;
        color=color+dist.xyz*(diff*0.5+0.5)/(dist.w+0.1);//vec4(vec3(-(eye + dist.w * ray).y*1.0,1.0+(eye + dist.w * ray).y,0.0)*diff*0.0+vec3(diff/2.0+0.5,(diff/2.0+0.5)/2.0,(diff/2.0+0.5)/1.5), 1.0);
        tot=tot+1.0/(dist.w+0.1);
    }
    
    return vec4(color/max(0.01,tot),1.0);
    
}

void main( void ) {
 vec2 p = 2.0 * (gl_FragCoord.xy / resolution.xy - 0.5)*vec2(resolution.x/resolution.y,1.0);
    glFragColor = render(time, p);
}
