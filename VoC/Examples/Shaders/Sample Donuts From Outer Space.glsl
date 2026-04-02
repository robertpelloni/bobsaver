#version 420

// original https://www.shadertoy.com/view/3dVSWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NOISINESS   .445
#define HUEOFFSET   .53
#define DONUTWIDTH .3
//imported functions: 
//https://www.shadertoy.com/view/Msf3WH
vec2 hash( vec2 p ) // replace this by something better
{
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )    //2D simplex
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
    vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, vec3(70.0) );
}  
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//helper functions:
vec2 cartesian2polar(vec2 cartesian){
    return vec2(atan(cartesian.x,cartesian.y),length(cartesian.xy));
}

vec2 polar2cartesian(vec2 polar){
    return polar.y*vec2(cos(polar.x),sin(polar.x));
}

 vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb2hsv(vec3 rgb) {
     float Cmax = max(rgb.r, max(rgb.g, rgb.b));
     float Cmin = min(rgb.r, min(rgb.g, rgb.b));
     float delta = Cmax - Cmin;

     vec3 hsv = vec3(0., 0., Cmax);

     if (Cmax > Cmin) {
         hsv.y = delta / Cmax;

         if (rgb.r == Cmax)
             hsv.x = (rgb.g - rgb.b) / delta;
         else {
             if (rgb.g == Cmax)
                 hsv.x = 2. + (rgb.b - rgb.r) / delta;
             else
                 hsv.x = 4. + (rgb.r - rgb.g) / delta;
         }
         hsv.x = fract(hsv.x / 6.);
     }
     return hsv;
 }

float sdTorus2D(float distToMid,float radius,  float thickness){    //returns the distance to a torus, with the distance to the torus center, its radius and thiccness as inputs
return abs(distToMid- radius)-thickness;
}

float donutFade(float distToMid,float radius,  float thickness){    //returns in the domain [0,1] from the inner edge 0 to the outer edge 1 of the torus  
return clamp( (distToMid-radius)/thickness+.5,0.,1.);
}

void main(void)
{
   vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
     uv*=3.;                     //zoom
    
    uv += noise(uv+(time+sin(time*.1)*10.+vec2(cos(time*.144),sin(time*.2)*14.))*.2)*NOISINESS;    //map distortion+ movement
  // uv/= 1.+  (time/2.)*2.;
    vec2 uvPol = cartesian2polar(uv);
    //vec3 col = 0.5 +.5*cos(time+uv.xyx+vec3(0,2,4));
    vec3 col = vec3(0.  );
    
    float colorAccumulation =  .5;
    float result = sin(uv.y);
     
     
    float torus = donutFade(uvPol.y, fract(time/3. )*5. ,DONUTWIDTH);   //pulsating donut
    float contribution =  min(smoothstep(torus ,1.,.95),smoothstep(torus , .0 ,.05) );    //determine how much this area is affected by torus1
    colorAccumulation += contribution ; 
    col +=  hsv2rgb(vec3(torus *1.3 +HUEOFFSET,1.,1.)) *contribution ;

    
     torus = donutFade(uvPol.y, .5,DONUTWIDTH); 
     contribution =  min(smoothstep(torus ,1.,.95),smoothstep(torus , .0 ,.05) );    //determine how much this area is affected by torus1
    colorAccumulation += contribution ; 
    col +=  hsv2rgb(vec3(torus *1.3 +HUEOFFSET,1.,1.)) *contribution ;

    torus = donutFade(uvPol.y, 1.1, DONUTWIDTH); 
    contribution =  min(smoothstep(torus ,1.,.95),smoothstep(torus , .0 ,.05) );    //determine how much this area is affected by torus1
    colorAccumulation += contribution ; 
    col +=  hsv2rgb(vec3(torus *1.3 +HUEOFFSET,1.,1.)) *contribution ;

    torus = donutFade(uvPol.y, 1.5, DONUTWIDTH); 
    contribution =  min(smoothstep(torus ,1.,.95),smoothstep(torus , .0 ,.05) );    //determine how much this area is affected by torus1
    colorAccumulation += contribution ; 
    col +=  hsv2rgb(vec3(torus *1.3 +HUEOFFSET,1.,1.)) *contribution ;

    
     //col /= colorAccumulation;        //for making the background white, use this line and initialize col as .5
     //col = vec3(contribution1,contribution1,contribution1) ;
    glFragColor = vec4(col,1.0);
}
