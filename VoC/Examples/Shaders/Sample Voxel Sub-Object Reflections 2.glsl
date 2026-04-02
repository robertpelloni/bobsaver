#version 420

// original https://www.shadertoy.com/view/sddSz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

Voxel Sub-Object Reflections
An extension of the voxel shader by jt:

Cast Voxels March Sub-Objects
https://www.shadertoy.com/view/7sdSzH

This shader demonstrates reflections within
a voxel shader, that reflect the image based on
what objects (SDFs in this case) are stored
inside each voxel.

There is another purly voxel relflection shader
by wildniklin:
Voxel Reflections
https://www.shadertoy.com/view/NsjSWy

and iq has another voxel shader with sub-voxel
objects with emissive objects (so multiple light 
bounces)

BTW this could be wayy faster. I did everything 
in the voxel marching the slowest way with branching.

It was more for me to review what is actually going
on. 

The code is bloated over all.
*/
#define far 50.

mat2 rot(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

float rnd(vec3 st){
    return fract(sin(dot(vec2(12.44,74.92),st.xz) + st.y)*43134.0);
    }

float formID = 0.;
float sdSphere(vec3 p, float d)
{
    return length(p) - d;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float Sphere_Box_LERP(vec3 p){

    float id = formID;
    
    float left = (sdBox(p,vec3(0.3)) - id/6.)*(step(0.,p.x));
    float right = (sdSphere(p,0.5))*(step(p.x,0.));
    //return  right;
    return mix(sdSphere(p,0.5),
               sdBox(p,vec3(id*0.4)) 
               - (1.-id*0.3)/4., id);
    
}
bool getVoxel(vec3 c) {
    //c.xz *= rot(time);
    vec3 p = vec3(c) + vec3(0.5);
    float d = min(sdSphere(p-vec3(-4.,0.,0.), 2.5), 
                  sdBox(p-vec3(4.,0.,0.), vec3(2.0)));
    //float d = min(max(-sdSphere(p, 7.5), sdBox(p, vec3(6.0))), -sdSphere(p, 25.0));
    return d < 0.0;
}

bool map(vec3 p){
    //return getVoxel(p);
    //return length(p) - 1.5 < 0.;//
    return (5.-length(p.xy + vec2(sin(p.z/8.)*6., 0.))) < 0.00;
}

float fMap(vec3 p){
    
    return Sphere_Box_LERP(p);
    return length(p)-0.5;
}

vec3 ray(vec2 uv, vec3 ro, vec3 lk){
    vec3 fwr = normalize(lk - ro);
    vec3 uu = vec3(0.,1.,0.);
    vec3 ri = cross(uu,fwr);
    vec3 up = cross(fwr,ri);
    return normalize(ri * uv.x + up * uv.y + fwr);
}

vec3 normal(vec3 p){

    vec2 e = vec2(0.001,0.);
    return normalize(vec3(
    fMap(p - e.xyy) - fMap(p + e.xyy),
    fMap(p - e.yxy) - fMap(p + e.yxy),
    fMap(p - e.yyx) - fMap(p + e.yyx)
    ));
}

float trace(vec3 ro,vec3 rd){
    float t = 0., d;
    
    for(float i = 0.; i < 50.; i++){
        d = fMap(ro + rd*t);
        
        if(d < 0.001 ) return t;
        
        t += d;
    }
    return far;
}

float voxelTrace(inout vec3 ro, 
                 inout vec3 rd,
                 inout vec3 col){

    vec3 pos = floor(ro);
    vec3 delta = abs(1./rd + 0.001);
    vec3 steps = vec3(0.);
    
    vec3 light1 = vec3(0.,sin(time)*8.,0.);
    
    steps.x = rd.x < 0. ? 
      (ro.x - pos.x)*delta.x : 
      (pos.x + 1. - ro.x)*delta.x;
    
    steps.y = rd.y < 0. ? 
      (ro.y - pos.y)*delta.y : 
      (pos.y + 1. - ro.y)*delta.y;
      
    steps.z = rd.z < 0. ? 
      (ro.z - pos.z)*delta.z : 
      (pos.z + 1. - ro.z)*delta.z;
    
    vec3 richtung = sign(rd);
    
    float t = 100.;
    
    for(int i = 0; i < 100; i++ ){
    
        if(map(pos)) {
            //throw this in here, make a global
            //id for the shape of the  sub-object.
            float id = rnd(pos);
            formID = id;
            
            // this: ro - pos - 0.5; shifts the 
            // null forward because we always check 
            // the space around 0.,0.! 
            // and -0.5 is for the same reason 
            // because we always shoot rays in from 
            // a place on a cube, it's like 
            // shooting into a square screen and 
            // we need to shift the world 
            // 0.5 in every dimention 
            vec3 shift = pos + 0.5;
            //  the - shift is then 
            // -(pow + 0.5) = -pos - 0.5
            
            
                   
                   
            float h = trace(ro - shift, rd);
            
               if( h < far && h > 0.){
                   
                   t = h;
                   vec3 p = (ro - shift + rd*t);
                   
                   vec3 l = light1 - shift;
                   vec3 ldir = l - p;
                   vec3 n = normal(p);
                   
                   float ldist = max(length(l),0.);
                   ldir/=ldist;
                   
                   float diff = max(dot(-ldir,n),0.);
                   float spec = pow(max(dot(reflect(-ldir,n),-rd),0.),8.);
                   vec3 amb = 0.5 + 0.5*cos(vec3(1.,2.,4.)/4. + id*80.);
                   col += diff*amb + spec;
                   
                   //needed a plus five here to work!
                   //wow
                   ro = pos + 0.5;// + n*.01;//nothing changes
                   rd = reflect(rd, n);
                   // + n*0.01;
                   
                   return h;
            }
            
        }
        
        if(min(steps.x,min(steps.y,steps.z)) 
            == steps.x){
            //adding 1's and -1's to the position
            pos.x += richtung.x;
            //adding delta components to the t line
            steps.x += delta.x;
        }
        else if(min(steps.x,min(steps.y,steps.z)) 
                    == steps.y){    
            pos.y += richtung.y;
            steps.y += delta.y;
        }
        else
        {
            pos.z += richtung.z;
            steps.z += delta.z;
        }
    }
    return far;
    
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(0.,0., -4.);
    ro.xz*= rot(time/8.);
    vec3 lk = vec3(0.,0.,0.);
    vec3 rd = ray(uv, ro, lk);
    //rd.xz*= rot(time);
    vec3 col = vec3(0.);
    vec3 rcol = vec3(0.);
    // Time varying pixel color
   float t = voxelTrace(ro,rd,col);
   if(t < far) voxelTrace(ro,rd,rcol);
   //col = vec3((1.-t)*vec3(0.7,0.37,0.0));
   col += rcol*0.38;
    // Output to screen
    col = mix(col, vec3(0.),t*2./far);
    glFragColor = vec4(col,1.0);
}
