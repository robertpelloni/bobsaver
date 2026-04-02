#version 420

// original https://www.shadertoy.com/view/Md3GR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by sebastien durand - 2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

// Lightening, essentially based on one of incredible TekF shaders:
// https://www.shadertoy.com/view/lslXRj

// Pupils effect came from lexicobol shader:
// https://www.shadertoy.com/view/XsjXz1

//-----------------------------------------------------

// #define MOUSE

vec3 lightPos;
mat2 ma, mb, mc, rotEye, rotHeadZ, rotHead;
 
const vec3 pos_noze = vec3(0,-.28+.04,.47+.08);
const vec3 pos_eye = vec3(.14,-.14,.29);
const float size_eye = .09;

// Isosurface Renderer
const int traceLimit=40;
const float traceSize=.005;

// consts
const float tau = 6.2831853;
const float phi = 1.61803398875;

// globals
vec3 envBrightness = vec3(.5,.6,.9);//.7,.6,1.);  // couleur d'ambiance generale

// For optim... not use for the moment as it is 60 fpt here  :)
bool withHead;

// -----------------------------------------------------------------

float hash( float n ) { return fract(sin(n)*43758.5453123); }

float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = vec2(0.0,0.0); //texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;

    return mix( rg.x, rg.y, f.z );
}

// HSV to RGB conversion 
// [iq: https://www.shadertoy.com/view/MsS3Wc]
vec3 hsv2rgb_smooth(float x, float y, float z) {
    vec3 rgb = clamp( abs(mod(x*6.+vec3(0.,4.,2.),6.)-3.)-1., 0., 1.);
    rgb = rgb*rgb*(3.-2.*rgb); // cubic smoothing    
    return z * mix( vec3(1), rgb, y);
}

float distance(vec3 ro, vec3 rd, vec3 p) {
    return length(cross(p-ro,rd));
}

bool intersectSphere(in vec3 ro, in vec3 rd, in vec3 c, in float r, out float t0, out float t1) {
    ro -= c;
    float b = dot(rd,ro), d = b*b - dot(ro,ro) + r*r;
    if (d<0.) return false;
    float sd = sqrt(d);
    t0 = max(0., -b - sd);
    t1 = -b + sd;
    return (t1 > 0.);
}

float udRoundBox(in vec3 p,in vec3 b, in float r )
{
  return length(max(abs(p)-b,0.0))-r ;
}

float udRoundBox2(in vec3 p,in vec3 b, in float r )
{
  return length(max(abs(p)-b,0.0))-r; // + .5*dot(p,p);
}

float sdCapsule(in vec3 p, in vec3 a, in vec3 b, in float r0, in float r1 ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1.);
    return length( pa - ba*h ) - mix(r0,r1,h);
}

// capsule with bump in the middle -> use for arms and legs
vec2 sdCapsule2(in vec3 p,in vec3 a,in vec3 b, in float r0,in float r1,in float bump) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    float dd = bump*sin(3.14*h);  // Little adaptation
    return vec2(length(pa - ba*h) - mix(r0,r1,h)*(1.+dd), 1.); 
}

float sdCylinder( vec3 p, vec3 c) {
  return length(p.yz-c.xy)-c.z;
}

float smin(in float a, in float b, in float k ) {
    float h = clamp( .5+.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.-h);
}

float smax(in float a, in float b, in float k) {
    return log(exp(a/k)+exp(b/k))*k;
}

float SmoothMax( float a, float b, float smoothing ) {
    return a-sqrt(smoothing*smoothing + pow(max(.0,a-b),2.0));
}

float sdEllipsoid( in vec3 p, in vec3 r) {
    return (length(p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float d_ear(in vec3 p, in float scale_ear) {
    vec3 p_ear = scale_ear*p;

    p_ear.xy *= ma;
    p_ear.xz *= ma; 
    float d_ear = max(-sdEllipsoid(p_ear-vec3(.005,.025,.02), vec3(.07,.11,.07)), 
                       sdEllipsoid(p_ear, vec3(.08,.12,.09)));
    p_ear.yz *= mb; 
    d_ear = max(p_ear.z, d_ear); 
    d_ear = smin(d_ear, sdEllipsoid(p_ear+vec3(.035,.045,.01), vec3(.04,.04,.018)), .01);
    return d_ear/scale_ear;
}

float skinPart(vec3 pgeneral, vec3 p) {
    
    float d_cou = sdCapsule2(pgeneral, vec3(0,-.24,-.11), vec3(0,-.7,-.12), .22, .12, -.45).x;
    
    
   // p.zy *= rotEye;
    
    float d = 1000.;
    
    d = sdEllipsoid(p-vec3(0,.05,.0), vec3(.39,.48,.46));
    d = smin(d, sdEllipsoid(p-vec3(0.,.1,-.15), vec3(.42,.4,.4)),.1);
        
    d = smin(d, udRoundBox(p-vec3(0,-.28,.2), vec3(.07,.05,.05),.05),.4); // machoire

   // d = min(d, udRoundBox(p- vec3(0,-1.22,-.12), vec3(.25,.5,.0), .13)); // epaules

    d = smin(d, d_cou, .05);  // cou

    p.x = abs(p.x);

// correction crane ------------------------     
    // plat du front   
 //   vec3 p_plane = p;
  //  p_plane.yz *= ma;
  //  d = smax(d, p_plane.z-.68, .11);  

  //  d = smax(d, -(length(p- vec3(1.3,.3,.33))-.88), .09);  // cote
    //d = smax(d, -(length(p- vec3(.12,-.16,.44)))+.1, .05); // eye
    d = smax(d, -sdEllipsoid(p-vec3(.12,-.16,.48), vec3(.09,.06,.09)), .07); // eye

// ----------------------------------------- 
// nez precis
    d = smin(d, max(-(length(p-vec3(.032,-.325,.45))-.028),     // trou du nez
                    smin(length(p-vec3(.043,-.29,.434))-.01,  // narines
                    sdCapsule(p, vec3(0,-.13,.39), vec3(0,-.28,.47), .01,.04), .05))// arrete
            ,.065); 
            
// -----------------------------------------    
    d = smin(d, length(p- vec3(.22,-.34,.08)), .17); // machoire
    d = smin(d, sdCapsule(p, vec3(.16,-.35,.2), vec3(-.16,-.35,.2), .06,.06), .15); // joues
    
    d = smin(d, max(-length(p.xz-vec2(0,.427))+.015,  // barre sous le nez
                max(-p.y-.41,   // delimitation levre supperieure
                    sdEllipsoid(p- vec3(0,-.34,.37), vec3(.08,.15,.05)))), // avcancement bouche
             .032);   // bouche
             
    d = smin(d, length(p- vec3(0,-.5,.26)), .2);   // menton
    d = smin(d, length(p- vec3(0,-.44,.15)), .25); // dessous 
  
    //d = smin(d, sdCapsule(p, vec3(.24,-.1,.33), vec3(.08,-.05,.46), .0,.01), .11); // sourcil 
    
    // paupieres
    vec3 p_eye1 = p - pos_eye;
    p_eye1.xz *= mb;
    
    vec3 p_eye2 = p_eye1;
    float d_eye = length(p_eye1) - size_eye;
          
    p_eye1.yz *= rotEye;
    p_eye2.zy *= mc;
    
    float d1 = min(max(-p_eye1.y,d_eye - .01),
                   max(p_eye2.y,d_eye - .005));
    d = smin(d,d1,.01);

    // oreilles
    d = smin(d, d_ear(vec3(p.x-.4,p.y+.22,p.z), .9), .01);    
    return d; //max(p.y+cos(time),d);
}

float dEye(vec3 p_eye) {
    p_eye.xz *= ma;     
    return length(p_eye) - size_eye;
}

vec2 min2(in vec2 dc1, in vec2 dc2) {
    return dc1.x < dc2.x ? dc1 : dc2; 
}

vec2 toge(vec3 p) {
    p -= vec3(0.,0.,-.02);
    
    float d_skin = udRoundBox(p- vec3(0,-1.22,-.12), vec3(.25,.5,.0), .13); // epaules
    
    // echarpe
    float d1 = udRoundBox2(p - vec3(-.05, -1.02,-.1), vec3(.15, .25, .0), .22);
    float r = length(p-vec3(1.,0,-.1))-1.25;
    d1 = max(d1, -r);
    d1 = max(d1+.007*sin(r*42.+.6), (length(p-vec3(1.,.1,-.1))-1.62)); 
    
    // habit
    float d = .004*smoothstep(.0,.45, -p.x)*cos(r*150.)+udRoundBox2(p - vec3(-.05, -1.,-.1), vec3(.15, .23, .0), .2);
    
    return min2(vec2(d_skin,2.), min2(vec2(d,0.), vec2(d1, 1.)));
}

vec3 headRotCenter = vec3(0,-.2,-.07);
float DistanceField( vec3 p) {
    float d = toge(p).x;
    
    vec3 p0 = p;
    p -= headRotCenter;
    p.yz *= rotHeadZ;
    p.xz *= rotHead;
    p += headRotCenter;
    
    d = min(d, skinPart(p0,p));
    p.x = abs(p.x);
    d = min(d, dEye(p- pos_eye));
    return d;
}

// render for color extraction
float colorField(vec3 p) {
    vec2 dc = toge(p);
    vec3 p0 = p;
    p -= headRotCenter;
    p.yz *= rotHeadZ;
    p.xz *= rotHead;
    p += headRotCenter;

    dc = min2(dc, vec2(skinPart(p0,p), 2.));
         
    p.x = abs(p.x);
    return min2(dc, vec2(dEye(p - pos_eye), 3.)).y;
}

vec3 Sky( vec3 ray) {
    return envBrightness*mix( vec3(.8), vec3(0), exp2(-(1.0/max(ray.y,.01))*vec3(.4,.6,1.0)) );
}

// -------------------------------------------------------------------
// pupils effect came from lexicobol shader:
// https://www.shadertoy.com/view/XsjXz1
// -------------------------------------------------------------------

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)), 
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*43758.5453);
}

float iqnoise( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
        
    float k = 1.0+63.0*pow(1.0-v,4.0);
    
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec3 o = hash3( p + g )*vec3(u,u,1.0);
        vec2 r = g - f + o.xy;
        float d = dot(r,r);
        float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
        va += o.z*ww;
        wt += ww;
    }
    
    return va/wt;
}

float noise ( vec2 x)
{
    return iqnoise(x, 0.0, 1.0);
}

mat2 m = mat2( 0.8, 0.6, -0.6, 0.8);

float fbm( vec2 p)
{
    float f = 0.0;
    f += 0.5000 * noise(p); p *= m* 2.02;
    f += 0.2500 * noise(p); p *= m* 2.03;
    f += 0.1250 * noise(p); p *= m* 2.01;
    f += 0.0625 * noise(p); p *= m* 2.04;
    f /= 0.9375;
    return f;
}

vec3 iris(vec2 p, float open)
{
    float background = 1.0;// smoothstep(-0.25, 0.25, p.x);
    
    float r = sqrt( dot (p,p));
    float r_pupil = .15 + .15*smoothstep(.5,2.,open);

    float a = atan(p.y, p.x); // + 0.01*time;
    vec3 col = vec3(1.0);
    
    float ss = 0.5 + 0.5 * sin(time * 2.0);
    float anim = 1.0 + 0.05*ss* clamp(1.0-r, 0.0, 1.0);
    r *= anim;
        
    if( r< .8) {
        col = vec3(0.12, 0.60, 0.57);
        float f = fbm(5.0 * p);
        col = mix(col, vec3(0.12,0.52, 0.60), f); // iris bluish green mix
        
        f = 1.0 - smoothstep( r_pupil, r_pupil+.2, r);
        col = mix(col, vec3(0.60,0.44,0.12), f); //yellow
        
        a += 0.05 * fbm(20.0*p);
        
        f = smoothstep(0.3, 1.0, fbm(vec2(5.0 * r, 20.0 * a))); // white highlight
        col = mix(col, vec3(1.0), f);
        
        f = smoothstep(0.3, 1.0, fbm(vec2(5.0 * r, 5.0 * a))); // yellow highlight
        col = mix(col, vec3(0.60,0.44,0.12), f);
        
        f = smoothstep(0.5, 1.0, fbm(vec2(5.0 * r, 15.0 * a))); // dark highlight
        col *= 1.0 - f;
        
        f = smoothstep(0.55, 0.8, r); //dark at edge
        col *= 1.0 - 0.6*f;
        
        f = smoothstep( r_pupil, r_pupil + .05, r); //pupil
        col *= f; 
        
        f = smoothstep(0.75, 0.8, r);
        col = mix(col, vec3(1.0), f);
    }
    
    return col * background;
}

// -------------------------------------------------------------------

vec3 Shade( vec3 pos, vec3 ray, vec3 normal, vec3 lightDir1, vec3 lightDir2, vec3 lightCol1, vec3 lightCol2, float shadowMask1, float shadowMask2, float distance )
{
    
    float colorId = colorField(pos);
    
    vec3 ambient = envBrightness*mix( vec3(.2,.27,.4), vec3(.4), (-normal.y*.5+.5) ); // ambient
    
    // ambient occlusion, based on my DF Lighting: https://www.shadertoy.com/view/XdBGW3
    float aoRange = distance/20.0;
    
    float occlusion = max( 0.0, 1.0 - DistanceField( pos + normal*aoRange )/aoRange ); // can be > 1.0
    occlusion = exp2( -2.0*pow(occlusion,2.0) ); // tweak the curve
    
    ambient *= occlusion*.8+.2; // reduce occlusion to imply indirect sub surface scattering

    float ndotl1 = max(.0,dot(normal,lightDir1));
    float ndotl2 = max(.0,dot(normal,lightDir2));
    float lightCut1 = smoothstep(.0,.1,ndotl1);
    float lightCut2 = smoothstep(.0,.1,ndotl2);

    vec3 light = vec3(0);
    

    light += lightCol1*shadowMask1*ndotl1;
    light += lightCol2*shadowMask2*ndotl2;

    
    // And sub surface scattering too! Because, why not?
    float transmissionRange = distance/10.0; // this really should be constant... right?
    float transmission1 = DistanceField( pos + lightDir1*transmissionRange )/transmissionRange;
    float transmission2 = DistanceField( pos + lightDir2*transmissionRange )/transmissionRange;
    vec3 sslight = lightCol1 * smoothstep(0.0,1.0,transmission1) + lightCol2 * smoothstep(0.0,1.0,transmission2);
    vec3 subsurface = vec3(1,.8,.5) * sslight;

    vec3 p = pos;
    p -= headRotCenter;
    p.yz *= rotHeadZ;
    p.xz *= rotHead;
    p += headRotCenter;

    vec3 albedo;
    if (colorId < .5) {  
        // Toge 1
        albedo = vec3(1.,.6,0.);
    } else if (colorId < 1.5) {  
        // Toge 2
        albedo = vec3(.6,.3,0.);
    } else if (colorId < 2.5) {
         // Skin color
        albedo = vec3(.6,.43,.3); 
        float v = 1.;
        if (p.z>0.) {
            v = smoothstep(.02,.03, length(p.xy-vec2(0,-.03)));
        }
        albedo = mix(vec3(.5,0,0), albedo, v);
         
    } else {
        // Eye
        if (p.z>0.) {
            vec3 pos_eyeloc = pos_eye;
            pos_eyeloc.x *= sign(p.x);
            vec3 pe = p - pos_eyeloc;
 
            // Light point in face coordinates
            vec3 lightPos2 = lightPos - headRotCenter;
            lightPos2.yz *= rotHeadZ;
            lightPos2.xz *= rotHead;
            lightPos2 += headRotCenter;

            vec3 dir = normalize(lightPos2-pos_eyeloc);
            
            float a = clamp(atan(-dir.x, dir.z), -.6,.6), 
                  ca = cos(a), sa = sin(a);
            pe.xz *= mat2(ca, sa, -sa, ca);

            float b = clamp(atan(-dir.y, dir.z), -.3,.3), 
                  cb = cos(b), sb = sin(b);
            pe.yz *= mat2(cb, sb, -sb, cb);
            
            albedo = (pe.z>0.) ? iris(17.*(pe.xy), length(lightPos2-pos_eyeloc)) : vec3(1);
        }
     }
    
    // Draw face
    
    float specularity = .2; 
    vec3 h1 = normalize(lightDir1-ray);
    vec3 h2 = normalize(lightDir2-ray);
    
    float specPower;
    specPower = exp2(3.0+5.0*specularity);

    if (colorId < 1.5) {  
        // Toge
        specPower = sqrt(specPower);
    } else if (colorId < 2.5) {
    } else {
        specPower *= specPower;
    }
  
    vec3 specular1 = lightCol1*shadowMask1*pow(max(.0,dot(normal,h1))*lightCut1, specPower)*specPower/32.0;
    vec3 specular2 = lightCol2*shadowMask2*pow(max(.0,dot(normal,h2))*lightCut2, specPower)*specPower/32.0;
    
    
    vec3 rray = reflect(ray,normal);
    vec3 reflection = Sky( rray );
    
    // specular occlusion, adjust the divisor for the gradient we expect
    float specOcclusion = max( 0.0, 1.0 - DistanceField( pos + rray*aoRange )/(aoRange*max(.01,dot(rray,normal))) ); // can be > 1.0
    specOcclusion = exp2( -2.0*pow(specOcclusion,2.0) ); // tweak the curve
    
    // prevent sparkles in heavily occluded areas
    specOcclusion *= occlusion;

    reflection *= specOcclusion; // could fire an additional ray for more accurate results
    
    float fresnel = pow( 1.0+dot(normal,ray), 5.0 );
    fresnel = mix( mix( .0, .01, specularity ), mix( .4, 1.0, specularity ), fresnel );

    light += ambient;
    light += subsurface;

    vec3 result = light*albedo;
    result = mix( result, reflection, fresnel );
    result += specular1;
    result += specular2;

    return result;
}

float Trace( vec3 pos, vec3 ray, float traceStart, float traceEnd )
{
    float t0=0.,t1=100.;
//    if (intersectSphere(pos, ray, vec3(0,-.015,.011), .6, t0, t1)) { 
        float t = max(traceStart, t0);
        traceEnd = min(traceEnd, t1);
        float h;
        for( int i=0; i < traceLimit; i++) {
            h = DistanceField( pos+t*ray );
            if (h < traceSize || t > traceEnd)
                return t>traceEnd?100.:t; //break;
            t = t+h;
        }
  //  }
    
    return 100.0;
}

float TraceMin( vec3 pos, vec3 ray, float traceStart, float traceEnd )
{
    float Min = traceEnd;
    float t = traceStart;
    float h;
    for( int i=0; i < traceLimit; i++ )
    {
        h = DistanceField( pos+t*ray);
        Min = min(h,Min);
        if ( /*h < .001 ||*/ t > traceEnd )
            break;
        t = t+max(h,.1);
    }
    
    return Min;
}

vec3 Normal( vec3 pos, vec3 ray, float t )
{
    // in theory we should be able to get a good gradient using just 4 points
    float pitch = .2 * t / resolution.x;
#ifdef FAST
    // don't sample smaller than the interpolation errors in Noise()
    pitch = max( pitch, .005 );
#endif
    
    vec2 d = vec2(-1,1) * pitch;

    vec3 p0 = pos+d.xxx; // tetrahedral offsets
    vec3 p1 = pos+d.xyy;
    vec3 p2 = pos+d.yxy;
    vec3 p3 = pos+d.yyx;
    
    float f0 = DistanceField(p0);
    float f1 = DistanceField(p1);
    float f2 = DistanceField(p2);
    float f3 = DistanceField(p3);
    
    vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
    //return normalize(grad);
    // prevent normals pointing away from camera (caused by precision errors)
    return normalize(grad - max(.0,dot (grad,ray ))*ray);
}

// Camera

vec3 Ray( float zoom, in vec2 fc) {
    return vec3( fc.xy-resolution.xy*.5, resolution.x*zoom );
}

vec3 Rotate( inout vec3 v, vec2 a ) {
    vec4 cs = vec4( cos(a.x), sin(a.x), cos(a.y), sin(a.y) );
    
    v.yz = v.yz*cs.x+v.zy*cs.y*vec2(-1,1);
    v.xz = v.xz*cs.z+v.zx*cs.w*vec2(1,-1);
    
    vec3 p;
    p.xz = vec2( -cs.w, -cs.z )*cs.x;
    p.y = cs.y;
    
    return p;
}

// Camera Effects

void BarrelDistortion( inout vec3 ray, float degree )
{
    // would love to get some disperson on this, but that means more rays
    ray.z /= degree;
    ray.z = ( ray.z*ray.z - dot(ray.xy,ray.xy) ); // fisheye
    ray.z = degree*sqrt(ray.z);
}

vec3 LensFlare( vec3 ray, vec3 lightCol, vec3 light, float lightVisible, float sky, vec2 fc )
{
    vec2 dirtuv = fc.xy/resolution.x;
    float dirt = 1.;//1.0-texture2D( iChannel1, dirtuv ).r;
    float l = (dot(light,ray)*.5+.5);
    
    return (
            ((pow(l,30.0)+.05)*dirt*.1
            + 1.0*pow(l,200.0))*lightVisible + sky*1.0*pow(l,5000.0)
           )*lightCol
           + 5.0*pow(smoothstep(.9999,1.0,l),20.0) * smoothstep(.5,1.0,lightVisible) * normalize(lightCol);
}

mat2 matRot(in float a) {
    float ca = cos(a), sa = sin(a);
    return mat2(ca,sa,-sa,ca);
}

const float
    a_eyeClose = .55, 
    a_eyeOpen = -.3;

const float 
    t_apear = 5.,
    t_noze = t_apear+8., 
    t_openEye = t_noze + 2.,
    t_rotHead = t_openEye + 4.,
    t_rotDown = t_rotHead + 3.,
    t_outNoze = t_rotDown + 3.,
    t_night = t_outNoze + 4.,
    t_colorfull = t_night + 5.,
    t_disapear = t_colorfull + 2.,
    t_closeEye = t_disapear + 3.;

void main(void)
{
    float time = mod(time+61., 63.);
    
// constantes
    ma = matRot(-.5);
    mb = matRot(-.15);
    mc = matRot(-.6);

// clignement des yeux

    float a_PaupieresCligne =  mix(hash(floor(time*10.))>.95?fract(time*20.):0.,a_eyeOpen,a_eyeClose);    
    float a_Paupieres = mix(a_eyeClose, .2, smoothstep(t_openEye, t_openEye+3., time));    
    a_Paupieres = mix(a_Paupieres, a_PaupieresCligne, smoothstep(t_rotDown, t_rotDown+1., time));
    a_Paupieres = mix(a_Paupieres, a_eyeClose, smoothstep(t_closeEye, t_closeEye+3., time));

    rotEye = matRot(a_Paupieres);

// rotation de la tete 
    float a_headRot = 0.1, a_headRotH = 0.1;
    
    a_headRot = mix(0., .2*cos(30.*(time-t_rotHead)), smoothstep(t_rotHead, t_rotHead+.5, time)-smoothstep(t_rotHead+1.3, t_rotHead+3., time));
    a_headRotH = mix(-.1, .2*cos(30.*(time-t_rotHead)), smoothstep(t_rotHead+1.5, t_rotHead+2., time)-smoothstep(t_rotHead+2., t_rotHead+3., time));
    a_headRotH = mix(a_headRotH, .3, smoothstep(t_rotHead+2., t_rotDown, time));
    a_headRotH = mix(a_headRotH, -.2, smoothstep(t_outNoze, t_outNoze+2., time));
    a_headRotH = mix(a_headRotH, -.1, smoothstep(t_closeEye, t_closeEye+3., time));
    
    rotHead = matRot(a_headRot); 
    rotHeadZ = matRot(a_headRotH); 
    mat2 rotHead2 = matRot(-a_headRot); 
    mat2 rotHeadH2 = matRot(-a_headRotH); 

// Position du nez    
    vec3 p_noze = pos_noze - headRotCenter;
    p_noze.xz *= rotHead2;
    p_noze.yz *= rotHeadH2;
    p_noze += headRotCenter;

// Positon du point lumineux
    float distLightRot = mix(1., .4, smoothstep(3.,t_noze-2., time));
    vec3 centerLightRot = /*mix(vec3(0),*/ vec3(0,.2/*pos_eye.y*/,1.7); //, smoothstep(t_noze-2.,t_noze, time));
                              
    float lt = 3.*(time-1.); //-5.);
    vec3 lightRot = centerLightRot + distLightRot*vec3(cos(lt*.5), .025*sin(2.*lt), sin(lt*.5));
    
    lightPos = mix(lightRot, p_noze, smoothstep(t_noze, t_noze + 1., time));
    lightPos = mix(lightPos, lightRot, smoothstep(t_outNoze,t_outNoze+2., time));

// intensitee et couleur du point
    float lightAppear = smoothstep(t_apear, t_apear+2., time)-smoothstep(t_disapear, t_disapear+3., time);

    vec3 lightCol2 = hsv2rgb_smooth(.6*(floor(time/63.))+.4,1.,.5);
    
    // Ambiant color
    envBrightness = mix(vec3(.5,.6,.9), vec3(.02,.03,.05), smoothstep(t_night, t_night+3., time));
    envBrightness = mix(envBrightness, lightCol2, smoothstep(t_colorfull, t_colorfull+1., time));
    envBrightness = mix(envBrightness, vec3(.5,.6,.9), smoothstep(t_disapear+5., t_disapear+9., time));
    
    vec3 ray = Ray(2.0,gl_FragCoord.xy);
    
    BarrelDistortion(ray, .5 );
    
    ray = normalize(ray);
    vec3 localRay = ray;
    vec2 mouse = vec2(0);
#ifdef MOUSE
    if ( mouse*resolution.xy.z > 0.0 )
        mouse = .5-mouse*resolution.xy.yx/resolution.yx;
    vec3 pos = 6.*Rotate(ray, vec2(-.1,1.+time*.1)+vec2(-1.0,-3.3)*mouse );        
#else    
    vec3 pos = vec3(0,0,.6) + 6.*Rotate(ray, vec2(-.1,1.+time*.1));        
#endif    
    vec3 col;

    vec3 lightDir1 = normalize(vec3(.5,1.5,1.5)); //cos(lt),1.,sin(lt)));
    vec3 lightCol1 = vec3(1.1,1.,.9)*.7*envBrightness;
    
    float lightRange2 = .4; // distance of intensity = 1.0
    
    float traceStart = 0.;
    float traceEnd = 40.0;
    
    float t = Trace( pos, ray, traceStart, traceEnd );
    if ( t < 10.0 )
    {
        vec3 p = pos + ray*t;
        
        // shadow test
        vec3 lightDir2 = lightPos-p;
        float lightIntensity2 = length(lightDir2);
        lightDir2 /= lightIntensity2;
        lightIntensity2 = lightAppear*lightRange2/(.1+lightIntensity2*lightIntensity2);
        
        float s1 = 0.0;
        s1 = Trace( p, lightDir1, .05, 4.0 );
        float s2 = 0.0;
        s2 = Trace( p, lightDir2, .05, 4.0 );
        
        vec3 n = Normal(p, ray, t);
        col = Shade(p, ray, n, lightDir1, lightDir2,
                    lightCol1, lightCol2*lightIntensity2,
                    (s1<10.0)?0.0:1.0, (s2<10.0)?0.0:1.0, t );
        
        // fog
        float f = 200.0;
        col = mix( vec3(.8), col, exp2(-t*vec3(.4,.6,1.0)/f) );
    }
    else
    {
        col = Sky( ray );
    }
    
    // draw light

    float s1 = max(distance(pos, ray, lightPos)+.03,0.);
    float dist = length(lightPos-pos);
    if (dist < t) {
        lightCol2 *= 2.5*exp( -.01*dist*dist );
        float BloomFalloff = 15000.; //mix(1000.,5000., Anim);
        col = col *(1.-lightAppear) + lightAppear*mix(lightCol2, col, smoothstep(.037,.047, s1));
        col += lightAppear*lightCol2*lightCol2/(1.+s1*s1*s1*BloomFalloff);
    }

// Post traitments -----------------------------------------------------    
    // vignetting:
    col *= smoothstep(.5, .0, dot(localRay.xy,localRay.xy) );

    // compress bright colours, ( because bloom vanishes in vignette )
    vec3 c = (col-1.0);
    c = sqrt(c*c+.05); // soft abs
    col = mix(col,1.0-c,.48); // .5 = never saturate, .0 = linear
    
    // compress bright colours
    float l = max(col.x,max(col.y,col.z));//dot(col,normalize(vec3(2,4,1)));
    l = max(l,.01); // prevent div by zero, darker colours will have no curve
    float l2 = SmoothMax(l,1.0,.01);
    col *= l2/l;
    
    glFragColor =  vec4(pow(col,vec3(1.0/2.2)),1);
}
