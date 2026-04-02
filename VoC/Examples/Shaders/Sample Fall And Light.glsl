#version 420

// original https://www.shadertoy.com/view/ftcGDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/////////////////////////////////////////////////////////////
//             ...  Fall & Light ...                     ////
/////////////////////////////////////////////////////////////
// Brasil/Amazonas/Manaus
// Created by Rodrigo Cal (twitter: @rmmcal)
// - Published: 2021/11
// https://www.shadertoy.com/view/ftcGDl
//
// Fork: https://www.shadertoy.com/view/fltGDH
/////////////////////////////////////////////////////////////

const float pi = 3.1415926;
const float pi2 = 2.*pi;
const float rad = pi/180.;
float rnd ;

mat2 rotate(float x){
    float c = cos(x);
    float s = sin(x);
    return mat2(c,s,-s,c);
}
  
vec4 v(float v){
    return vec4(v, 0.,0.,0.);
}
vec4 v(float v, float v2){
    return vec4(v, v2, 0.,0.);
}

vec4 vmin(vec4 v1, vec4 v2){
    return v1.x < v2.x ? v1 : v2;
}

vec4 vmin(vec4 v1, float v2){
    return v1.x < v2 ? v1 : v(v2);
}

vec4 vmin(vec4 v1, float v2, float v3){
    return v1.x < v2 ? v1 : v(v2,v3);
}

/////////////
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
/////////////

vec4 dist(vec3 p)
{
    vec4 d = v(1.0);
    vec2 ps = ((p.xy+vec2(3., 2.)))/1.0;
    float f = .1;
    d = min(d, .075);

    vec3 c1 = vec3(.1);
    vec3 c2 = vec3(.2)*2.0;
    vec3 q = mod(p+0.5*c1,c1)-0.5*c1; 
    q.z=p.z;
    vec2 id = floor((p+0.5*c1)/c1).xy;

    float  e2 = .001+abs(fract(dot((id+cos(id.x+id.y*10.0*1.0+cos(id.x*123.0)))*179.531, vec2(11.1327,1.1323))));

    id = floor((p+0.5*c1)/c1).xy+vec2(-1,0);
    
    float at = +(-2.+2.0*fract(-e2*4.+(e2+.4)*time*0.04));
    vec4 da = d;
    d = vmin(d,  -c1.x/15.0+length(q-vec3(0.00, 0.0,1.+at ))*1.0, 1.0);

    d =   vmin(d,  sdVerticalCapsule(  (q-vec3(0,0, e2*225.  - 25.0*abs(fract((at)))  )).xzy,  .5, .001 ), 2.0) ;
  
    float wave = cos(cos(p.x*11.01) + cos((p.y+.5)*11.01)+ cos((p.x*.5+.5)*11.01+max(0.,cos(at))) + time)*.03;
    d = vmin(d, 1.- p.z + wave, 0.0);
    
    float swave = 1.90- p.z + wave;
    d = vmin(d, length(q-vec3(0.0,0.0,swave))-c1.x*e2*e2*e2/4.0 , 0.0);
   
    return d;
}

vec3 getNormal(vec3 p)
{
    vec2 d = vec2(0., 0.01);
    float x = dist(p-d.yxx).x;
    float y = dist(p-d.xyx).x;
    float z = dist(p-d.xxy).x;
    return normalize(vec3(x,y,z)-dist(p).x);
}

vec3 hsv2rgb(float v){
    return abs(fract(v + vec3(3, 2, 1) / 3.) - .5) * 6. - 1.;
}

void main(void)
{
  
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pc = (uv-.75)*vec2(1, resolution.y/resolution.x);

    vec3 p = vec3(0.);
    p += vec3(0.,-5.0,-5.);
    float sr = 5.;

    float a = time*.05 * (max(-1.0,cos(time*.25))* .005+.995 );

    p = vec3(sr*cos(a)-.85,sr*sin(a), 0.2);
    vec3 d = normalize(vec3(pc,1.0));
    d.yz *= rotate(1.341592);
    d.xy *= rotate(-a+4.63);

    vec3 c=vec3(0.0);
    float t = 0.;
    float pd = 1e19;
    vec4 hit;
    vec4 hitn;
    vec3 cadd;
    vec3 cadd2;
    float caddm = 1.; 
    for (int i = 0 ; i < 200; i++)
    {
        hit = dist(p);           // current 
        hitn = dist(p+ d*hit.x); // next 
        float h=hit.x; 
        float h2=hitn.x;
        h = (h+h2)/2.0;

        //float y = h*h/(2.0*pd);
        //float k = sqrt(h*h-y*y);
        //pd = h;
        //h = min(h, h/max(0.0, t-y));

        if (h < 0.01)
         break;
        t+=h;
        p += d*h;
        cadd += vec3(1,.5,.25)*h;
        
        caddm = min(caddm, h);
        cadd2 += vec3(1,.5,.25)/caddm;;
    }
    vec3 pn = getNormal(p);
    c += pn.z*.0;
 
  
   
    if (hit.y==0.0) {
    }
    if (hit.y==2.0) {
        c = cadd2*.5 ;
    } if (hit.y==1.0) {
        c = (pn.z*.5+.5)*(hsv2rgb(p.x+p.y+p.z)*.5+.75  ) ; 
    }
    else
        c += vec3(abs(pn.z)) *(cadd2)/(t*190.); 
    
     
    c = mix(c, c * (1.-(log(cadd))*1.0), max(0., sin(-time*.25)));
    
    
    glFragColor = vec4(c,1.0);
}
