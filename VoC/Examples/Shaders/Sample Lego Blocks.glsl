#version 420

// original https://www.shadertoy.com/view/Mc3cRn

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Danil (2024+) https://github.com/danilw
// https://mastodon.gamedev.place/@danil
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// self https://www.shadertoy.com/view/Mc3cRn

// if you look for templates - look
// https://danilw.github.io/blog/my_shader_templates_list/

// CONTROL:
// Mouse x (click)- left middle right - 3 views
// Mouse y - shift for view

// Ultra-wide screen fix - define this - or/and edit second clamp value in that define
//#define FIX_FOV_UW

//-------------------------

// using
// https://iquilezles.org/articles/distfunctions/
// https://mercury.sexy/hg_sdf
// palette from iq https://www.shadertoy.com/view/ll2GD3
// sdf repetition fix by blackle https://www.shadertoy.com/view/WtXcWB

//-------------------------

// angle loop fix
#define ANGLE_loop (min(frames,0))
//#define ANGLE_loop 0

#define MIN_DIST 0.000001
#define MAX_DIST 1000.

#define MAX_MARCHING_STEPS 256
// set epsilon_step bigger for smaller number of step
// for 64 is 0.01, for 256 is 0.001, 512 0.0001
#define epsilon_step 0.0001

#define MAX_SHADOW_STEPS 64
#define MAX_REFL_STEPS 64

//-------------------------

#define OBJ_SKIP -1
#define OBJ_SKY 0
#define OBJ_CUBE 10
#define OBJ_CT0 250100
#define OBJ_CT1 501000
#define OBJ_CT2 1100000

//-------------------------

#define PI 3.14159265
#define TAU (2.*PI)

const vec3 lightDir = normalize(vec3(1.5, .65, 1.50));
// ggx only
const float sunIluminance = 1.25;
const vec3 ggx_light2_dir = normalize(vec3(-0.2662, -0.8589, 0.4376));
const vec3 sky_topCol = vec3(0.51, 0.534, 1.0);
const vec3 bottomCol = vec3(1.);

//-------------------------

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b + r;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 pMod2(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

vec3 get_maid(int tid);
vec2 map( in vec3 pos)
{
    vec2 res = vec2( MAX_DIST, float(OBJ_SKY));
    {
        vec2 tp = pos.xz;
        vec2 tidt = pMod2(tp, vec2(1.));
        int tid = int(tidt.x)*500+int(tidt.y);
        
        const float rad = 0.0525;
        const vec3 box = vec3(0.5)-0.0003;
        
        
        // sdf repetition fix by blackle https://www.shadertoy.com/view/WtXcWB
        // needed only when boxed have different height, and when camera outside
        {
            res = opU( res, vec2(sdBox( vec3(tp.x-1.,pos.y,tp.y+0.), box*0.795 ),float(OBJ_SKIP)));
            //res = opU( res, vec2(sdBox( vec3(tp.x+1.,pos.y,tp.y+0.), box*0.95 ),float(OBJ_SKIP)));
            res = opU( res, vec2(sdBox( vec3(tp.x+0.,pos.y,tp.y-1.), box*0.795+vec3(1.,0.,0.)),float(OBJ_SKIP)));
            //res = opU( res, vec2(sdBox( vec3(tp.x+0.,pos.y,tp.y+1.), box*0.95 ),float(OBJ_SKIP)));
        }
        
        if(tidt.x<0.||tidt.y<0.||tidt.x>500.||tidt.y>500.){return res;}
        vec3 tpa = get_maid(tid);
        
        res = opU( res, vec2(sdRoundBox( vec3(tp.x-tpa.y,pos.y,tp.y-tpa.z), box+vec3(tpa.x,0.,1.), rad ),float(OBJ_CUBE+tid)));
        res = opU( res, vec2(sdRoundedCylinder( vec3(tp.x,pos.y-.5,tp.y), 0.25*0.5, 0.051, 0.15 ),float(OBJ_CT0+tid)));
    }
    
    return res;
}

// map_n to fix - line on normal
// https://danilw.github.io/GLSL-howto/vulkan_sh_launcher/Mc3cRn_norm.png
vec2 map_nbox( in vec3 pos)
{
    vec2 res = vec2( MAX_DIST, float(OBJ_SKY));
    
    {
        vec2 tp = pos.xz;
        vec2 tidt = pMod2(tp, vec2(1.));
        int tid = int(tidt.x)*500+int(tidt.y);
        const float rad = 0.0525;
        const vec3 box = vec3(0.5)-0.0003;
        
        if(tidt.x<0.||tidt.y<0.||tidt.x>500.||tidt.y>500.){return res;}
        vec3 tpa = get_maid(tid);
        
        res = opU( res, vec2(sdRoundBox( vec3(tp.x-tpa.y,pos.y,tp.y-tpa.z), box+vec3(tpa.x,0.,1.), rad ),float(OBJ_CUBE+tid)));
        //res = opU( res, vec2(sdRoundedCylinder( vec3(tp.x,pos.y-.5,tp.y), 0.25*0.5, 0.051, 0.15 ),float(OBJ_CT0+tid)));
    }
    
    return res;
}
vec2 map_ncyl( in vec3 pos)
{
    vec2 res = vec2( MAX_DIST, float(OBJ_SKY));
    
    {
        vec2 tp = pos.xz;
        vec2 tidt = pMod2(tp, vec2(1.));
        
        int tid = int(tidt.x)*500+int(tidt.y);
        
        const float rad = 0.0525;
        const vec3 box = vec3(0.5)-0.0003;
        
        if(tidt.x<0.||tidt.y<0.||tidt.x>500.||tidt.y>500.){return res;}
        vec3 tpa = get_maid(tid);
        
        //res = opU( res, vec2(sdRoundBox( vec3(tp.x-tpa.y,pos.y,tp.y-tpa.z), box+vec3(tpa.x,0.,1.), rad ),float(OBJ_CUBE+tid)));
        res = opU( res, vec2(sdRoundedCylinder( vec3(tp.x,pos.y-.5,tp.y), 0.25*0.5, 0.051, 0.15 ),float(OBJ_CT0+tid)));
    }
    
    return res;
}

// 10-cube variations 0-9
// https://danilw.github.io/GLSL-howto/vulkan_sh_launcher/X32fzK_tid.jpg
// 1xxxxxxx
uint [12] maidx1 = uint[12](
10610661u,
12732773u,
10101061u,
12345273u,
10145061u,
12323273u,
10106101u,
12327323u,
10610661u,
12732773u,
18066101u,
19277323u
);

uint [12] maidx2 = uint[12](
18018061u,
19239273u,
10101018u,
14523239u,
14501801u,
12323923u,
10610661u,
12732773u,
10106101u,
12327323u,
10101018u,
12323239u
);

// color index
uint[6] idti1 = uint[6](
1112222u,
3344555u,
6644777u,
8899900u,
1112222u,
3444455u
);

uint[6] idti2 = uint[6](
1223444u,
5566778u,
5577900u,
1112222u,
3344455u,
6677889u
);

// color index shift at (where 0)
ivec2 ti1 = ivec2(4,2);
ivec2 ti2 = ivec2(4,1);

float hash11(float p);
float get_maiddpal(int tid){
    ivec2 tidp = ivec2(tid/500, tid%500);
    int tidg = (tidp/ivec2(7,12)).x+(tidp/ivec2(7,12)).y*50;
    tidp = tidp%ivec2(7,12);
    float et = .0;
    if((tidg%2)==0){if(!((tidp.y/2==ti1.y&&tidp.x>ti1.x)||tidp.y/2>ti1.y))et = 0.35;}
    else{if(!((tidp.y/2==ti2.y&&tidp.x>ti2.x)||tidp.y/2>ti2.y))et = 0.35;}
    uint ma = 0u;
    if((tidg%2)==0)ma=idti1[5-tidp.y/2];
    else ma=idti2[5-tidp.y/2];
    const uint[10] upw = uint[10](1u, 10u, 100u, 1000u, 10000u, 100000u, 1000000u, 10000000u, 100000000u, 1000000000u);
    uint mda = upw[6-tidp.x];
    int idx = int(ma/mda)%10;
    //return float(idx)/7.;
    return float(tidg)*.3+(hash11(float(tidg)*0.53+0.3)*1.2+0.2)*float(idx)/7.+et;
}

vec3 get_maid(int tid){
    ivec2 tidp = ivec2(tid/500, tid%500);
    int tidg = (tidp/ivec2(7,12)).x+(tidp/ivec2(7,12)).y*50;
    tidp = tidp%ivec2(7,12);
    uint ma = 0u;
    if((tidg%2)==0)ma=maidx1[11-tidp.y];
    else ma=maidx2[11-tidp.y];
    const uint[10] upw = uint[10](1u, 10u, 100u, 1000u, 10000u, 100000u, 1000000u, 10000000u, 100000000u, 1000000000u);
    uint mda = upw[6-tidp.x];
    int idx = int(ma/mda)%10;
    return vec3(float(idx<8),float(idx<6)*float(1-2*(idx%2)),float(idx<4)*float(2*(idx/2)-1)+float(idx>5)*float(2*(idx%2)-1));
}

//-------------------------

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 get_pal(float d){
    d = fract(d);
    vec3 col = pal( d, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    //col.b += col.g*col.b;
    return normalize(col*col+0.001)*0.75+0.25*col*col;
}

vec3 color_by_object_id(int obj_id){
    if(obj_id>=OBJ_CUBE&&obj_id<OBJ_CUBE+500*500)obj_id=obj_id-OBJ_CUBE;
    if(obj_id>=OBJ_CT0)obj_id=obj_id-(obj_id>OBJ_CT0+500*500?(obj_id>OBJ_CT1+500*500?OBJ_CT2:OBJ_CT1):OBJ_CT0);
    vec3 albedo = get_pal(get_maiddpal(obj_id)*1.33);
    return albedo;
}

//-------------------------

vec2 raycast( in vec3 ro, in vec3 rd){
    vec2 res = vec2( MAX_DIST, float(OBJ_SKY));

    float tmin = MIN_DIST;
    float tmax = MAX_DIST;
    
    //call boxAABB here to save performance

    float t = tmin;
    for( int i=ANGLE_loop; i<MAX_MARCHING_STEPS && t<tmax; i++ )
    {
        vec2 h = map( ro+rd*t);
        if( abs(h.x)<(epsilon_step*t) )
        { 
            res = vec2(t,h.y); 
            break;
        }
        t += h.x;
    }
    
    return res;
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax)
{

    float res = 1.0;
    float t = mint;
    for( int i=ANGLE_loop; i<MAX_SHADOW_STEPS; i++ )
    {
        float h = map(ro + rd*t).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s );
        t += clamp( h, 0.01, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

float calcSoftshadow_reflect( in vec3 ro, in vec3 rd, in float mint, in float tmax)
{

    float res = 1.0;
    float t = mint;
    for( int i=ANGLE_loop; i<MAX_REFL_STEPS; i++ )
    {
        float h = map(ro + rd*t).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s );
        t += clamp( h, 0.01, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

// https://iquilezles.org/articles/normalsSDF

// map_n to fix - line on normal
// https://danilw.github.io/GLSL-howto/vulkan_sh_launcher/X32fzK_tid.jpg
vec3 calcNormal( in vec3 pos, int obj_id)
{

    vec2 e = vec2(1.0,-1.0)*0.00025;
    /*
        return normalize( e.xyy*map( pos + e.xyy).x + 
                      e.yyx*map( pos + e.yyx).x + 
                      e.yxy*map( pos + e.yxy).x + 
                      e.xxx*map( pos + e.xxx).x ); 
    */
    if(obj_id>=OBJ_CUBE&&obj_id<OBJ_CUBE+500*500){
        return normalize( e.xyy*map_nbox( pos + e.xyy).x + 
                      e.yyx*map_nbox( pos + e.yyx).x + 
                      e.yxy*map_nbox( pos + e.yxy).x + 
                      e.xxx*map_nbox( pos + e.xxx).x );  
    }
    if(obj_id>=OBJ_CT0){
        return normalize( e.xyy*map_ncyl( pos + e.xyy).x + 
                      e.yyx*map_ncyl( pos + e.yyx).x + 
                      e.yxy*map_ncyl( pos + e.yxy).x + 
                      e.xxx*map_ncyl( pos + e.xxx).x );  
    }
    
    return normalize(pos);
}

// https://iquilezles.org/articles/nvscene2008/rwwtt.pdf
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ANGLE_loop; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map(pos + h*nor).x;
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 applyFog(in vec3  rgb, in vec3 skyColor, in float dist) {
    float startDist = MAX_DIST/1.75-2.;
    float fogAmount = 2.0 * (1.0 - exp(-(dist-startDist) * (1.0/startDist)));
    return mix(rgb, skyColor, clamp(fogAmount, 0.0, 1.0));
}

vec3 calculateSunColor(float sunZenith);
float ggx(vec3 N, vec3 V, vec3 L, float roughness);
vec3 get_sky_color(vec3 rd, float sunIlum, float sun_power);
vec3 render( in vec3 ro, in vec3 rd)
{ 
    // sky
    vec3 sky_col = get_sky_color(rd, sunIluminance, 1.);
    //vec3 col = sky_col;
    vec3 col = vec3(0.);
    
    // raycast scene
    vec2 res = raycast(ro, rd);
    float t = res.x;
    int mid = int(res.y);
    

    if( mid>OBJ_SKY )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos, mid);

        float mat_s=0.05;

        vec3 ref = reflect( rd, nor );
        
        // material        
        col = color_by_object_id(mid);
        
        float ks = 1.;

        // lighting
        float occ = calcAO( pos, nor );
        
        vec3 lin = vec3(0.0);

        float lamb1 = clamp((dot(nor, lightDir))*(1./PI), 0.0, 1.0);
        float lamb2 = clamp((dot(nor, ggx_light2_dir))*(1./PI), 0.0, 1.0);
        vec3 sunColor = calculateSunColor(lightDir.y);
        vec3 sunColor2 = calculateSunColor(ggx_light2_dir.y);

        float reflect_sh = 1.;
        reflect_sh=calcSoftshadow_reflect( pos, ref, 0.02, 4.5 );
        float shadow = 1.;
        shadow = calcSoftshadow( pos, lightDir, 0.02, 20.5 );
        float ao = smoothstep(0., 4., occ);
        
        float diffuse = lamb1;
        diffuse *= shadow;
        vec3 result = mix(vec3(0.), sunColor, diffuse);

        diffuse += lamb2*ao;
        result += mix(vec3(0.), sunColor2, lamb2*ao);
        
        const float material_shininess = 0.543;
        mat_s+=material_shininess;

        const float material_intensity = 0.15;
        const float AMB_STRENGTH = .63;
        
        diffuse += ao*AMB_STRENGTH;
        
        vec3 AMB_COL = vec3(0.3);
        float tmat_s=1.-(mat_s+0.5);
        const float mix_material_skyref = 0.5;
        AMB_COL+=mix(sky_topCol,mix_material_skyref*sky_topCol,tmat_s);
        result += mix(vec3(0), AMB_COL, ao*AMB_STRENGTH);
        vec3 albedo = col;
        result*= albedo;
        
        float spec = ggx(nor, -rd, lightDir, mat_s);
        float specular = spec*material_intensity;
        
        result = mix(result*0.75+result*reflect_sh*0.25, result+sunColor, specular*shadow);
        
        lin = result;

        col = lin;
        //col = applyFog(col, sky_col, t);

    }
    return vec3(col);
}

//-------------------------

mat2 MD(float a){float s = sin( a );float c = cos( a );return mat2(vec2(c, -s), vec2(s, c));}
void SetCamera(vec2 uv, out vec3 ro, out vec3 rd)
{
    float camf = 1.;//-clamp(mouse*resolution.xy.y/resolution.y,0.,1.);
    float came = 1.;//-clamp(mouse*resolution.xy.x/resolution.x,0.,1.);
    vec2 c3 = vec2(.5,5.*camf);
    vec2 c1 = vec2(1.,1.*camf);
    vec2 c2 = vec2(0.,.5);
    
    int mid=3;//int(3.*abs(mouse*resolution.xy.z)/resolution.x);
    if(mid==0){camf=c1.x;came=c1.y;}
    if(mid==1){camf=c2.x;came=c3.y;}
    if(mid==2){camf=c3.x;came=c3.y;}
    
    ro = vec3(250.,2.5+10.*came*0.5+55.*(1.-smoothstep(0.,1.,sqrt(camf))),250.);
    ro.xz+=vec2(150.,0.)*MD(time*(1./75.)*(3.14159265*2.)*0.1);
    
    vec2 m = (mouse*resolution.xy.xy/resolution.xy-0.5)*3.14159265*vec2(2.,1.);
    m=vec2(0.,-0.5*3.1415926);
    vec2 sm = m;
    sm.x = atan(-fract((1./75.)*time*0.1))*4.*2.;
    sm.y = sm.y+camf*0.82;
    m = sm;
    
    m.y = -m.y;
#ifdef FIX_FOV_UW
    float fov=clamp(20.+60.*camf,20.,65.);
    if(mid==2)fov=clamp(120.-80.*camf,20.,65.);
#else
    float fov=clamp(20.+60.*camf,20.,80.);
    if(mid==2)fov=clamp(120.-80.*camf,20.,120.);
#endif
    float aspect = resolution.x / resolution.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    rd = vec3(uv*screenSize, 1./aspect);
    
    // cylindrical perspective https://www.shadertoy.com/view/ftffWN
      float a = rd.x/rd.z;
      rd.xz = rd.z * vec2(sin(a),cos(a));
    
    rd = normalize(rd);
    mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
    mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));

    
      const float maxFocalLength = 1.97;
      float focalLength = maxFocalLength;
      vec3 camForward = vec3(0., 0., 1.);
      rd = normalize(rd+camForward * focalLength);

    rd = (rotY * rotX) * rd;
}
//-------------------------

vec3 ACESFilm(vec3 x){
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}
vec3 srgb_encode (vec3 v) {
  return mix(12.92*v,1.055*pow(v,vec3(.41666))-.055,step(.0031308,v));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    uv.y *= resolution.y/resolution.x;
    
    vec3 ro; vec3 rd;
    SetCamera(uv, ro, rd);
    vec3 color = render( ro, rd );
    
    color = ACESFilm(color);
    color = srgb_encode(color);

    color = pow( color, vec3(0.4545) );
    glFragColor = vec4( color, 1.0 );
}

// sky
//----------------------------------------------

const float sunAngularDiameter = 2.5;

const float goldenAngle = 2.3999632297286533;

// sky from https://www.shadertoy.com/view/3dlSW7

float hGPhase(float cosTheta, const float g){
    float g2 = g * g;
    
    return 0.25 * (1.0 - g2) * pow(g2 - 2.0 * g * cosTheta + 1.0, -1.5);
}

vec3 calculateSunColor(float sunZenith){
    return mix(vec3(1.0, 0.4, 0.05), vec3(1.0), max(sunZenith, 0.0));
}

float calculateSun(float lDotV, float sunIlum){
    const float cosRad = cos(radians(sunAngularDiameter));
    float sunLuminance = sunIlum / ((1.0 - cosRad) * TAU);
    
    return smoothstep(cosRad,cosRad*1.001, lDotV) * sunLuminance;
}

vec3 calculateSky(vec3 background, float lDotU, float lDotV, float sunIlum){
    float phaseMie = hGPhase(lDotV, 0.8);
    
    float zenith = max(lDotU, 0.0);
    
    float sunZenith = lightDir.y;
    
    vec3 sky = mix(sky_topCol, (bottomCol + sky_topCol), exp2(-zenith * 8.0));
         sky += phaseMie * exp2(-zenith * 6.0);
    
    vec3 absorbColor = calculateSunColor(1.0 - exp2(-zenith * 2.0));
    
    sky = sky * mix(absorbColor * 0.9 + 0.1, vec3(1.0), sunZenith);
    return background * absorbColor + sky * sunIlum * (1.0 - clamp(-sunZenith * 10.0, 0.0, 1.0));    
}

vec3 get_sky_color(vec3 rd, float sunIlum, float sun_power){
    float lDotU = dot(rd, vec3(0.,1.,0.));
    float lDotV = dot(rd, lightDir);
    vec3 col = vec3(0.0);
    col += sun_power*calculateSun(lDotV,sunIlum)*calculateSunColor(lightDir.y);
    col = calculateSky(col, lDotU, lDotV,sunIlum);
    return col;
}

//----------------------------------------------

// ggx
//----------------------------------------------
float G(float dotNV, float k){
    return 1.0/(dotNV*(1.0f-k)+k);
}
float ggx(vec3 N, vec3 V, vec3 L, float roughness){
    float F0 = 0.6;
    float alpha = roughness*roughness;

    vec3 H = normalize(V+L);

    float dotNL = clamp(dot(N,L),0.,1.);
    float dotNV = clamp(dot(N,V),0.,1.);
    float dotNH = clamp(dot(N,H),0.,1.);
    float dotLH = clamp(dot(L,H),0.,1.);

    float F, D, vis;

    float alphaSqr = alpha*alpha;
    float pi = 3.14159;
    float denom = dotNH * dotNH *(alphaSqr - 1.0) + 1.0;
    D = alphaSqr/(pi * denom * denom);

    float dotLH5 = pow(1.0 - dotLH, 5.0);
    F = F0 + (1.0 - F0)*(dotLH5);

    float k = alpha * 0.5;

    return dotNL * D * F * G(dotNL,k)*G(dotNV,k);
}

// look https://www.shadertoy.com/view/4fsSRn
// read https://arugl.medium.com/hash-noise-in-gpu-shaders-210188ac3a3e

#define FIX_FRACT_HASH 1000.

#ifdef FIX_FRACT_HASH
float fix_float(float x){return sign(x)*(floor(abs(x))+floor(fract(abs(x))*FIX_FRACT_HASH)/FIX_FRACT_HASH);}
#else
float fix_float(float x){return x;}
#endif

float hash12(vec2 p)
{
#ifdef FIX_FRACT_HASH
    p = sign(p)*(floor(abs(p))+floor(fract(abs(p))*FIX_FRACT_HASH)/FIX_FRACT_HASH);
#endif
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash11(float p)
{
#ifdef FIX_FRACT_HASH
    p = sign(p)*(floor(abs(p))+floor(fract(abs(p))*FIX_FRACT_HASH)/FIX_FRACT_HASH);
#endif
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
