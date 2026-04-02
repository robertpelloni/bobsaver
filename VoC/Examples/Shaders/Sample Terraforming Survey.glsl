#version 420

// original https://www.shadertoy.com/view/7lsXWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ANY and ALL adulation belongs to IQ, and his new sphere noise.
// read about it here: https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
// see it in action in his shadertoy here: https://www.shadertoy.com/view/3dGSWR

float rnd ( float t ) {
  return fract( sin(t * 1841.63623 + 2714.23423));

}
vec2 unit ( float t ) {
  float a =  fract( sin(t * 1841.63623 + 2714.23423))* 324.114;
  float x = cos(a);
  float y = sin(a);
  return vec2(x,y);

}
float box (vec3 p, vec3 s) {
  p = abs(p) -s ;
  return max(p.x,max(p.y,p.z));
}

vec3 repeat(vec3 p, vec3 s) {
  return (fract(p/s-0.5)-0.5)*s;
}

vec2 repeat(vec2 p, vec2 s) {
  return (fract(p/s-0.5)-0.5)*s;
}

float repeat(float p, float s) {
  return (fract(p/s-0.5)-0.5)*s;
}

float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
} 
float sph(vec3 p, float r){
  return length(p) - r;
}
float sph( vec3 i, vec3 f, vec3 c )
{
    // random radius at grid vertex i+c (please replace this hash by
    // something better if you plan to use this for a real application)
    vec3  p = 17.0*fract( (i+c)*0.3183099+vec3(0.11,0.17,0.13) );
    float w = fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
    float r = 0.7*w*w;
    // distance to sphere at grid vertex i+c
    return length(f-c) - r; 
}

// NuSan's improvement
float sdBase(in vec3 p) {
return length(fract(p)-0.5)-(0.3+dot(sin(p*vec3(2.21,1.13,1.7)),vec3(.2)));
}
/*
float sdBase( in vec3 p )
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    return min(min(min(sph(i,f,vec3(0,0,0)),
                       sph(i,f,vec3(0,0,1))),
                   min(sph(i,f,vec3(0,1,0)),
                       sph(i,f,vec3(0,1,1)))),
               min(min(sph(i,f,vec3(1,0,0)),
                       sph(i,f,vec3(1,0,1))),
                   min(sph(i,f,vec3(1,1,0)),
                       sph(i,f,vec3(1,1,1)))));
}
*/
float tick( float t ) {
  float i = floor(t);
  float r = fract(t);
  
  for ( int n = 0; n < 4; n++) {
    r = smoothstep(0.,1.,r);
  }
  return i + r;
}
vec2 sdFbm( in vec3 p, in float th, in float d )
{
    // rotation and 2x scale matrix
    const mat3 m = mat3( 0.00,  1.60,  1.20,
                        -1.60,  0.72, -0.96,
                        -1.20, -0.96,  1.28 );
    vec3  q = p;
    float t = 0.0;
    float s = 1.0;
    const int ioct = 11;
    for( int i=0; i<ioct; i++ )
    {
        if( d>s*0.866 ) break; // early exit
        if( s<th ) break;      // lod
        
        float n = s*sdBase(q);
        float porous = mix(0.02,0.2,sin(time/10.)*.5+0.5);  // default 0.1;
        float y = 0.3;//(sin(time/24.) * 0.5 + 0.5) * .3 + .1;
        n = smax(n,d-porous*s,y*s); // default 0.3
        d = smin(n,d      ,y*s);    // default 0.3
        q = m*q;
        s = 0.415*s;
     
        t += d; 
        q.z += -4.33*t*s; // deform things a bit
    }
    return vec2( d, t );
}    

float fbm( in vec2 p )
{
    float f = 0.0;
    float s = 0.5;
    for( int i=0; i<11; i++ )
    {
        float n = 0;//texture(iChannel1,p).x;
        f += s*n;
        p *= 2.01*mat2(4.0,-3.0,3.0,4.0)/5.0;
        s *= 0.55;
    }
    return f;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(0.0, cos(cr),sin(cr));
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//=========================================

const float precis = 0.0005;  // default 0.0005

float cyl(vec2 p, float r) {
  return length(p) - r;
}

vec2 off ( vec3 p) {
  return vec2(sin(p.x/3.0), cos(p.y/4.1));
}
float layer (vec3 p, float r ) {
  return length(p) -r ;
}
vec3 ro;
vec3 ta;
vec2 map( in vec3 p, in float dis )
{
    
   
    float spot = sph(p - ro   - vec3(0,0,2), .01); 
    
    p.y *= .5; // default 1.0
    // ground
    float d = length(p-vec3(0.0,-250.0,0.0))-250.0;
    d = p.y;
    // terrain
    vec2 dt = sdFbm( p, dis*precis, d );
   
    //float hole = box(p - ro, vec3(1.));
    //dt.x = max(dt.x, -hole);
    dt.x = min(dt.x, spot);
    return dt;
}

vec3 calcNormal( in vec3 pos, in float t )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*precis*t;
    return normalize( e.xyy*map( pos + e.xyy, t ).x + 
                      e.yyx*map( pos + e.yyx, t ).x + 
                      e.yxy*map( pos + e.yxy, t ).x + 
                      e.xxx*map( pos + e.xxx, t ).x );
}

mat2 rot ( float a ) {
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca, sa, -sa, ca);
}
vec3 jump( float t ) {
  float sc = 4.;
  float y = sin(time);
  vec2 a = unit(floor(t)) *sc *y;;
  vec2 b = unit(floor(t)+1.)*sc*y;
  
  float height = 5.6 + sin(time);
  return ( mix( vec3(a.x, height,a.y), vec3(b.x,height,b.y), fract(t)));  

}

vec2 offset (float t ) {
  
  t /= 1.;
  float a = cos(t) + cos(t*2.1)/2.3 + cos(t*4.2)/ 4.1;
  float b = cos(t*1.1) + cos(t*1.9)/1.7 + cos(t*4.)/ 3.6;
 
  
 
  return vec2(a,b)/10.;

}

float getsss(vec3 p, vec3 r, float dist) {
  return clamp(map(p+r*dist,1.).x*3.0,0.0,1.0);
}

void main(void)
{
   
    
 
    vec2 p = (2.0*(gl_FragCoord.xy)-resolution.xy)/ resolution.y;

       
    float time = time * 1.3;

    // scene setup
  
    float cr, fl, fad;
    
  
    float n = time;
   
 
    float tt = time * .43;
    
 
    vec3 pole = vec3( cos(tt), 0., sin(-tt) )* 1.2;
   
    ro = vec3(offset(n), tt);
    ta = vec3(offset(n+1.), tt +2.*sin(time/4.1));
    ro.y +=.5;
    ro += pole;
    ta += pole;
    
    
   
    

    
    // camera matrix    
    mat3 ca = setCamera( ro, ta, cr );
    
    vec3 rd = ca * normalize( vec3(p.xy,2.0));
    
   

  

    // raymarch
    float t = 0.;
    vec2 h = vec2(0.0,0.0);
    bool hit = false;
    vec3 pos;
    float dd;
    float i;
    for( i=0.; i<300.; i++ )
    {
        pos = ro + t*rd;
        float flip = sign(map(pos,t).x);
        h = map( pos, t )*flip;
        if( abs(h.x)<.0001) {//(precis*t)) {
          
          hit = true;
          break;
        }
       if (t>300.0 ) {
          break;
       }
       t += h.x   * 1.; // overstepping
       dd += t;
    }
   
    
   
    vec3 nor = calcNormal( pos, t );
    vec3 light = normalize(vec3(1,0,3));
    light.xz *= rot(time*.31);
    
    float shade = dot(nor,light) + .45; 
    float ao = pow(1. - i/300.,8.);
    
    float spec= pow(max(dot(reflect(light,nor),-rd),.0), 17.);
    //float sss = getsss(ro,rd,1.2);
    vec3 col = vec3(1.,.5,.3);
    col *= pow(shade,1.2);
    col *= pow(ao,1.2) ;
    //col += spec  ;
    //col *= sss * 20.;
    
    float spot = length(pos - ((ro + vec3(0.,0.,2.))  ));
    
    
    col += .001/pow(spot,10.) * vec3(.6,.5,1);
   
  
    
    if (! hit) {
      col = vec3(.9,.2,.1) * rd.y/.4; 
    }
    
    // fog
    col = mix(col, vec3(.3), i/2000.);
  
  
   
    col = pow(col,vec3(.35));
    
  
    glFragColor = vec4( col, 1.0 );

}
