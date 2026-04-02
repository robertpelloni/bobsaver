#version 420

// original https://www.shadertoy.com/view/NsBXzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Material Maker Experiment 002
// By PauloFalcao
//
// Made in the node base material maker
//
// Youtube video making this https://youtu.be/VzV9zOzzUVA
//
// MaterialMaker is a nodebased shader maker to make procedural textures
// With custom nodes GLSL nodes created directly in the tool,
// it's possible to make complex stuff like raymarching :)
//
// It's also possible to export the generated code to Shadertoy!
//
// I made a library with Ray Marching nodes
// 1st version 0.01 have 44 new nodes
// Some nodes are based in code from other authors from shadertoy
// I always refer the shader author and the shadertoy original code
// The idea is to reuse the code to quicky create something without coding experience
// Or just focus on the code of a single node
//
// You need Material Maker - https://rodzilla.itch.io/material-maker
// And my library - https://github.com/paulofalcao/MaterialMakerRayMarching
// 

float iq_sdOctahedron( vec3 p, float s){
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

vec3 rotate3d(vec3 p, vec3 a) {
    vec3 rv;
    float c;
    float s;
    c = cos(a.x);
    s = sin(a.x);
    rv.x = p.x;
    rv.y = p.y*c+p.z*s;
    rv.z = -p.y*s+p.z*c;
    c = cos(a.y);
    s = sin(a.y);
    p.x = rv.x*c+rv.z*s;
    p.y = rv.y;
    p.z = -rv.x*s+rv.z*c;
    c = cos(a.z);
    s = sin(a.z);
    rv.x = p.x*c+p.y*s;
    rv.y = -p.x*s+p.y*c;
    rv.z = p.z;
    return rv;
}
const float PI=3.14159265359;

vec2 equirectangularMap(vec3 dir) {
    vec2 longlat = vec2(atan(dir.y,dir.x),acos(dir.z));
     return longlat/vec2(2.0*PI,PI);
}

//Simple HDRI START

//Hash without Sine Dave_Hoskins
//https://www.shadertoy.com/view/4djSRW 
float Simple360HDR_hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float Simple360HDR_noise(vec2 v){
  vec2 v1=floor(v);
  vec2 v2=smoothstep(0.0,1.0,fract(v));
  float n00=Simple360HDR_hash12(v1);
  float n01=Simple360HDR_hash12(v1+vec2(0,1));
  float n10=Simple360HDR_hash12(v1+vec2(1,0));
  float n11=Simple360HDR_hash12(v1+vec2(1,1));
  return mix(mix(n00,n01,v2.y),mix(n10,n11,v2.y),v2.x);
}

float Simple360HDR_noiseOct(vec2 p){
  return
    Simple360HDR_noise(p)*0.5+
    Simple360HDR_noise(p*2.0+13.0)*0.25+
    Simple360HDR_noise(p*4.0+23.0)*0.15+
    Simple360HDR_noise(p*8.0+33.0)*0.10+
    Simple360HDR_noise(p*16.0+43.0)*0.05;
}

vec3 Simple360HDR_skyColor(vec3 p){
    vec3 s1=vec3(0.2,0.5,1.0);
    vec3 s2=vec3(0.1,0.2,0.4)*1.5;
    vec3 v=(Simple360HDR_noiseOct(p.xz*0.1)-0.5)*vec3(1.0);
    float d=length(p);
    return mix(s2+v,s1+v*(12.0/max(d,20.0)),clamp(d*0.1,0.0,1.0));
}

vec3 Simple360HDR_floorColor(vec3 p){
    vec3 v=(Simple360HDR_noiseOct(p.xz*0.1)*0.5+0.25)*vec3(0.7,0.5,0.4);
    return v;
}

vec3 Simple360HDR_renderHDR360(vec3 rd, vec3 sun){
    vec3 col;
    vec3 p;
    vec3 c;
    if (rd.y>0.0) {
        p=rd*(5.0/rd.y);
        c=Simple360HDR_skyColor(p);
    } else {
        p=rd*(-10.0/rd.y);
        c=Simple360HDR_floorColor(p);
        c=mix(c,vec3(0.5,0.7,1.0),clamp(1.0-sqrt(-rd.y)*3.0,0.0,1.0));
    }
    vec3 skycolor=vec3(0.1,0.45,0.68);
    float d=length(p);
    
    float ds=clamp(dot(sun,rd),0.0,1.0);
    vec3 sunc=(ds>0.9997?vec3(2.0):vec3(0.0))+pow(ds,512.0)*4.0+pow(ds,128.0)*vec3(0.5)+pow(ds,4.0)*vec3(0.5);
    if (rd.y>0.0){
        c+=vec3(0.3)*pow(1.0-abs(rd.y),3.0)*0.7;
    } 
    return c+sunc;
}

vec3 Simple360HDR_make360hdri(vec2 p, vec3 sun){
    float xPI=3.14159265359;
    vec2 thetaphi = ((p * 2.0) - vec2(1.0)) * vec2(xPI,xPI/2.0); 
    vec3 rayDirection = vec3(cos(thetaphi.y) * cos(thetaphi.x), sin(thetaphi.y), cos(thetaphi.y) * sin(thetaphi.x));
    return Simple360HDR_renderHDR360(rayDirection,sun);
}
//Simple HDRI END

const float p_o349467_CamY = 2.152000000;
const float p_o349467_LookAtX = 0.000000000;
const float p_o349467_LookAtY = 0.635000000;
const float p_o349467_LookAtZ = 0.000000000;
const float p_o349467_CamD = 1.825000000;
const float p_o349467_CamZoom = 1.516000000;
const float p_o349467_Reflection = 0.200000000;
const float p_o349467_Specular = 0.000000000;
const float p_o349467_Pow = 64.000000000;
const float p_o349467_SunX = 2.500000000;
const float p_o349467_SunY = 2.500000000;
const float p_o349467_SunZ = 1.000000000;
const float p_o349467_AmbLight = 0.250000000;
const float p_o349467_AmbOcclusion = 0.502000000;
const float p_o349467_Shadow = 1.000000000;
const float p_o538946_s = 0.610000000;
const float p_o528578_x = 0.000000000;
const float p_o528578_y = 1.030000000;
const float p_o528578_z = 0.000000000;
const float p_o492884_r = 2.514000000;
const float p_o492884_x = 0.024000000;

float o360551_input_obj3d(vec3 p) {
    float o492884_0_1_sdf3d = iq_sdOctahedron((p),p_o492884_r)-p_o492884_x;
    return o492884_0_1_sdf3d;
}

const float p_o391263_smooth = 0.000000000;
const float p_o373061_x = 1.000000000;
const float p_o373061_y = 1.000000000;
const float p_o373061_z = 1.000000000;
const float p_o382957_xyz = 0.452000000;
const float p_o382957_x = 1.000000000;
const float p_o382957_y = 1.000000000;
const float p_o382957_z = 1.000000000;

vec4 o360551_input_trans3d(vec4 p) {
    vec4 o370386_0_1_v4v4 = (vec4(rotate3d((vec4((vec4((vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).xyz-vec3(p_o373061_x, p_o373061_y, p_o373061_z),(vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).w)).xyz/vec3(p_o382957_x, p_o382957_y, p_o382957_z)/p_o382957_xyz,(vec4((vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).xyz-vec3(p_o373061_x, p_o373061_y, p_o373061_z),(vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).w)).w)).xyz, -vec3((sin(time*0.05)*360.0), (sin(time*0.07)*360.0), (sin(time*0.03)*360.0))*0.01745329251), (vec4((vec4((vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).xyz-vec3(p_o373061_x, p_o373061_y, p_o373061_z),(vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).w)).xyz/vec3(p_o382957_x, p_o382957_y, p_o382957_z)/p_o382957_xyz,(vec4((vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).xyz-vec3(p_o373061_x, p_o373061_y, p_o373061_z),(vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).w)).w)).w));
    vec4 o371615_0_1_v4v4 = o370386_0_1_v4v4;
    vec4 o_o382957_0=o371615_0_1_v4v4;vec4 o382957_0_1_v4v4 = vec4(o_o382957_0.xyz,(vec4((vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).xyz-vec3(p_o373061_x, p_o373061_y, p_o373061_z),(vec4(vec3(sqrt((p).xyz*(p).xyz+p_o391263_smooth)),(p).w)).w)).w/min(min(p_o382957_x, p_o382957_y), p_o382957_z)/p_o382957_xyz);
    vec4 o373061_0_1_v4v4 = o382957_0_1_v4v4;
    vec4 o391263_0_1_v4v4 = o373061_0_1_v4v4;
    return o391263_0_1_v4v4;
}

float for_min_o360551(vec4 p) {
  float d=o360551_input_obj3d(p.xyz);
  float m=min(999999.0,d);
  for(int i=0;i<6;i++){
    p=o360551_input_trans3d(p);
    d=o360551_input_obj3d(p.xyz);
    m=min(m,d/p.w);
  }
  return m;
}

float o349467_input_sdf_a(vec3 p) {
    float o360551_0_1_sdf3d = for_min_o360551(vec4((rotate3d(((((p))/p_o538946_s)-vec3(p_o528578_x, p_o528578_y, p_o528578_z)), -vec3((time*21.0), (time*27.0), (time*23.0))*0.01745329251)),1.0));
    vec2 o512498_0_1_sdf3dc = vec2(o360551_0_1_sdf3d, 0.0);
    vec2 o528578_0_1_sdf3dc = o512498_0_1_sdf3dc;
    vec2 o538946_0_in = o528578_0_1_sdf3dc;vec2 o538946_0_1_sdf3dc = vec2(o538946_0_in.x*p_o538946_s, o538946_0_in.y);
    return (o538946_0_1_sdf3dc).x;
    }

vec3 o349467_input_tex3d_a(vec4 p) {
    return vec3(1.0,0.1,0.1);
}

float o349467_input_sdf_b(vec3 p) {
    return max((p).y+1.0,length(vec3((p).x,(p).y+1.0,(p).z))-10.0);
}

vec3 o349467_input_tex3d_b(vec4 p) {
    return vec3(mod(floor((p).x*2.0)+floor((p).z*2.0),2.0))*0.9+0.1;
}

vec3 o349467_input_hdri(vec2 uv) {
    return Simple360HDR_make360hdri(vec2((uv).x,-(uv).y+1.0),normalize(vec3(-p_o349467_SunX,p_o349467_SunY,-p_o349467_SunZ)));
}

vec2 input_o349467(vec3 p) {
    float sdfa=o349467_input_sdf_a(p);
    float sdfb=o349467_input_sdf_b(p);
    if (sdfa<sdfb) {
      return vec2(sdfa,0.0);
    } else {
      return vec2(sdfb,1.0);
    }
}

//tetrahedron normal by PauloFalcao
//https://www.shadertoy.com/view/XstGDS
vec3 normal_o349467(vec3 p){  
  const vec3 e=vec3(0.001,-0.001,0.0);
  float v1=input_o349467(p+e.xyy).x;
  float v2=input_o349467(p+e.yyx).x;
  float v3=input_o349467(p+e.yxy).x;
  float v4=input_o349467(p+e.xxx).x;
  return normalize(vec3(v4+v1-v3-v2,v3+v4-v1-v2,v2+v4-v3-v1));
}

void march_o349467(inout float d,inout vec3 p,inout vec2 dS, vec3 ro, vec3 rd){
    for (int i=0; i < 500; i++) {
        p = ro + rd*d;
        dS = input_o349467(p);
        d += dS.x;
        if (d > 50.0 || abs(dS.x) < 0.0001) break;
    }
}

//from https://www.shadertoy.com/view/lsKcDD
float calcAO_o349467( in vec3 pos, in vec3 nor ){
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ ){
        float h = 0.001 + 0.25*float(i)/4.0;
        float d = input_o349467( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.98;
    }
    return clamp( 1.0 - 1.6*occ, 0.0, 1.0 );    
}

//from https://www.shadertoy.com/view/lsKcDD
float calcSoftshadow_o349467( in vec3 ro, in vec3 rd, in float mint, in float tmax){
    float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    for( int i=0; i<32; i++ ){
        float h = input_o349467( ro + rd*t ).x;
        res = min( res, 10.0*h/t );
        t += h;
        if( res<0.0001 || t>tmax ) break;  
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 raymarch_o349467(vec2 uv) {
    uv-=0.5;
    vec3 cam=vec3((sin(sin(time*0.2)*0.5+0.5)*4.0),p_o349467_CamY,(sin(sin(time*0.3)*0.5+0.5)*4.0))*p_o349467_CamZoom;
    vec3 lookat=vec3(p_o349467_LookAtX,p_o349467_LookAtY,p_o349467_LookAtZ);
    vec3 ray=normalize(lookat-cam);
    vec3 cX=normalize(cross(vec3(0.0,1.0,0.0),ray));
    vec3 cY=normalize(cross(cX,ray));
    vec3 rd = normalize(ray*p_o349467_CamD+cX*uv.x+cY*uv.y);
    vec3 ro = cam;
    
    float d=0.;
    vec3 p=vec3(0);
    vec2 dS=vec2(0);
    march_o349467(d,p,dS,ro,rd);
    
    vec3 color=vec3(0.0);
    vec3 objColor=(dS.y<0.5)?o349467_input_tex3d_a(vec4(p,1.0)):o349467_input_tex3d_b(vec4(p,1.0));
    vec3 light=normalize(vec3(p_o349467_SunX,p_o349467_SunY,p_o349467_SunZ));
    if (d<50.0) {
        vec3 n=normal_o349467(p);
        float l=clamp(dot(-light,-n),0.0,1.0);
        vec3 ref=normalize(reflect(rd,-n));
        float r=clamp(dot(ref,light),0.0,1.0);
        float cAO=mix(1.0,calcAO_o349467(p,n),p_o349467_AmbOcclusion);
        float shadow=mix(1.0,calcSoftshadow_o349467(p,light,0.05,5.0),p_o349467_Shadow);
        color=min(vec3(max(shadow,p_o349467_AmbLight)),max(l,p_o349467_AmbLight))*max(cAO,p_o349467_AmbLight)*objColor+pow(r,p_o349467_Pow)*p_o349467_Specular;
        //reflection
        d=0.01;
        march_o349467(d,p,dS,p,ref);
        vec3 objColorRef=vec3(0);
        if (d<50.0) {
            objColorRef=(dS.y<0.5)?o349467_input_tex3d_a(vec4(p,1.0)):o349467_input_tex3d_b(vec4(p,1.0));
            n=normal_o349467(p);
            l=clamp(dot(-light,-n),0.0,1.0);
            objColorRef=max(l,p_o349467_AmbLight)*objColorRef;
        } else {
            objColorRef=o349467_input_hdri(equirectangularMap(ref.xzy)).xyz;
        }
        color=mix(color,objColorRef,p_o349467_Reflection);
    } else {
        color=o349467_input_hdri(equirectangularMap(rd.xzy)).xyz;
    }
    return color;
}

void main(void) {
    float minSize = min(resolution.x, resolution.y);
    vec2 UV = vec2(0.0, 1.0) + vec2(1.0, -1.0) * (gl_FragCoord.xy-0.5*(resolution.xy-vec2(minSize)))/minSize;
    vec3 o349467_0_1_rgb = raymarch_o349467((UV));
    glFragColor = vec4(o349467_0_1_rgb, 1.0);
}
