#version 420

// original https://www.shadertoy.com/view/ltjczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: Rigel 
// licence: https://creativecommons.org/licenses/by/4.0/
// link: https://www.shadertoy.com/view/ltjczK

/*
When you graph a real function y=f(x) you need a plane (2D). When you 
graph a complex function w=f(z), to see the relationship between 
the input complex plane (2D) and the output complex plane (2D), you need 4D. 
Because humans are not able to see in 4D one technique to visualize 
these functions is to use color hue, and saturation as the two extra 
dimensions. This technique is called domain coloring. 
https://en.wikipedia.org/wiki/Domain_coloring

In case you know nothing about complex numbers, or need a refresher
this youtube serie is very good !
https://www.youtube.com/watch?v=T647CGsuOVU
*/

#define speed time*.05

vec2 toCarte(vec2 z) { return z.x*vec2(cos(z.y),sin(z.y)); }
vec2 toPolar(vec2 z) { return vec2(length(z),atan(z.y,z.x)); }

// All the following complex operations are defined for the polar form 
// of a complex number. So, they expect a complex number with the 
// format vec2(radius,theta) -> radius*eˆ(i*theta).
// The polar form makes the operations *,/,pow,log very light and simple
// The price to pay is that +,- become costly :/ 
// So I switch back to cartesian in those cases.
vec2 zmul(vec2 z1,vec2 z2) { return vec2(z1.x*z2.x,z1.y+z2.y); }
vec2 zdiv(vec2 z1, vec2 z2) { return vec2(z1.x/z2.x,z1.y-z2.y); }
vec2 zlog(vec2 z) { return toPolar(vec2(log(z.x),z.y)); }
vec2 zpow(vec2 z, float n) { return vec2(exp(log(z.x)*n),z.y*n); }
vec2 zpow(float n, vec2 z) { return vec2(exp(log(n)*z.x*cos(z.y)),log(n)*z.x*sin(z.y)); }
vec2 zpow(vec2 z, vec2 w) { return zpow(exp(1.),zmul(zlog(z),w)); }
vec2 zadd(vec2 z1, vec2 z2) { return toPolar(toCarte(z1) + toCarte(z2)); }
vec2 zsub(vec2 z1, vec2 z2) { return toPolar(toCarte(z1) - toCarte(z2)); }

//sinz, cosz and tanz came from -> https://www.shadertoy.com/view/Mt2GDV
vec2 zsin(vec2 z) {
   z = toCarte(z);
   float e1 = exp(z.y);
   float e2 = exp(-z.y);
   float sinh = (e1-e2)*.5;
   float cosh = (e1+e2)*.5;
   return toPolar(vec2(sin(z.x)*cosh,cos(z.x)*sinh));
}

vec2 zcos(vec2 z) {
   z = toCarte(z);
   float e1 = exp(z.y);
   float e2 = exp(-z.y);
   float sinh = (e1-e2)*.5;
   float cosh = (e1+e2)*.5;
   return toPolar(vec2(cos(z.x)*cosh,-sin(z.x)*sinh));
}

vec2 ztan(vec2 z) {
    z = toCarte(z);
    float e1 = exp(z.y);
    float e2 = exp(-z.y);
    float cosx = cos(z.x);
    float sinh = (e1 - e2)*0.5;
    float cosh = (e1 + e2)*0.5;
    return toPolar(vec2(sin(z.x)*cosx, sinh*cosh)/(cosx*cosx + sinh*sinh));
}

vec2 zeta(vec2 z) {
   vec2 sum = vec2(.0);
   for (int i=1; i<20; i++) 
       sum += toCarte(zpow(float(i),-z));
   return toPolar(sum);
}

vec2 lambert(vec2 z) {
   vec2 sum = vec2(.0);
   for (int i=1; i<15; i++)
      sum += toCarte(zdiv(zpow(z,float(i)),zsub(vec2(1.,.0),zpow(z,float(i)))));
   return toPolar(sum);
}

vec2 mandelbrot(vec2 z) {
   vec2 sum = vec2(.0);
   vec2 zc = toCarte(z);
   for (int i=1; i<11; i++) 
       sum += toCarte(zpow(toPolar(sum),2.)) + zc;
   return toPolar(sum);
}

vec2 julia(vec2 z) {
    vec2 sum = toCarte(zpow(z,2.));
    // the julia set is connected if C is in the mandelbrot set and disconnected otherwise
    // to make it interesting, C is animated on the boundary of the main bulb
    // the formula for the boundary is 0.5*eˆ(i*theta) - 0.25*eˆ(i*2*theta) and came from iq
    // http://iquilezles.org/www/articles/mset_1bulb/mset1bulb.htm
    float theta = fract(speed)*2.*6.2830;
    vec2 c = toCarte(vec2(0.5,.5*theta)) - toCarte(vec2(0.25,theta)) - vec2(.25,.0);
    for (int i=0; i<7; i++) sum += toCarte(zpow(toPolar(sum),2.)) + c;
    return toPolar(sum);
}

vec2 map(vec2 uv) {
  
    float t = floor(mod(speed,10.));
  
    //t = 7.;
    float s = t == 1.? 4.  : t==5.? .6: t==4.? 6. : t==5.? 2.5 : t== 9. ? 13. : 3.;  
   
    uv *= s + s*.2*cos(fract(speed)*6.2830);
    
    vec2 fz, z = toPolar(uv); 
        
         // z + 1 / z - 1
    fz = t == 0. ? zdiv(zadd(z,vec2(1.0)),zsub(z,vec2(1.0,.0)) ) :
         // formula from wikipedia https://en.m.wikipedia.org/wiki/Complex_analysis
         // fz = (zˆ2 - 1)(z + (2-i))ˆ2 / zˆ2 + (2+2i)
         t == 1. ? zdiv(zmul(zsub(zpow(z,2.),vec2(1.,0)),zpow(zadd(z,toPolar(vec2(2.,-1.))),2.)),zadd(zpow(z,2.),toPolar(vec2(2.,-2.)))) :
         // z^(3-i) + 1.
         t == 2. ? zadd(zpow(z,vec2(3.,acos(-1.))),vec2(1.,.0)) :
         // tan(z^3) / z^2
         t == 3. ? zdiv(ztan(zpow(z,3.)),zpow(z,2.)) :
         // tan ( sin (z) )
         t == 4. ? ztan(zsin(z)) :
         // sin ( 1 / z )
         t == 5. ? zsin(zdiv(vec2(1.,.0),z)) :
         // the usual coloring methods for the mandelbrot show the outside. 
         // this technique allows to see the structure of the inside.
         t == 6. ? mandelbrot(zsub(z,vec2(1.,.0))) : 
         // the julia set 
         t == 7. ? julia(z) :
         //https://en.m.wikipedia.org/wiki/Lambert_series
         t == 8. ? lambert(z) :
         // this is the Riemman Zeta Function (well, at least part of it... :P)
         // if you can prove that all the zeros of this function are 
         // in the 0.5 + iy line, you will win:
         // a) a million dollars ! (no, really...)
         // b) eternal fame and your name will be worshiped in history books
         // c) you will uncover the deep and misterious connection between PI and the primes
         // https://en.m.wikipedia.org/wiki/Riemann_hypothesis
         // https://www.youtube.com/watch?v=rGo2hsoJSbo
         zeta(zadd(z,vec2(8.,.0)));
   
 
    return toCarte(fz);  
}

vec3 color(vec2 uv) {
    float a = atan(uv.y,uv.x);
    float r = length(uv);
    
    vec3 c = .5 * ( cos(a*vec3(2.,2.,1.) + vec3(.0,1.4,.4)) + 1. );

    return c * smoothstep(1.,0.,abs(fract(log(r)-time*.1)-.5)) // modulus lines
             * smoothstep(1.,0.,abs(fract((a*7.)/3.14+(time*.1))-.5)) // phase lines
             * smoothstep(11.,0.,log(r)) // infinity fades to black
             * smoothstep(.5,.4,abs(fract(speed)-.5)); // scene switch
}

void main(void) {
     vec2 uv = (gl_FragCoord.xy - resolution.xy *.5)/resolution.y;
     glFragColor = vec4( color(map(uv)), 1.0 );
}
