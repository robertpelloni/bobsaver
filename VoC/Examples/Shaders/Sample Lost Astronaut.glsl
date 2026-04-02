#version 420

// original https://www.shadertoy.com/view/Mlfyz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Lost Astronaut"
// by Julien Vergnaud @duvengar 2017

// ====================================================================
// this shader is inspired by iq's "Raymarching - Primitives's",
// https://www.shadertoy.com/view/Xds3zN
// and article,
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// and Shane's "Transparent 3D Noise" ,
// https://www.shadertoy.com/view/lstGRB
// ====================================================================

#define T time
#define PI 3.1416 //

//// COLORS ////
const vec3 ORANGE = vec3(1.0, 0.5, 0.3);
const vec3 GREEN   = vec3(0.0, 1., 0.5);
const vec3 PINK   = vec3(.9, 0.3, 0.4);

//==========================================================//
//                 NOISE 3D
//
// 3D noise and fbm function by Inigo Quilez
//==========================================================//

mat3 m = mat3( .00,  .80,  .60,
              -.80,  .36, -.48,
              -.60, -.48,  .64 );

float hash( float n )
{
    float h =  fract(sin(n) * 4121.15393);

    return  h + .444;   
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f * f * (3.0 - 2.0 * f );

    float n = p.x + p.y * 157.0 + 113.0 * p.z;

    return mix(mix(mix( hash(n + 00.00), hash(n + 1.000), f.x),
                   mix( hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix( hash(n + 113.0), hash(n + 114.0), f.x),
                   mix( hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

float fbm( vec3 p )
{
   float f = 0.0;

   f += 0.5000 * noise( p ); p = m * p * 2.1;
   f += 0.2500 * noise( p ); p = m * p * 2.2;
   f += 0.1250 * noise( p ); p = m * p * 2.3;
   f += 0.0625 * noise( p );
    
   return f/0.9375;
}

//==========================================================
//            signed DISTANCE FIELD PRIMITIVES 
//==========================================================
//
// distance field primitives by Inigo Quilez
// https://www.shadertoy.com/view/Xds3zN
//
//==========================================================
//                        PLANE

float sdPlane( vec3 p ) 
{
    return p.y ;
}

//-----------------------------------------------------------
//                       SPHERE            
//
float sdSphere( vec3 p, float s )
{
  return length(p) - s;
}

//-----------------------------------------------------------
//                     RECTANGLE
//
float sdBox( vec3 p, vec3 b )
{   
  vec3 d = abs(p) - b ;   
  return max(min(d.x, min(d.y, d.z)), .0) + length(max(d, .0));
}

// polynomial smooth min and max ref iq's article
// http://www.iquilezles.org/www/articles/smin/smin.htm

float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * (b - a) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * (1.0 - h);
}

float smax( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * (a - b) / k, 0.0, 1.0 );
    return mix( b, a, h ) + k * h * (1.0 - h);
}

vec3 opRot( vec3 p, float a )
{
    float  c = cos(a);
    float  s = sin(a);
    mat2   m = mat2(c,-s,s,c);   
    return vec3(m*p.xy,p.z);
}

//==========================================================
//          SKULL SIGNED DISTANCE FIELD 
//
//==========================================================

float sdSkull( vec3 p, float s )
{

  // domain deformation on s give interesting results
  // this deformation can be applied to bigger shapes in order to preserve details.
  float ss = noise(p * 9.);
  ss = mix(s,ss *.5,.1);
  // kind of morphing effect
  // s = clamp(cos(time*.5), .15,.35);

  float shape = sdSphere(p - vec3(.0,.05,.0), s * .95 * cos(cos(p.y*11.)* p.z * 2.3) );
    
  // first part external skull top
  // -----------------------------
  // globe front 
  shape = smin(shape,  sdSphere (p - vec3(.10, 0.23, 0.00), s * .82), .09);
  // globe back 
  shape = smin(shape,  sdSphere (p - vec3(-.1, 0.24, 0.00), s * .82), .09);
  // eye brow
  shape = smin(shape,  sdSphere (p - vec3(.24, 0.07, 0.10), s * .36 * cos(p.y * 7.0)), .02);
  shape = smin(shape,  sdSphere (p - vec3(.24, 0.07, -.10), s * .36 * cos(p.y * 7.0)), .02);
  // lateral holes
  shape = smax(shape, -sdSphere (p - vec3(.15, -.01, 0.31), s * .28 * cos(p.x * .59)), .02);
  shape = smax(shape, -sdSphere (p - vec3(.15, -.01, -.31), s * .28 * cos(p.x * .59)), .02);
        
  //checkbones
  vec3 q = p;
  shape = smin(shape, sdSphere(p-vec3(.22,-.13,.18), s*.11),.09);
  shape = smin(shape, sdSphere(p-vec3(.22,-.13,-.18), s*.11),.09);
  
  // empty the skull
  shape = max(shape, -sdSphere(p - vec3(.0,.05,.0), s * .90 * cos(cos(p.y*11.)* p.z * 2.3) ));  
  shape = smax(shape,  -sdSphere (p - vec3(.10, 0.23, 0.00), s * .73),.02);
  shape = smax(shape,  -sdSphere (p - vec3(-.1, 0.24, 0.00), s * .73),.02);
  shape = smax(shape,  -sdSphere (p - vec3(.0, 0.24, 0.00), s * .73),.02);
  
  // eye balls
  shape = smax(shape, -sdSphere(p-vec3(.32,-.04,.140), s  * .28 * cos(p.y*10.)),.03);
  shape = smax(shape, -sdSphere(p-vec3(.32,-.04,-.140), s * .28 * cos(p.y*10.)),.03);
  
  // nose
  // ---------------
  // base nose shape
  float temp = sdSphere(p- vec3(cos(.0)*.220,-.05, sin(.0)*.3), s * .35 * cos(sin(p.y*22.)*p.z*24.));
  // substract the eyes balls & skukl globe
  temp = smax(temp, -sdSphere(p-vec3(.32,-.04,.140), s * .35 * cos(p.y*10.)), .02);
  temp = smax(temp, -sdSphere(p-vec3(.32,-.04,-.140), s * .35 * cos(p.y*10.)),.02); 
  temp = smax(temp, -sdSphere(p - vec3(.0,.05,.0), s * .90 * cos(cos(p.y*11.)* p.z * 2.3) ),.02);
  
  // add nose shape to skull 
  shape = smin(shape,temp,.015);  
  
  // empty the nose
  shape = smax(shape, - sdSphere(p- vec3(cos(.0)*.238,-.09, sin(.0)*.3), s * .3 * cos(sin(p.y*18.)*p.z*29.)),.002);
  
  // substract bottom
  shape = smax(shape, -sdSphere(p- vec3(-.15,-0.97, .0), s * 2.5 ),.01);
  // I like the noise deformation on this edge with ss for the sphere radius.
  // It give a more natural look to the skull.
  shape = smax(shape, -sdSphere(p- vec3(-.23,-0.57, .0), ss * 1.6 ),.01);
    
   
  
  // skull part2: UP jaws
  // ------------------
    
  temp = smax(sdSphere(p - vec3(.13,-.26,.0), .45 * s), -sdSphere(p - vec3(.125,-.3,.0), .40 * s), .01);
  
  // substract back
  temp = smax(temp,-sdSphere(p - vec3(-.2,-.1,.0), .9 * s), .03);
  
  // substract bottom  
  temp = smax(temp,-sdSphere(p - vec3(.13,-.543,.0), .9 * s), .03);
  
  // substract up  
  temp = max(temp, -sdSphere(p - vec3(.0,.02,.0), s * .90 * cos(cos(p.y*11.)* p.z * 2.3) ));  
 
  shape = smin(shape, temp, .04);
    
  // Teeths
  // -------
 
  temp = sdSphere(p - vec3(.26, -.29, .018), .053 * s );
  temp = min(temp, sdSphere(p - vec3(.26, -.29, -.018), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.25, -.29, .05), .05 * s ));
  temp = min(temp, sdSphere(p - vec3(.25, -.29, -.05), .05 * s ));
  temp = min(temp, sdSphere(p - vec3(.235, -.29, .08), .05 * s ));
  temp = min(temp, sdSphere(p - vec3(.235, -.29, -.08), .05 * s ));
  temp = min(temp, sdSphere(p - vec3(.215, -.28, .1), .05 * s ));
  temp = min(temp, sdSphere(p - vec3(.215, -.28, -.1), .05 * s ));
  temp = max(temp, -sdSphere(p - vec3(.16, -.35, .0), .33 * s ));   
  
  temp = min(temp, sdSphere(p - vec3(.18, -.28, .115), .05 * s ));
  temp = min(temp, sdSphere(p - vec3(.18, -.28, -.115), .05 * s )); 
  temp = min(temp, sdSphere(p - vec3(.14, -.28, .115), .06 * s ));
  temp = min(temp, sdSphere(p - vec3(.14, -.28, -.115), .06 * s ));
  temp = min(temp, sdSphere(p - vec3(.11, -.28, .115), .06 * s ));
  temp = min(temp, sdSphere(p - vec3(.11, -.28, -.115), .06 * s )); 
  temp = min(temp, sdSphere(p - vec3(.08, -.28, .115), .06 * s ));
  temp = min(temp, sdSphere(p - vec3(.08, -.28, -.115), .06 * s ));

   
  shape = smin(shape, temp, .03); 
    
  // DOWN Jaws
  // ----
  
  temp = sdSphere(p - vec3(.1,-.32,.0), .43 * s);  
  temp = smax (temp, - sdSphere(p - vec3(.1,-.32,.0), .37 * s ),.02);  
  temp = smax(temp, - sdSphere(p - vec3(.1,-.034,.0), 1.03 * s),.02) ;  
  temp = smax(temp, - sdSphere(p - vec3(.0,-.4,.0), .35 * s),.02);    
  temp = smin(temp, sdBox(p - vec3(.04 -.03 * cos(p.y * 20.2),-.23, .27 + sin(p.y)*.27), vec3(cos(p.y*4.)*.03,.12,.014)), .13);
  temp = smin(temp, sdBox(p - vec3(.04 -.03 * cos(p.y * 20.2),-.23, -.27 -sin(p.y)*.27), vec3(cos(p.y*4.)*.03,.12,.014)), .13);
  
  temp = max(temp, - sdSphere(p - vec3(.0,.153,.2), .85 * s)); 
  temp = max(temp, - sdSphere(p - vec3(.0,.153,-.2), .85 * s)); 
    
  temp = smin (temp, sdSphere(p - vec3(.2, -.45, 0.05), .05 * s ),.07);  
  temp = smin (temp, sdSphere(p - vec3(.2, -.45, -.05), .05 * s ),.07);  
    
  shape = smin(shape, temp, .02);  
    
  // Teeths
  // -------
 
  temp = sdSphere(p - vec3(.23, -.34, .018), .053 * s );
  temp = min(temp, sdSphere(p - vec3(.23, -.34, -.018), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.22, -.34, -.048), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.22, -.34, .048), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.20, -.34, -.078), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.20, -.34, .078), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.17, -.35, -.098), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.17, -.35, .098), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.14, -.35, -.11), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.14, -.35, .11), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.11, -.35, -.11), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.11, -.35, .11), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.08, -.35, -.11), .053 * s));
  temp = min(temp, sdSphere(p - vec3(.08, -.35, .11), .053 * s));
      
 
  shape = smin(shape, temp, .025);  
  shape *= 1.5;
    
  //================ 
  return shape ;
  //================
    

}    

//==========================================================
//               OBJECT POSITION
//
// update objects primitives positions if necessary.
//
//==========================================================

vec3 skullP ()
{     
   return vec3(.0,.0,.0);
}

//==========================================================
//                     OBJECTS UNION
//
//==========================================================

vec2 add(vec2 d1, vec2 d2)
{
  
    return (d1.x < d2.x) ? d1: d2 ;   
}

//==========================================================
//                     SCENE MANAGER  

//==========================================================

vec2 map(vec3 pos)
{
    
    vec2 scene = vec2(.5 * sdSkull(opRot(pos,T*.1) -  skullP()- vec3(.0,.0, .0), .35), 39.);
    return scene;     
}

//==========================================================//
//                     RAY CASTER  with transparency
//
// derived from iq's original raycaster
// https://www.shadertoy.com/view/Xds3zN
// and mixed with shane's transparency layers,
// https://www.shadertoy.com/view/lstGRB
//==========================================================//

float castRayTrans( vec3 ro, vec3 rd )    
{
    int   i  = 0;                                   
    float layers = 0.;
    float thD = .0023; 
    float aD = 0.;
    float col = .0;
    float t = .0;
       
    while( i ++< 60)
    {    
      vec2 res = map(ro + rd * t);                  // map() > response vec2(depth, id)
      float d = res.x;
        
      if(layers > 22. || col > 1. || t > 4.) break; // break when object something is encountred or when outside of bounds

         aD = (thD-abs(d)*13./14.)/thD;

        if(aD > 0.) { 
            
            col += aD/(1. + t*t*0.1)*0.1;
            layers++; 
        }
       t += max(abs(d)*.8, thD*1.6);               
    }
    return col;                                        // return color value
}

//==========================================================//
//                       NORMALS 
//
//==========================================================//

vec3 calcNormal( vec3 pos )
{
    vec2 e = vec2(1., -1.) * .0005;
    return normalize(e.xyy * map(pos + e.xyy).x + 
                      e.yyx * map(pos + e.yyx).x + 
                      e.yxy * map(pos + e.yxy).x + 
                      e.xxx * map(pos + e.xxx).x );
}

//==========================================================//
//                       CAMERA 
//
//==========================================================//

mat3 setCamera(vec3 ro)
{
  vec3 cw = normalize(- ro);
  vec3 cp = vec3(sin(.0), cos(.0), .0);
  vec3 cu = normalize(cross(cw,cp));
  vec3 cv = normalize(cross(cu,cw));
  
  return mat3(cu, cv, cw);
}

//==========================================================//
//                       MAIN 
//
//==========================================================//

void main(void)
{
    
  // Pixel ratio for background
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv = -1. + 2. * uv;   
  uv.x *= resolution.x / resolution.y ;
  uv *= 4.0;
    

  // Pixel ratio for skull
  vec2 p = (-resolution.xy + 2.0 * gl_FragCoord.xy)/resolution.y;
  vec2 mo = mouse*resolution.xy.xy/resolution.xy;

  // camera    
  //---------------------------
  // noisy version of skull with distortion applied to camera.
  //vec3 ro = vec3( 2. * cos(T)+ .2*cos(noise(vec3(p*15.,T))), 1., 2. * sin(T) );
  // rotation of camera on Y axis.
  vec3 ro = vec3( 2. * cos(T), 1., 2. * sin(T) );
  
  // camera-to-world transformation
  mat3 ca = setCamera(ro);    
  
    
  // ray direction
  //---------------------------
  vec3 rd = ca * normalize(vec3(p.xy, 2.));

  // render    
  //---------------------------
  vec3 tot = vec3(0.3,.30,.7)+ vec3(pow(fbm(vec3( gl_FragCoord.xy*.005,T*.1)),6.))*.2;  
    
  // cosmos
  float ff = smoothstep(.7, 1.1,fbm(.1 * vec3(uv,T ) )); 
  tot *= mix(tot*.6, ORANGE, ff*.9  );
  ff = smoothstep(.0, 0.9,fbm(.1 * vec3(uv,T ) )); 
  tot *= mix(tot*.4, PINK, ff*2.3  );
  ff = smoothstep(.5, 0.7,fbm(.1 * vec3(uv,T ) )); 
  tot *= mix(tot*.6, GREEN, ff*.8  );
  tot += smoothstep(.0,resolution.y * 3.,resolution.y-length(gl_FragCoord));
    
  //skull
  vec3 col = vec3(castRayTrans(ro,rd));  ;
  tot += .9*col-.07;

  /// lights & starfield
  vec2 n = vec2(T*.2,T*.5);
  tot /= smoothstep(.45,1.1,fbm(vec3(n+gl_FragCoord.xy *.01,.1*T )));
  tot /= smoothstep(.0,1.,fbm(vec3(  n+gl_FragCoord.xy *.01,.1*T )));
  tot /= smoothstep(.55,.7,fbm(vec3(6.*uv+n*9. ,.1)));
  

  glFragColor = vec4( tot, 1.0 );

}
