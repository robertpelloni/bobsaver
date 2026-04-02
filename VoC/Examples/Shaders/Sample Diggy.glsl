#version 420

// original https://www.shadertoy.com/view/MtyGz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time * 0.5
#define lampLightIntensity abs(2.0*sin(time*5.0))

const float PI=3.14159265;
const float PIH = PI*0.5;
const int MAX_ITER = 50;
const float EPSILON = 0.00001;
vec3 lightDir = normalize(vec3(0, 1, 0.75)); 
float lightIntensity=0.5;

float bgMatType = 0.0;
float PlaneMatType = 1.0;
float BodyMatType = 2.0;
float DressMatType = 3.0;
float LampMatType = 4.0;
float EyesMatType = 5.0;
float TeethMatType = 6.0;

vec3 skyColor = vec3(1.0,1.0,1.0);
vec3 ambientLight=vec3(0.0,0.0,0.0);
vec3 planeColor = vec3(1.0,1.0,1.0);
vec3 bodyColor = vec3(0.89,0.74,0.15);
vec3 dressColor = vec3(0.83,0.52,0.05);
vec3 lampColor = vec3(0.63,0.99,0.99);
vec3 eyesColor = vec3(0);
vec3 teethColor = vec3(1.0,1.0,1.0);

vec3 lampLightColor = vec3(0.63,0.99,0.99);
vec3 lampPos = vec3(0.0, 0.8, 0.15);
float lampLightAtt = 1.5;

//#define SELF_SHADOW
#define CHEAP_AO

// Thanks iq! https://www.shadertoy.com/view/ld3Gz2
// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 ) 
{
    float a =     det(b0,b2);
    float b = 2.0*det(b1,b0);
    float d = 2.0*det(b2,b1);
    float f = b*d - a*a;
    vec2  d21 = b2-b1;
    vec2  d10 = b1-b0;
    vec2  d20 = b2-b0;
    vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
    vec2  pp = -f*gf/dot(gf,gf);
    vec2  d0p = b0-pp;
    float ap = det(d0p,d20);
    float bp = 2.0*det(d10,d0p);
    float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
    return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}

vec4 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p )
{
    vec3 w = normalize( cross( c-b, a-b ) );
    vec3 u = normalize( c-b );
    vec3 v = normalize( cross( w, u ) );

    vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
    vec2 b2 = vec2( 0.0 );
    vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
    vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

    vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

    return vec4( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z, length(cp.xy), p3.z );
}

//---------------------------------------------
vec3 rotationCoordY(vec3 n, float t)
{
 vec3 result;

   vec2 sc = vec2(sin(t), cos(t));
   mat3 rotate;

      rotate = mat3( sc.y,  0.0, -sc.x,
                     0.0,   1.0,  0.0,
                     sc.x,  0.0, sc.y);   

  result = n * rotate;
  return result;
}

//---------------------------------------------
vec3 rotationCoordX(vec3 n, float t)
{
 vec3 result;

   vec2 sc = vec2(sin(t), cos(t));
   mat3 rotate;

      rotate = mat3( 1.0,  0.0,  0.0,
                     0.0,  sc.y, -sc.x,
                     0.0, sc.x, sc.y);   

  result = n * rotate;
  return result;
}

//------------------------------------------
float sdPlaneY( vec3 p )
{
    return p.y;
}

//----------------------------------------------------
float sdSphere(vec3 p, float r)
{
   return length(p) - r;
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------
vec3 InstantiateRotY(vec3 p, float inPiFrac)
{
    float rad        = mod(atan(p.x, p.z) +  PIH*inPiFrac, PI*inPiFrac) - PIH*inPiFrac;
    p.xz            = vec2(sin(rad), cos(rad)) * length(p.xz);
    return p;
}

//---------------------------------------------
float dSegment(vec3 pa, vec3 ba, float r)
{
    return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0))-r;
}

//--------------------------------------------------
float smin( float a, float b, float k ) 
{
   float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
   return mix( b, a, h ) - k*h*(1.0-h);
}

//---------------------------------------------
vec2 minDistMat(vec2 curDist, vec2 dist)
{
       if (dist.x < curDist.x) 
       {
        return dist;
       }
       return curDist;
}

//---------------------------------------------
float body(in vec3 p) {
    float d = sdSphere(p*vec3(0.85,1.0,1.2), 0.2);
    d = smin(d, sdSphere(p*vec3(0.95,1.0,1.2)+vec3(0,-0.22,0), 0.05), 0.22);
    d = smin(d, sdSphere(p*vec3(0.75,1.5,0.7)+vec3(0,0.15,0), 0.1), 0.3);
    return d;
}

//---------------------------------------------
vec2 diggy(in vec3 p, bool includeLamp) {
    // body
    vec2 d = vec2(body(p), DressMatType);
    float dSmall = body((p+vec3(0.0,-0.05,-0.15))/0.8)*0.8;
    d.x=max(-dSmall,d.x);
    
    // Lamp neck
    vec3 lampDispl = vec3(0.0,0.4, 0.2);
    vec4 b = sdBezier( vec3(0.0, 0.2, 0.0), vec3(0.0,0.7, 0.0), lampDispl, p);
    d.x = smin(d.x, b.x - (0.04 - 0.02*b.y), 0.1);
    
    // legs
    vec3 symYPos = p;
       symYPos.x = abs(symYPos.x);  
    d.x = smin(d.x, sdSphere(symYPos * vec3(1.4, 0.7, 1.4) + vec3(-0.25, 0.2, 0.05), 0.1), 0.22); 
    
    //d=200.0;
    // arms
    vec3 armsPos = symYPos + vec3(-0.26, -0.15, 0.0);
    b = sdBezier( vec3(0.05, 0.1, 0.0), vec3(0.01, 0.0, 0.0), vec3(-0.05, -0.1, 0.0), armsPos);
    d.x = smin(d.x, b.x - (0.1*sqrt(b.y)), 0.01);
    
    // eyes
    vec3 eyesPos = symYPos + vec3(-0.08, -0.08, -0.135);
    b = sdBezier( vec3(0.05, 0.0, -0.02), vec3(0.0, 0.06, -0.01), vec3(-0.05, 0.0, 0.01), eyesPos);
    d = minDistMat(d, vec2(b.x - 0.01, EyesMatType)); 
    
    // Lamp
    if(includeLamp) {
        d = minDistMat(d, vec2(sdSphere(p-lampDispl, 0.05), LampMatType));
    }
    
    // Body inside dress
    d = minDistMat(d, vec2(body(p/0.95)*0.95, BodyMatType));
    
    // Mouth
    vec3 mouthPos = p + vec3(0.0, 0.06, -0.165);
    mouthPos = rotationCoordX(mouthPos, -0.6);
    float dMouth = udRoundBox(mouthPos, vec3(0.15, 0.08, 0.05), 0.01);
    dMouth = max(sdSphere(p*vec3(0.6, 0.93, 0.85) + vec3(0.0, 0.02, -0.1), 0.1), dMouth);
    d = max(d, -dMouth);
    
    
    // Teeth
    vec3 teethPos = symYPos + vec3(-0.036, -0.01, -0.17);
    teethPos = rotationCoordX(teethPos, 0.47);
    teethPos = rotationCoordY(teethPos, 0.12);
    d = minDistMat(d, vec2(udRoundBox(teethPos, 
                                      vec3(0.02+0.008*smoothstep(-0.035, 0.035, teethPos.y), 0.035, 0.005), 0.01), TeethMatType));
    
    return d;
    
}

//--------------------------------------------------
vec2 map(in vec3 p, bool includeLamp)
{
       vec3 pos = p;
        
       vec2 d = vec2(1.0, bgMatType);
    
    d = minDistMat(d, diggy(pos + vec3(0.0, -0.4, 0.0), includeLamp));
    
    // Planes
    d = minDistMat(d, vec2(sdPlaneY(pos), PlaneMatType));
        
    return d; 
}

//------------------------------------------------- 
vec3 getNormal(in vec3 p)
{

   vec3 e = vec3( EPSILON, 0., 0. );
   vec3 nor = vec3(
       map(p+e.xyy, true).x - map(p-e.xyy, true).x,
       map(p+e.yxy, true).x - map(p-e.yxy, true).x,
       map(p+e.yyx, true).x - map(p-e.yyx, true).x);
   return normalize(nor);  

}

//------------------------------------------
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<10; i++ )
    {        
        float h = map( ro + rd*t, false ).x;
        res = min( res, 10.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<EPSILON || t>tmax ) break;
    }
    return clamp(res, 0.0, 1.0 );
}

//------------------------------------------
float calcAO( in vec3 pos, in vec3 nor )
{
#ifdef CHEAP_AO
    return mix(0.5, 1.0, clamp((nor.y + 1.0) * 0.5, 0.0, 1.0)); 
#else
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<10; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( pos, false ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 0.5*occ, 0.0, 1.0 );   
#endif
}

//------------------------------------------
vec3 illum(in vec3 pos, in vec3 rd ,in vec3 nor, in vec3 lig, in vec3 col, in float t, in float mat, in vec3 add)
{
    // lighitng 
    vec3 ref = reflect( rd, nor );
    float occ = calcAO( pos, nor );  
    
    vec3 pointLigDir = lampPos-pos;
    float distToPointLig = length(pointLigDir);
    pointLigDir /= distToPointLig;
    
    float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
    float dif = clamp( dot( nor, lig ), 0.0, 1.0 )*lightIntensity;
    float difPoint = clamp( dot( nor, pointLigDir ), 0.0, 1.0 );
    float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
    float dom = smoothstep( -0.1, 0.1, ref.y );
    float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
    float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),1.0);
    
    float pointLightInt = clamp(lampLightIntensity-distToPointLig*lampLightAtt,0.0, lampLightIntensity);
    difPoint *= pointLightInt;
        
#ifndef SELF_SHADOW
    if(mat == PlaneMatType) 
    {
#endif
        dif *= softshadow( pos, lig, 0.1, 10.0 );
        difPoint *= softshadow( pos, pointLigDir, 0.1, 10.0 );
#ifndef SELF_SHADOW
    }
#endif
    
    vec3 brdf = vec3(0.0);
    brdf += dif*vec3(1,1,1)+difPoint*lampLightColor;
    brdf += 0.5*(spe*vec3(1,1,1)*dif+spe*difPoint*lampLightColor);
    brdf += 0.30*amb*ambientLight*occ;
    brdf += 0.10*dom*ambientLight*occ;
    brdf += 1.0*bac*vec3(0.25,0.25,0.25)*occ;
       brdf += clamp(lightIntensity+pointLightInt*0.2,0.0,1.0)*fre*vec3(1.00,1.00,1.00)*occ;
    brdf += 0.02;
    col = col*brdf;
    
    return col + add;
}
//----------------------------------------------------------------------
vec3 getColor(inout vec3 ro, vec3 rd, vec2 t)
{
      vec3 color = skyColor; 
 
       float mat =  t.y;
       if (mat > 0.0) 
       {
        vec3 hitPos = ro + rd * t.x;
          vec3 normal = vec3(1,0,0);
        vec3 add = vec3(0);
        
        if(mat == PlaneMatType)
        {
            normal = vec3(0,1,0);
        }
        else if(mat > PlaneMatType)
        {
            normal = normalize(getNormal(hitPos)); 
            add = vec3(smoothstep(0.6, 0.8, 1.0 - max(dot(-rd, normal), 0.0))); 
        }
        
           if (mat == BodyMatType) 
           {
            color = bodyColor;
           }
        else if(mat == DressMatType)
        {
            color = dressColor;
        }
        else if(mat == LampMatType)
        {
            float intensity = smoothstep(0.0, 2.0, lampLightIntensity);
            float diff = max(clamp(intensity, 0.2, 1.0), dot(normal, lightDir));
            float back = max(clamp(intensity, 0.2, 1.0), dot(normal, -lightDir));
            float spec = pow(clamp(dot(lightDir, reflect(rd, normal)), 0.0, 1.0), 32.0);
            
            vec3 mate = lampLightColor * 0.9;
            color = (diff + 0.5 * back) * mate + spec * vec3(1.0);
        }
        else if (mat == PlaneMatType) 
           {
            color = planeColor;
           }
        else if (mat == EyesMatType)
        {
            color = eyesColor;
        }
        else if (mat == TeethMatType)
        {
            color = teethColor;
        }
        
        if(mat != LampMatType) {
            float distToLamp = length(hitPos-lampPos);
        
            color = illum(hitPos, rd, normal, lightDir, color.rgb, t.x, mat, add);                   
        }
    }
   
      return color;
}

//-------------------------------------------------
vec2 render(in vec3 posOnRay, in vec3 rayDir)
{ 
    vec2 t = vec2(0.0, bgMatType);
    float maxDist = 25.0;
    for(int i=0; i<MAX_ITER; ++i)
    {
        vec2 d = map(posOnRay + t.x*rayDir, true); 
        if (abs(d.x) < EPSILON || t.x > maxDist) 
            break;
        t.x += d.x;
        t.y = d.y;
    }
    return t;
}
//------------------------------------------
void main(void)
{
    vec2 pos     =  gl_FragCoord.xy / resolution.xy * 2. - 1.;
    pos.x *= resolution.x / resolution.y;  
       
    vec3 camP = rotationCoordY(vec3(0., 0.3, 1.5), time);
    vec3 camUp = vec3(0. , 1., 0.);
    vec3 camDir = normalize(vec3(0.0, 0.3, 0.0)-camP);
    vec3 u = normalize(cross(camUp,camDir));
    vec3 v = cross(camDir,u);
    vec3 rayDir = normalize(2. * camDir + pos.x * u + pos.y * v);  
        
    vec2 t =  render(camP, rayDir);  
    vec3 color = getColor(camP, rayDir, t); 
    
    // gamma
    color = pow( clamp( color, 0.0, 1.0 ), vec3(0.45) );
    
    // vignetting
    pos*=0.35;
    float distSqr = dot(pos, pos);
    float vignette = 1.0 - distSqr;
    color *=  vignette;
    
    glFragColor = vec4(color, 1.0);

}
