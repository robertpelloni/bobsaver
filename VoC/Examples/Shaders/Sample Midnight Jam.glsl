#version 420

// original https://www.shadertoy.com/view/clsXRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846  
#define TWO_PI 6.28318530718
#define NUM_OCTAVES 10
#define FRC time*0.7
#define MLS time*0.7

/* Image to Grayscale */
float img2avg ( vec4 img ) { 
  return dot(img.rgb, vec3(0.33333)); }
float img2avg ( vec3 img ) { 
  return dot(img.rgb, vec3(0.33333)); }
    
vec2  zr(vec2 uv, vec2 move, float zoom, float ang) {
          uv -= 0.5;
          uv *= mat2( 
                    cos(ang) , -sin(ang) ,
                    sin(ang) ,  cos(ang) );
          uv *= zoom;
          uv -= move*zoom;
          uv -= move*(5.0-zoom);
          return(uv); }

float random (float x) {
          return fract(sin(0.005387+x)*129878.4375453); }

float random (vec2 uv) {
          return fract(sin(0.387+dot( uv.xy, vec2(12.9,78.2))) * 4.54 ); }

float noise(float x) {
            float i = floor(x);
            float f = fract(x);
            float y = mix(random(i), random(i + 1.0), smoothstep(0.,1.,f));
            return y; }

vec2  random2(vec2 st){
          st = vec2( dot(st,vec2(127.1,311.7)), dot(st,vec2(269.5,183.3)));
        return -1.0 + 2.0*fract(sin(st)*43758.5453123); }
float noise(vec2 st) {
          vec2  i = floor(st);   // Gradient Noise by Inigo Quilez - iq/2013
          vec2  f = fract(st);   // https://www.shadertoy.com/view/XdXGW8
          vec2  u;
            u = f*f*f*(f*(f*6.-15.)+10.);
          return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                           dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                      mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                           dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y); }

vec3  hsb2rgb (vec3 c) {
          vec4   K = vec4(1.0,2.0/3.0,1.0/3.0,3.0);                     // Color conversion function from Sam Hocevar: 
          vec3   p = abs(fract(c.xxx+K.xyz)*6.0-K.www);                 // lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
          return c.z*mix(K.xxx,clamp(p-K.xxx,0.0,1.0),c.y); }
                                     
float rect(vec2 uv, float x, float y, float w, float h) { 
            return step(x-w*0.5,uv.x) * step(uv.x,x+w*0.5)
                      * step(y-h*0.5,uv.y) * step(uv.y,y+h*0.5);   }
                 
float circle(vec2 uv, float x, float y, float d) {
            return step(distance(uv,vec2(x,y)),d*0.5); }                         
                                     
float sphere2(vec2 uv, float x, float y, float d) {
        vec2 dist = uv-vec2(x,y);
            return clamp( (1.- dot(dist,dist)/(d/8.0)) ,0.0, 1.0); }

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float fbm_noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * fbm_noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}
            
vec2 random3( vec2 p ) {
  return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float map(float value, float min1, float max1, float min2, float max2) {
          return min2 + (value - min1) * (max2 - min2) / (max1 - min1);    }
    
mat2 rotate2d(float a)   {
     return mat2( 
     cos(a) , -sin(a) ,
     sin(a) ,  cos(a) ); }
    
mat2 scale(vec2 s) {
     return mat2(
     s.x, 0.0 ,
     0.0 , s.y );  }

vec2 uv2wtr( vec2 uv, float kx, float ky) {
  kx = kx*2.0+0.01;
  vec2 t1 = vec2(kx,ky);
  vec2 t2 = uv;
  for(int i=1; i<10; i++) {
    t2.x+=0.3/float(i)*sin(float(i)*3.0*t2.y+MLS*kx)+t1.x;
    t2.y+=0.3/float(i)*cos(float(i)*3.0*t2.x+MLS*kx)+t1.y; }
    vec3 tc1;
  tc1.r=cos (t2.x+t2.y+1.0)*0.5+0.5;
  tc1.g=sin (t2.x+t2.y+1.0)*0.5+0.5;
  tc1.b=(sin(t2.x+t2.y)+cos(t2.x+t2.y))*0.5+0.5;
  uv = uv +(tc1.rb*vec2(2.0)-vec2(1.0))*ky;
    return uv; }
    
float nexto(float ch, float n) {
  float a;
  a = sin(n*ch);  a = floor(a*10000.0)*0.001;
  a = cos(a);     a = floor(a*8000.0)*0.001;
  return fract(a); }    
    
vec2 uv2wav( vec2 uv1, float kx, float ky, float sd) {
    float tx = kx;
    float ty = ky;
        vec2 t1;
        float time = FRC*0.0;
    //                       frq                                     spd                    amp
    t1.y = cos( uv1.x * nexto(1.0,tx)*10.0 + time * ceil(nexto(2.0,tx)*10.0-5.0) ) * nexto(3.0,tx)*1.15;
    t1.x = sin( uv1.y * nexto(1.0,ty)*10.0 + time * ceil(nexto(2.0,ty)*10.0-5.0) ) * nexto(3.0,ty)*1.15;
    uv1 = uv1 + vec2(t1.x,t1.y)*sd;
    t1.y = cos( uv1.x * nexto(4.0,tx)*10.0 + time * ceil(nexto(5.0,tx)*10.0-5.0) ) * nexto(6.0,tx)*0.55;
    t1.x = sin( uv1.y * nexto(4.0,ty)*10.0 + time * ceil(nexto(5.0,ty)*10.0-5.0) ) * nexto(6.0,ty)*0.55;
    uv1 = uv1 + vec2(t1.x,t1.y)*sd;
    t1.y = cos( uv1.x * nexto(7.0,tx)*10.0 + time * ceil(nexto(8.0,tx)*10.0-5.0) ) * nexto(9.0,tx)*0.15;
    t1.x = sin( uv1.y * nexto(7.0,ty)*10.0 + time * ceil(nexto(8.0,ty)*10.0-5.0) ) * nexto(9.0,ty)*0.15;
    uv1 = uv1 + vec2(t1.x,t1.y)*sd;
    return uv1; }
    
/* RGB to HSB Conversion */
vec3 rgb2hsb( vec3 c ) {
  // Color conversion function from Sam Hocevar: 
  // lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
  vec4   K = vec4(0.0,-1.0/3.0,2.0/3.0,-1.0);
  vec4   p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4   q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
  float  d = q.x - min(q.w, q.y);
  float  e = 1.0e-10;
  return vec3(abs(q.z+(q.w-q.y)/(6.0*d+e)), d/(q.x+e), q.x); }

/* Hue Tune & Replace  */
vec3 rgb2ht( vec3 img, float t) {
    img.rgb = rgb2hsb(img.rgb);
    img.r = img.r+t;
    return hsb2rgb(img.rgb); }
vec3 rgb2hr( vec3 img, float t) {
    img.rgb = rgb2hsb(img.rgb);
    img.r = t;
    return hsb2rgb(img.rgb); }
        
/* Saturation Tune & Replace */
vec3 rgb2st( vec3 img, float t) {
    img.rgb = rgb2hsb(img.rgb);
    img.g = img.g+t;
    return hsb2rgb(img.rgb); }
vec3 rgb2sr( vec3 img, float t) {
    img.rgb = rgb2hsb(img.rgb);
    img.g = t;
    return hsb2rgb(img.rgb); }
        
/* Lightness Tune & Replace  */
vec3 rgb2lt( vec3 img, float t) {
    img.rgb = rgb2hsb(img.rgb);
    img.b = img.b+t;
    return hsb2rgb(img.rgb); }
vec3 rgb2lr( vec3 img, float t) {
    img.rgb = rgb2hsb(img.rgb);
    img.b = t;
    return hsb2rgb(img.rgb); }

vec2 zoom(vec2 uv, vec2 m, float zmin, float zmax) {
    float zoom = map(sin(FRC),-1.,1.,zmin,zmax);
    uv -= 0.5;
    uv *= zoom;
    uv -= m*zoom;
    uv -= m*(zmax-zoom);
    return(uv);
}

vec2 roto(vec2 uv, vec2 m, float ang) {
  uv -= 0.5;    
  uv *= mat2( 
  cos(ang) , -sin(ang) ,
  sin(ang) ,  cos(ang) );
  uv += 0.5;
    return(uv);
}
    
// Description : GLSL 2D simplex noise function
//      Author : Ian McEwan, Ashima Arts
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License :
//  Copyright (C) 2011 Ashima Arts. All rights reserved.
//  Distributed under the MIT License. See LICENSE file.
//  https://github.com/ashima/webgl-noise
    
// Some useful functions
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {

    // Precompute values for skewed triangular grid
    const vec4 C = vec4(0.211324865405187,
                        // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,
                        // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,
                        // -1.0 + 2.0 * C.x
                        0.024390243902439);
                        // 1.0 / 41.0

    // First corner (x0)
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    // Other two corners (x1, x2)
    vec2 i1 = vec2(0.0);
    i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
    vec2 x1 = x0.xy + C.xx - i1;
    vec2 x2 = x0.xy + C.zz;

    // Do some permutations to avoid
    // truncation effects in permutation
    i = mod289(i);
    vec3 p = permute(
            permute( i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(
                        dot(x0,x0),
                        dot(x1,x1),
                        dot(x2,x2)
                        ), 0.0);

    m = m*m ;
    m = m*m ;

    // Gradients:
    //  41 pts uniformly over a line, mapped onto a diamond
    //  The ring size 17*17 = 289 is close to a multiple
    //      of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt(a0*a0 + h*h);
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);

    // Compute final noise value at P
    vec3 g = vec3(0.0);
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
    return 130.0 * dot(m, g);
}
    
    
/////////////// Float 

/* Float to Zero Centered */
float f2z ( float f ) {
    return f*2.0-1.0; }
    
/* Zero Centered to Float */
float z2f ( float z ) {
    return z*0.5+0.5; }
    
/* Float Constrain */
float f2f ( float f ) {
    return clamp(f,0.0,1.0); }
    
/* Zero Centered Constrain */
float z2z ( float z ) {
    return clamp(z,-1.0,1.0); }

/* Float to Random */    
float f2rand (float x) {
  return fract(sin(0.005387+x)*129878.4375453); }
    
/* Float to Noise */    
float f2noise(float x) {
    return mix(f2rand(floor(x)), f2rand(floor(x) + 1.0), smoothstep(0.,1.,fract(x))); }
    
/* Float to Slit */
float f2slit ( float f, float lvl, float len, float smt ) { 
    return smoothstep(lvl-len*0.5-smt,lvl-len*0.5    ,f) - 
           smoothstep(lvl+len*0.5    ,lvl+len*0.5+smt,f); }

/* Float to Map */
float f2m(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);        }
    
float sphere(vec2 uv, float x, float y, float d, vec2 l) {
    return 
        (1.0-distance(uv,vec2(x,y)+l*d)*(1.0/d))  
        * 
        smoothstep(d*0.51,d*0.49,distance(uv,vec2(x,y)))
    ; }
    
float cube(vec2 uv, float x, float y, float s) { 

    return step(x-s*0.5,uv.x) * step(uv.x,x+s*0.5)
                 * step(y-s*0.5,uv.y) * step(uv.y,y+s*0.5);     }
        
float sphere3(vec2 uv, float x, float y, float d, vec2 l) {
    return 
        clamp((1.0-distance(uv,vec2(x,y)+l*d)),0.0,1.0)
    ; }

/* Cartesian to Polar */
vec2 xy2md(vec2 xy) {
    return vec2( 
        sqrt( pow(xy.x,2.0) + pow(xy.y,2.0) ) ,
        atan(xy.y,xy.x) ); }

/* Polar to Cartesian */
vec2 md2xy(vec2 md) {
    return vec2( 
        md.x * cos(md.y) ,
        md.x * sin(md.y) ); }
    
/* Barrel Distortion */
vec2 uv2brl( vec2 uv, float pwr ) {
    //uv.y = uv.y * (HEIGHT/WIDTH);  
    uv = md2xy(xy2md(uv - 0.5) + vec2(pwr-0.5,0.0)) + 0.5;
    //uv.y = uv.y * (WIDTH/HEIGHT);  
    return uv; }

// ----------------------------------------

void main(void) {

// Normalized pixel coordinates (from 0 to 1)
vec2  uv = gl_FragCoord.xy/resolution.xy;
vec2  RES = resolution.xy;
vec2  M = mouse*resolution.xy.xy/resolution.xy;
      M.y = 1.0-M.y;

const int n = 10;        // number of layers
float thr = 0.85;        // threshold of roads in layer
float amt = 0.50;        // amount of cars in layer

      // setup main coordinate system according to the screen dimensions
vec2  uv0 = gl_FragCoord.xy/RES.xy; uv0.y = 1.0-uv0.y;
      uv0.x *= RES.x/RES.y;
vec2  uvc = uv0;
            uv0.x -= ((RES.x-RES.y)/RES.y)*0.5;

      // set main coordinate system movement parameters
float angle = sin(MLS*0.2); // MLS
float zoom  = 20.0+10.0*sin(FRC*0.5);
vec2  move  = vec2(FRC*0.2,FRC*0.7);        

      // move main coordinate system
      uv0 = zr(uv0+vec2(abs(sin(M.x*PI*0.5)),abs(sin(M.y*PI*0.5))), move, zoom, angle);

vec3  layer;  // RGB of every layer
vec3  stack;  // RGB of composed image

for (int i=n; i>0; i--) {    // for every layer

    vec2  uv = uv0; // copy main coordinate system to create local fixed UV
                // take  ↓ it  ↓ do not move  ↓ zoom according to layer number              ↓ rotate 
                uv = zr( uv,   vec2(0.0),     1.0 + (float(n-i))*0.3 + sin(FRC*0.01)*0.005,  PI*2.0*random(float(i)*0.258) );

                // bend the road
    float kx = 0.5*sin(0.2*PI*random(float(i)*1087.4432)+0.00001*length(uv));     // bending coefficient
                uv.y +=                                         sin(uv.x*kx);                         // bend Y axis with Sin
                uv.x += (fract(uv.y)-0.5) * sin(uv.x*kx-PI*0.5)*kx;     // bend X axis with modified Sin
                //                    ↑ we need to bend road X according to the road center

    float dir = step(mod(uv.y,2.0),1.0);    // neighboring roads will have opposite directions (0 and 1)

                // calculate speed on every road according to direction
                //                                    ↓ boost  boost ↓      ↓ break                   ↓ according to layer 
    float    speed = (dir-0.5) * 10.0 * ( FRC + 2.0 * (noise(FRC*0.2+floor(uv.y)+float(i)*10.0)) * 2.0 - 1.0 );
                //       ↑ direction         ↑ counter  counter ↑       ↑ according to road           ↑ normalize to (-1;1)

    vec2  uvi = floor(uv);        // integer part of fixed UV
    vec2  uvf = fract(uv);        // fract part of fixed UV

    vec2  uvm = uv;               // local moveable UV
                uvm.x += speed;            // move every road along X axis
    vec2  mi  = floor(uvm);   // integer part of moveable UV
    vec2  mf  = fract(uvm);     // fract part of moveable UV

    float car_vis = step(amt, random(mi.x+float(i)*200.0));                                             // is current block has a car
    float CPR = car_vis * (1.0-step(amt, random(mi.x-1.0+float(i)*200.0)));             // is current block has a car and is previous block empty
    float CNX = car_vis * (1.0-step(amt, random(mi.x+1.0+float(i)*200.0)));             // is current block has a car and is next block empty
    float CPR2 = (1.0-car_vis) * (step(amt, random(mi.x-1.0+float(i)*200.0)));     // is current block empty and is previous block has a car
    float CNX2 = (1.0-car_vis) * (step(amt, random(mi.x+1.0+float(i)*200.0)));     // is current block empty and is next block has a car

    vec3  c_lamp = vec3(1.0);                                                                    // RGB of road lightning
    vec3  c_red  = vec3(1.0,0.0,0.0);                                                    // RGB of red lights
    vec3  c_yel  = vec3(1.0,1.0,random(mi.x+float(i)*300.0));    // RGB of yellow lights

                // paint the car:                                ↓ hue                             ↓ saturation            ↓ brightness
    vec3  car_color = hsb2rgb(vec3( (random(mi.y) + random(mi.x*10.1+5.5)*0.3),  0.4+0.6*random(mi.x+10.0), 1.0 ) );

    float    road_vis = step(thr,(random(uvi.y+float(i)*100.0)))-0.01;     // is current road visible
    float kl = 0.25;    // brightness of car lights
    float ka = 0.50;  // brightness of road lights

                // lightning of roads and cars
    vec3    lamp = mix(vec3(0.0), c_lamp,    pow((abs(snoise( uv/6.5))) ,5.0) +0.07 )        // fixed road lights: white
                         + mix(vec3(0.0), c_red*ka , pow((abs(snoise((uvm+137.0)/5.5))),5.0))              // moving road lights: red
                         + mix(vec3(0.0), c_yel*ka , pow((abs(snoise((uvm+872.0)/5.5))),5.0))              // moving road lights: yellow

                           // drawing 4 circles for car lights, coloring it according to the road direction
                         + mix(vec3(0.0), mix(c_yel,c_red,dir)*(0.6+0.4*random(mi.x+float(i)*13.4)), 
                                                                                                    CNX * sphere2(mf,0.8,0.7,0.1)          
                                                                                                + CNX * sphere2(mf,0.8,0.3,0.1))         
                         + mix(vec3(0.0), mix(c_red,c_yel,dir)*(0.6+0.4*random(mi.x+float(i)*73.7)), 
                                                                                                    CPR * sphere2(mf,0.2,0.7,0.1)
                                                                                                + CPR * sphere2(mf,0.2,0.3,0.1)) ;        

                             // drawing 4 circles for extra car lights, coloring it according to the road direction:                                                                 
                         + mix(vec3(0.0), mix(c_red*kl,car_color*kl,dir)*(0.6+0.4*random(mi.x+float(i)*73.7)),         
                                                                                                +    CNX2 * sphere2(mf-vec2(0.5,0.0), 0.5, 0.5, 3.0 ) )
                         + mix(vec3(0.0), mix(car_color*kl,c_red*kl,dir)*(0.6+0.4*random(mi.x+float(i)*13.4)), 
                                                                                                +    CPR2 * sphere2(mf+vec2(0.5,0.0), 0.5, 0.5, 3.0 ) )
                         + mix(vec3(0.0), mix(car_color*kl,c_red*kl,dir)*(0.6+0.4*random(mi.x+float(i)*73.7)), 
                                                                                                +    CNX  * sphere2(mf-vec2(0.5,0.0), 0.5, 0.5, 3.0 ) )
                         + mix(vec3(0.0), mix(c_red*kl,car_color*kl,dir)*(0.6+0.4*random(mi.x+float(i)*13.4)), 
                                                                                                +    CPR  * sphere2(mf+vec2(0.5,0.0), 0.5, 0.5, 3.0 ) ) ;

                lamp = clamp(lamp,vec3(0.0),vec3(1.0)); // clamp lights to avoid overexposure

                // paint layer with:
                //            ↓ road visibility     ↓ road brighntess      ↓ road lightning
                layer = vec3( road_vis            * float(i)/float(n)    * lamp 
                                            //        ↓ road tiles                                ↓ road lines      
                                            * ( 0.3 * rect( uvf,  0.5,  0.5,  1.0,  0.9 ) + 1.0 * rect( uvf, 0.5,  0.5,  0.4,  0.1  ) ) ) 
                                            // ↓ minimal constant lightning                    
                                            + lamp * 0.25;    

                // add road cracks
                layer *= (0.75+0.6*pow( abs( snoise(uv*8.0+131.0)  )  ,  3.0  ));

    float fig;    // draw a car
                fig += random(mi.x+0.01) * circle(  mf,  random(mi.x+0.11),   0.5  ,0.3+0.4*random(mi+0.21)  );
                fig += random(mi.x+0.02) *   rect(  mf,  random(mi.x+0.12),   0.5  ,0.1+0.9*random(mi+0.22)  ,  0.1+0.9*random(mi+0.32));
                fig += random(mi.x+0.05) * circle(  mf,  random(mi.x+0.15),   0.5  ,0.3+0.3*random(mi+0.25)  );
                fig += random(mi.x+0.06) *   rect(  mf,  random(mi.x+0.16),   0.5  ,0.1+0.9*random(mi+0.26)  ,  0.1+0.9*random(mi+0.36));
                fig += random(mi.x+0.07) *   rect(  mf,  random(mi.x+0.17),   0.5  ,0.1+0.9*random(mi+0.27)  ,  0.1+0.9*random(mi+0.37));
                // add extra shadows to a car    
                fig *= (0.75+pow( abs( snoise(uvm+725.0)  )  ,  2.5  ));

                // apply lighting to a car and add a car to the layer
                layer = mix(layer, car_color * fig * lamp, car_vis * step(0.05,fig));

                // add layer to the stack
                stack = mix(stack,layer,road_vis+0.01);

                // if current layer is not empty break the cycle to avoid extra calculations
                if (length(stack)>0.0) break;

}
            
vec3  color = hsb2rgb(vec3( noise(uv0*0.0020)*PI,  0.3, 1.0 ) );
float cloud = pow( fbm( vec2(fbm(uv0*0.1),fbm(uv0*0.1+vec2(10.0)+vec2(FRC*0.4,0.0)))   ),7.0)*10.0 * map(zoom,10.0,30.0,0.3,1.0);
      cloud = clamp(cloud,0.0,0.8);
      stack = mix(stack, color , cloud );

vec4  img = vec4(stack,1.0);

    // Output to screen
    glFragColor = img;
}
