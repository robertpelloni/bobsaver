#version 420

// original https://www.shadertoy.com/view/Xltczf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Raycaster code credit to Curv https://github.com/doug-moen/curv

// animation data
const vec3[] v1= vec3[]  (  
                    vec3 (50., 50., 50.), 
                    vec3 (-50., 50., 50.), 
                    vec3 (-50., -50., 50.), 
                    vec3 (50., -50., 50.), 
                    vec3 (50., -50., 10.),
                    vec3 (50., 50., 10.), 
                    vec3 (-50., 50., 10.),
                    vec3 (-0., 0., 100.),
                    vec3 (-0., 0., 10.),
                    vec3 (-0., 0., 100.), 
                    vec3 (-100., 0., 10.), 
                    vec3 ( 100., 0., 10.), 
                    vec3 (-100., 0., 10.), 
                    vec3 (-0., 0., 40.),
                    vec3 (-0., 0., 15.),
                    vec3 (-0., 0., 15.),      
                    vec3 (-0., 0., 15.),
                    vec3 (-0., 0., 15.), 
                    vec3 (-50., -50.,20.) 
                  
);

 
// rotm sphere
float sdSphere(in vec3 p, float s) {
    return length(p) - s;
}
 

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

 
 // wraps index 0 - tak 
float wrapi( float x,float tak){ return mod((mod(x  , tak) + tak) , tak) ;}

vec3 smooth_animate(float t){
 
float ll=float(v1.length());     // array lenght
float  i=round(ll*t);           // index of closest animation key
float T=mod( (ll*t+0.5),1.) ;   // local t of curve piece

//construct three point bezier of current key and  half way to next and prev key
// wrap index to keep animation looping
vec3 p0=    mix( v1[int( wrapi(i-1.,ll))], v1[int(wrapi(i,ll))],0.5);
vec3 p1=    v1[int(wrapi(i,ll))];
vec3 p2=    mix( v1[int(wrapi(i,ll))],v1[int( wrapi(i+1.,ll))],0.5)  ;
    
// 3p bezier
    return mix(mix( p0,p1,T),mix(p1,p2,T),T) ;}

 

vec4 map(vec4 r0)
    
{  
    vec3 p=r0.xyz ;
   vec3 psp1= vec3(p.x*cos(time)-p.y*sin(time),
                  p.y*cos(time)+p.x*sin(time) ,p.z) ;

   vec3 psp2= vec3(p.x*cos(time/-2.)-p.y*sin(time/-2.),
                  p.y*cos(time/-2.)+p.x*sin(time/-2.) ,p.z) ;

    vec3 m1= smooth_animate(mod(time/15.,1.))  ;
   vec3 m2= smooth_animate(mod((time)/12.,1.)+0.5)  ;
  vec3 pm1=psp1-m1 ;
  vec3 pm2=psp2-m2 ;

  float sphere1=sdSphere( psp1-m1, 19.9);
  float sphere2=sdSphere( psp2-m2, 29.9);
  float plane=p.z;

 float c1= mod( 
        mod (floor(pm1.x/10.),2.)+
        mod (floor(pm1.y/10.),2.)+
        mod (floor(pm1.z/10.),2.)
        ,2.);
    
 float c2= mod( 
        mod (floor(pm2.x/10.),2.)+
        mod (floor(pm2.y/10.),2.)+
        mod (floor(pm2.z/10.),2.)
        ,2.);
    
 float c3= mod( mod (floor(p.x/10.),2.)+mod (floor(p.y/10.),2.),2.);
 
 float c= sphere2>sphere1?c1:c2;
       c= plane> min(sphere2,sphere1)?c:c3;
 
    return vec4(smin(plane,smin(sphere1,sphere2,20.),20.),c,c,c );
 }

////Raycaster code credit to Curv https://github.com/doug-moen/curv

const vec3 bbox_min = vec3(-7.363703305156273,-7.363703305156273,-7.363703305156273);
const vec3 bbox_max = vec3(7.363703305156273,7.363703305156273,7.363703305156273);
// ray marching. ro is ray origin, rd is ray direction (unit vector).
// result is (t,r,g,b), where
//  * t is the distance that we marched,
//  * r,g,b is the colour of the distance field at the point we ended up at.
//    (-1,-1,-1) means no object was hit.
vec4 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 400.0;
   
    float t = tmin;
    vec3 c = vec3(-1.0,-1.0,-1.0);
    for (int i=0; i<200; i++) {
        float precis = 0.0005*t;
        vec4 res = map( vec4(ro+rd*t,time) );
        if (res.x < precis) {
            c = res.yzw;
            break;
        }
        t += res.x;
        if (t > tmax) break;
    }
    return vec4( t, c );
}
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( vec4(pos + e.xyy,time) ).x + 
                      e.yyx*map( vec4(pos + e.yyx,time) ).x + 
                      e.yxy*map( vec4(pos + e.yxy,time) ).x + 
                      e.xxx*map( vec4(pos + e.xxx,time) ).x );
}
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( vec4(aopos,time) ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}
// in ro: ray origin
// in rd: ray direction
// out: rgb colour
vec3 render( in vec3 ro, in vec3 rd )
{ 
    //vec3 col = vec3(0.7, 0.9, 1.0) +rd.z*0.8;
    //vec3 col = vec3(0.8, 0.9, 1.0);
    vec3 col = vec3(1.0, 1.0, 1.0);
    vec4 res = castRay(ro,rd);
    float t = res.x;
    vec3 c = res.yzw;
    if( c.x>=0.0 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = mix(c,normalize(c),0.12)*0.34;

        // lighting        
        float occ = calcAO( pos, nor );
        vec3  lig1 = normalize( vec3(-0.8, 0.3, 0.5) );
        vec3  lig2 = normalize( vec3(0.8, 0.3, 0.5) );
        float amb = clamp( 0.5+0.5*nor.z, 0.0, 1.0 );
        float dif1 = clamp( dot( nor, lig1 ), 0.0, 1.0 );
        float dif2 = clamp( dot( nor, lig2 ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig1.x,lig1.y,0.0))), 0.0, 1.0 )*clamp( 1.0-pos.z,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.z );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        float spe1 = pow(clamp( dot( ref, lig1 ), 0.0, 1.0 ),32.0);
        float spe2 = pow(clamp( dot( ref, lig2 ), 0.0, 1.0 ),32.0);
        
        vec3 lin = vec3(0.0);
        lin += 4.30*dif1*vec3(1.00,0.80,0.55);
        lin += 4.30*dif2*vec3(1.00,0.80,0.55);
        lin += 14.00*spe1*vec3(1.00,0.90,0.70)*dif1;
        lin += 14.00*spe2*vec3(0.50,0.90,1.0)*dif2;
        lin += 0.9*amb*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*vec3(0.40,0.60,1.00)*occ;
        lin += 0.20*bac*vec3(0.935,0.935,0.935)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
        vec3 iqcol = col*lin;

        //col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
        col = mix(col,iqcol, 0.64);
    }

    return vec3( clamp(col,0.0,1.0) );
}
// Create a matrix to transform coordinates to look towards a given point.
// * `eye` is the position of the camera.
// * `centre` is the position to look towards.
// * `up` is the 'up' direction.
mat3 look_at(vec3 eye, vec3 centre, vec3 up)
{
    vec3 ww = normalize(centre - eye);
    vec3 uu = normalize(cross(ww, up));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}
// Generate a ray direction for ray-casting.
// * `camera` is the camera look-at matrix.
// * `pos` is the screen position, normally in the range -1..1
// * `lens` is the lens length of the camera (encodes field-of-view).
//   0 is very wide, and 2 is a good default.
vec3 ray_direction(mat3 camera, vec2 pos, float lens)
{
    return normalize(camera * vec3(pos, lens));
}
void main(void)
{
    const vec3 origin = (bbox_min + bbox_max) / 2.0 +vec3 (0,0,10);
    const vec3 radius = (bbox_max - bbox_min) / 2.0;
    float r = max(radius.x, max(radius.y, radius.z)) / 1.0;
    vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    p.x *= resolution.x/resolution.y;
 
      vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
      //  vec3 eye = vec3 (cos (4. * mouse.x) * 67., sin (4. * mouse.x) *sin (4. * mouse.y) * 67., -cos (4. * mouse.y) * 67.);
vec3 eye = vec3(sin(time/5.)*150., cos(time/5.)*180., cos(time/10.)*4.+50.);
    vec3 centre = vec3(-1.0, 0.0, 30.0);
    vec3 up = eye+ vec3(0.0, 0.0, 1.0);
     
 
    mat3 camera = look_at(eye, centre, up);
    vec3 dir = ray_direction(camera, p, 2.5);

    vec3 col = render( eye, dir );
    
    // convert linear RGB to sRGB
    col = pow(col, vec3(0.4545));
    
    glFragColor = vec4(col,1.0);
}
