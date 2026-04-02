#version 420

// original https://www.shadertoy.com/view/tsjyWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Tile Generator v2. (WIP)" by julianlumia. https://shadertoy.com/view/Ws2cWD
// 2020-04-12 13:26:43

// Fork of "Islamic Tile Generator (WIP)" by julianlumia. https://shadertoy.com/view/tdScWD
// 2020-04-12 08:06:23

#define pi acos(-1.)
#define tau (2.*pi)
#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
#define S(a, b, t) smoothstep(a, b, t)

// inigo quilez
float sdTri(  vec2 p, float s )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - s;
    p.y = p.y + s/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdCircle( vec2 p, float r )
{
  return length(p) - r;
}

float sdOctogon( in vec2 p, in float r )
{
    const vec3 k = vec3(-0.9238795325, 0.3826834323, 0.4142135623 );
    p = abs(p);
    p -= 2.0*min(dot(vec2( k.x,k.y),p),0.0)*vec2( k.x,k.y);
    p -= 2.0*min(dot(vec2(-k.x,k.y),p),0.0)*vec2(-k.x,k.y);
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

//from iq : https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float smin( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;    
vec2 centuv = uv;
    
    
    
    
    
    
    float dp = dot(uv*4.,uv*2.)*.3;
 uv /= dp;
 uv.y=sin(uv-vec2(time*.5)).y;
    uv *= .5;
    
 vec3 col = vec3(0);
 float d = 10e6;
 float triA;
 
    uv = fract(vec2(uv.x-0.0,uv.y-.5)) -.5;
 uv *= 1.;
    vec2 cuv = uv;

 float wave =20.;
 float wavemultip = 0.05;//sin(time*0.5)*.2+0.2*.9;
 float offset = (sin(time*0.3)*2.)*0.03;
 vec2 uv2;
 vec2 objsize =vec2(abs(uv.x*1.)*.001+0.00001,5.);
 for(int i = 0; i <4; ++i)
 {
  uv = vec2((uv)*rot(float(.25)*pi));
  vec2 wpos = vec2(uv.x+sin(uv.y*wave)*wavemultip,uv.y)*1.;
  triA = sdBox(wpos+offset, objsize);
 float   triB = sdBox(wpos-offset, objsize);
 triA = min(triB, triA);       
 float   triC = sdBox(vec2(uv.x+sin(uv.y*wave-pi)*wavemultip,uv.y)-offset, objsize);
 float   triD = sdBox(vec2(uv.x+sin(uv.y*wave-pi)*wavemultip,uv.y)+offset, objsize);
 triC = min(triC, triD);
 triA = min(triC, triA);
if( triA < d)
 {
  d = triA;
  }
 } 
 float c;   
   // vec2 cuv = uv;
    
float tr6;    
float tr5;    

    
  wave =25.;
  wavemultip = 0.06;//sin(time*0.5)*.2+0.2*.9;
  offset = (sin(time*0.6)*0.5)*0.03;
  uv2;
  objsize =vec2(abs(centuv.x*3.)*.01+0.01,1.);
    for(int i = 0; i <4; ++i)
 {
  centuv = vec2((centuv)*rot(float(.25)*pi));
  vec2 wpos = vec2(centuv.x+sin(centuv.y*wave)*wavemultip,centuv.y)*1.;
  tr6 = sdBox(wpos+offset, objsize);
 float   triB = sdBox(wpos-offset, objsize);
 tr6 = min(triB, tr6);       
 float   triC = sdBox(vec2(centuv.x+sin(centuv.y*wave-pi)*wavemultip,centuv.y)-offset, objsize);
 float   triD = sdBox(vec2(centuv.x+sin(centuv.y*wave-pi)*wavemultip,centuv.y)+offset, objsize);
 triC = min(triC, triD);
 tr6 = min(triC, tr6);
if( tr6 < tr5)
 {
  tr5 = tr6;
  }
 } 
    
    
    
    
    
    
    
    
cuv*= .5;
    cuv += vec2(0.0,0.);

cuv = abs(cuv)-.2;
    for(int i = 0; i <1; ++i)
  {
cuv += vec2(-0.);

      cuv = vec2((cuv)*rot(float(.25)*pi));

cuv = abs(cuv)-.1+(offset);
     //   cuv = vec2((cuv)*rot(float(.05)*pi));
      c = sdOctogon(vec2((cuv.x)+float(i)*.2,cuv.y+float(i)*.05),.16);
      
   float c2 = c +0.001;
   c = max(c,-c2);
 if( c < d)
  {
   c = c;
  }
 } 
 float ca = sdOctogon(vec2((uv.x),uv.y),.36);
    
     float cat = sdCircle(vec2((centuv.x),centuv.y),.1);

    cat *= 1.;
 float c2a = ca -0.4;
 ca = max(ca,c2a);
    ca += .0;
// triA = min(triA,-ca);
 triA = min(triA,c);
 d = min(d, triA);
  //  cat = min(-cat,tr5);
       // cat = smin(cat,d,.5);

    d = max(d, -cat);
        cat = min(-cat,tr5);

    d = max(-d, cat);

//cat = max(cat,tr5);
 //       d = min(d, -cat);

    col += smoothstep(0.01,.001/resolution.y,-d);
 col += vec3(sin(cuv.y*1.*time)*.4,sin(cuv.y*.5*time),sin(cuv.y*0.06*time)+.0)*0.5;
 // col *= .6;
       col*=1.3;
 col=smoothstep(0.0,2.,col);
 col=pow(col, vec3(0.4545));
 glFragColor = vec4(col,1.0);
}

