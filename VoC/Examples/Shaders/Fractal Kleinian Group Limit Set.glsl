#version 420

// original https://www.shadertoy.com/view/XlVXzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//By Jos Leys ( with the help of Knighty)

vec3  background1Color=vec3(1.0,1.0,1.0);
vec3  background2Color=vec3(1.0,1.0,0.5);
vec2  ambientColor=vec2(0.5,0.3);
vec3  color2=vec3(0.2,0.6,0.0);
float specularExponent=4.;
float specularity=0.8;
vec3 from=vec3(0.0,0.975,-5.0);

float KleinR = 1.94+0.05*abs(sin(-time*0.5));//1.95859103011179;
float KleinI = 0.03*cos(-time*0.5);//0.0112785606117658;

float box_size_x=1.;
float box_size_z=1.;
vec3 light=vec3(50,10,-50);
float slice_start=-1.;
float slice_end=1.;
float fudge_factor=0.5;

//sphere inversion
bool SI=false;
vec3 InvCenter=vec3(1,.96,0.);
float rad=0.8;

vec2 wrap(vec2 x, vec2 a, vec2 s){
    x -= s; 
    return (x-a*floor(x/a)) + s;
}

void TransA(inout vec3 z, inout float DF, float a, float b){
    float iR = 1. / dot(z,z);
    z *= -iR;
    z.x = -b - z.x; z.y = a + z.y; 
    DF *= iR;//max(1.,iR);
}

float  JosKleinian(vec3 z)
{
    vec3 lz=z+vec3(1.), llz=z+vec3(-1.);
    float d=0.; float d2=0.;
    
    if(SI) {
             z=z-InvCenter;
        d=length(z);
        d2=d*d;
        z=(rad*rad/d2)*z+InvCenter;
            }

    float DE=1e10;
    float DF = 1.0;
    float a = KleinR;
    float b = KleinI;
    float f = sign(b)*1. ;     
    for (int i = 0; i < 20 ; i++) 
    {
        z.x=z.x+b/a*z.y;
        z.xz = wrap(z.xz, vec2(2. * box_size_x, 2. * box_size_z), vec2(- box_size_x, - box_size_z));
        z.x=z.x-b/a*z.y;
               
        //If above the separation line, rotate by 180° about (-b/2, a/2)
        if  (z.y >= a * 0.5 + f *(2.*a-1.95)/4. * sign(z.x + b * 0.5)* (1. - exp(-(7.2-(1.95-a)*15.)* abs(z.x + b * 0.5))))    
        {z = vec3(-b, a, 0.) - z;}
        
        //Apply transformation a
        TransA(z, DF, a, b);
        
        //If the iterated points enters a 2-cycle , bail out.
        if(dot(z-llz,z-llz) < 1e-5) {break;}
        
        //Store prévious iterates
        llz=lz; lz=z;
    }
    
    
    float y =  min(z.y, a-z.y) ;
    DE=min(DE,min(y,0.3)/max(DF,2.));
      if (SI) {DE=DE*d2/(rad+d*DE);}
    return DE;
}

float trace(vec3 ro, vec3 rd, float start,inout bool hit) {
    float dist=100.0;
    float t =start;
    for (int i = 0;  i < 200  ;i++) {
        if (t>(-ro.z+slice_end)/rd.z) {hit=false; break;}
        dist = JosKleinian(ro+t*rd);
        if (dist<1./pow(10.,3.5)) {break;}
        t += fudge_factor*dist;
    }
    return t;
}

vec3 blinnPhong(vec3 color, vec3 p, vec3 n)
{
    // Ambient colour based on background gradient
      float HALFPI=3.14159/2.;
    vec3 ambColor = clamp(mix(background2Color, background1Color, (sin(n.y * HALFPI) + 1.0) * 0.5), 0.0, 1.0);
    ambColor = mix(vec3(ambientColor.x), ambColor, ambientColor.y);
    vec3  halfLV = normalize(light - p);
    float diffuse = max(dot(n, halfLV), 0.0);
    float specular = pow(diffuse, specularExponent);
    
    return ambColor * color + color * diffuse + specular * specularity;
}

vec3 generateNormal(float afst,vec3 rd, vec3 from)
{
    float eps =0.001; bool hit=true;
       vec3 ray=  from+rd*afst;
    
    float start=afst-.1;
    
    vec3 ray1=from+vec3(eps,0,0)+ rd*trace(from+vec3(eps,0,0), rd,start,hit );
    vec3 ray2=from+vec3(0,eps,0)+ rd*trace(from+vec3(0,eps,0), rd,start,hit );
    vec3 ray3=from+vec3(-eps,0,0)+ rd*trace(from+vec3(-eps,0,0), rd,start,hit );
    
    vec3 n1=normalize(-cross(ray1-ray,ray2-ray));
    vec3 n2=normalize(-cross(ray2-ray,ray3-ray));
    
    vec3 n=(n1+n2)/2.;
    return n;
}

vec3  detcol( vec3  ray_direction)   
{
    bool hit=true;
    float start=(-from.z+slice_start)/ray_direction.z;
    float afst= trace(from, ray_direction,start,hit);
    vec3 ray=from+afst* ray_direction;
      

if ( !hit) {return background1Color;     }  

else {    
    vec4  color;
    vec3 normal = generateNormal(afst,ray_direction,from);
    color.rgb = blinnPhong(clamp(color2, 0.0, 1.0), ray, normal);
    
    // Shadows
        vec3 light_direction=normalize(ray-light);
        float startlight=(-light.z+slice_start)/light_direction.z;
        float afstlight= trace(light,light_direction,startlight,hit);
        if (abs(afstlight-length(light-ray))>0.001) {color.rgb *=0.8;}
    
    
    return color.xyz;}

}

void main(void)
{
    
       vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = (3.0)*uv-vec2(1.5,.5);
    uv.x *= resolution.x/resolution.y;
    
   
    vec3 rd = normalize(vec3(uv,0.)-from);

    float start=(-from.z-1.)/rd.z;

    
    vec3 c =detcol(rd);
    glFragColor = vec4(c, 1.0);
    
}

