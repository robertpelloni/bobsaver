#version 420

// original https://www.shadertoy.com/view/Wds3Wn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    

// A list of useful distance function to simple primitives, and an example on how to 
// do some interesting boolean operations, repetition and displacement.
//
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

//------------------------------------------------------------------

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdEllipsoid( in vec3 p, in vec3 r ) // approximated
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
    
}

float sdRoundBox( in vec3 p, in vec3 b, in float r ) 
{
    vec3 q = abs(p) - b;
    return min(max(q.x,max(q.y,q.z)),0.0) + length(max(q,0.0)) - r;
}

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 1
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x),
       p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
#endif    
#if 0    
    float d1 = q.z-h.y;
    float d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#endif
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdRoundCone( in vec3 p, in float r1, float r2, float h )
{
    vec2 q = vec2( length(p.xz), p.y );
    
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(q,vec2(-b,a));
    
    if( k < 0.0 ) return length(q) - r1;
    if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
    return dot(q, vec2(a,b) ) - r1;
}

float sdEquilateralTriangle(  in vec2 p )
{
    const float k = 1.73205;//sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = vec2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x += 2.0 - 2.0*clamp( (p.x+2.0)/2.0, 0.0, 1.0 );
    return -length(p)*sign(p.y);
}

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    float d1 = q.z-h.y;
    h.x *= 0.866025;
    float d2 = sdEquilateralTriangle(p.xy/h.x)*h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float dot2( in vec2 v ) { return dot(v,v); }
float sdCappedCone( in vec3 p, in float h, in float r1, in float r2 )
{
    vec2 q = vec2( length(p.xz), p.y );
    
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2-r1,2.0*h);
    vec2 ca = vec2(q.x-min(q.x,(q.y < 0.0)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdPryamid4(vec3 p, vec3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    float box = sdBox( p - vec3(0,-2.0*h.z,0), vec3(2.0*h.z) );
 
    float d = 0.0;
    d = max( d, abs( dot(p, vec3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y,-h.x )) ));
    float octa = d - h.z;
    return max(-box,octa); // Subtraction
 }

float length2( vec2 p )
{
    return sqrt( p.x*p.x + p.y*p.y );
}

float length6( vec2 p )
{
    p = p*p*p; p = p*p;
    return pow( p.x + p.y, 1.0/6.0 );
}

float length8( vec2 p )
{
    p = p*p; p = p*p; p = p*p;
    return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus82( vec3 p, vec2 t )
{
    vec2 q = vec2(length2(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

float sdTorus88( vec3 p, vec2 t )
{
    vec2 q = vec2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

float sdCylinder6( vec3 p, vec2 h )
{
    return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}

//------------------------------------------------------------------

float opS( float d1, float d2 )
{
    return max(-d2,d1);
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

vec3 opTwist( vec3 p )
{
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

//------------------------------------------------------------------   
// 3D noise function (IQ)
float noise(vec3 p)
{
    vec3 ip=floor(p);
    p-=ip; 
    vec3 s=vec3(7,157,113);
    vec4 h=vec4(0.,s.yz,s.y+s.z)+dot(ip,s);
    p=p*p*(3.-2.*p); 
    h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy=mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z); 
}

//------------------------------------------------------------------   
 
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//
// Raymarching lights within a fog experimental thingy
// Trying to use distance fields for lights.
// 

vec3 saucerpos = vec3(0.0);
vec3 carpos = vec3(0.0);

float terrain(vec3 pos){

    float s = 99999.9;
    
    float n = noise(pos.zxy*7.0);
    s = min(s,pos.y + max(0.0,(sin(n)*0.1))); // wet ground

   
    s = min(s,300.0-length(pos)); // sky
    s = min(s,sdRoundBox(pos+vec3(10,8.5+noise(pos.zxy*10.6)*0.007,0.0),vec3(3.0,3.0,40.0),6.0)); // road
    s = min(s,sdRoundBox(opRep(pos,vec3(0.0,0.0,30.0))+vec3(15.0,0.0,0.0),vec3(0.01,9.0,0.01),0.1)); // poles
    s = min(s,sdRoundBox(opRep(pos,vec3(0.0,0.0,1.5))+vec3(16.0,-1.0,0.0),vec3(0.05,1.0,0.1),0.01)); // fence
    s = min(s,max(sdEllipsoid(opRep(pos+vec3(0.0,0.0,0.0),vec3(6.0,0.0,6.0)),vec3(2.0,10.0,2.1)), 40.0 - length(pos*vec3(1.0,1.0,0.2)))); // trees
   
      

    s = min(s,sdRoundBox(pos+vec3(-10.0,1.0,0.0),vec3(15.,0.7,15.0),0.5)); // floor
   
    vec3 sym = pos;
    sym.z = abs(sym.z);
    s = min(s,sdRoundBox(sym+vec3(-20.0,-2.0,-5.0),vec3(3.,3.0,3.0),0.01)-abs(cos(pos.y*10.0))*0.01); // house
    float c = min(s,sdRoundBox(sym+vec3(-19.0,-3.3,-5.0),vec3(4.1,2.0,2.1),0.02)); // window
    s = max(-c,min(s,sdRoundBox(sym+vec3(-20.0,-3.3,-5.0),vec3(3.1,2.3,2.5),0.02))); // window
    s = min(s,sdRoundBox(sym+vec3(-18.0,-5.3,-4.0),vec3(7.,0.5,4.6),0.04)); // roof
    s = min(s,sdRoundBox(sym+vec3(-13.0,-0.5,-4.5),vec3(.3,1.9,0.3),0.3)); // pump
    
    
    // sign
    s = min(s,sdRoundBox(pos+vec3(-12.0,-9.0,0.0),vec3(2.2,2.1,0.1),0.1));
    s = min(s,sdRoundBox(pos+vec3(-12.0,-5.7,0.0),vec3(1.0,1.4,0.2),0.01));    

    
    // saucer
    vec3 fs = pos+saucerpos;
    s = min(s,sdEllipsoid(fs,vec3(3.0,1.0,3.0))); 
    s = min(s,sdEllipsoid(fs+vec3(0.0,-0.5,0.0),vec3(1.5,1.5,1.5))); 
  
    
    // car
    vec3 cp = pos+carpos+vec3(0.8,1.0,0.0);
    s = min(s,sdRoundBox(cp ,vec3(1.0,1.0,1.7),0.3)+min(0.0,sin(cp.z-2.5)*0.3)); // car
    
    return s;
}

vec4 lights(vec3 pos){
    
    
    float s = 99999.9;
    float p = 99999.9;
    float lw = 0.0;
    vec3 l = vec3(0.0);
     
   
    // street lights 
    p = length(opRep(pos,vec3(0.0,0.0,30.0))+vec3(12.0,-10.0,0.0))-0.2;
    l += vec3(2.1) / (abs(p)+1.0);
    lw += p;
    s = min(s,p); 

    
    if(mod(time,5.0)<3.0){
        // neon lamp
        
        vec3 lpos = pos+vec3(-25.1,-5.5,0.0);
        vec3 mirror = vec3(7.1,0.2,1000.0);
        lpos = abs(lpos+mirror)-mirror;
        
        p = sdRoundBox(lpos,vec3(0.01,0.01,8.0),0.05);
        l += vec3(0.0,2.0,0.0)  / (abs(p)+1.0);      
        lw += p;
        s = min(s,p); 
    }
    
    
   
    // back lamp
    vec3 sym = pos;
    sym.z = abs(sym.z);
    p = sdRoundBox(sym+vec3(-20.0,-4.4,-8.5),vec3(1.5,0.05,0.1),0.01);
    l += vec3(0.1,0.1,1.0)  / (abs(p)+1.0);      
    lw += p;
    s = min(s,p); 

    
    // shop lamp
    vec3 sym2 = pos;
    sym2.z = abs(sym2.z);
    p = sdRoundBox(sym2+vec3(-21.0,-3.0,-5.0),vec3(0.2,0.5,1.0),0.1);
    l += vec3(0.5,0.5,0.0)  / (abs(p)+1.0);      
    lw += p;
    s = min(s,p); 

    
    
    
      // roof sign
    if(mod(time,20.0)>10.0){
       p = sdRoundBox(pos+vec3(-12.0,-9.5,0.0),vec3(2.2,1.2,0.1),0.1);
        l += vec3(5.0,0.0,0.5)  / (abs(p)+1.0);  
        lw += p;
        s = min(s,p); 
    }
    
    
    // saucer
    vec3 fs = pos+saucerpos;
    p = sdEllipsoid(fs+vec3(0.0,-0.5,0.0),vec3(1.5,1.5,1.5));
    l +=  vec3(3.0,3.0,5.0) / (abs(p)+1.0)*max(0.0,sin(time));    
    lw += p;
    s = min(s,p); 

    if(mod(time,0.1)<0.05 && mod(time,5.0)< 1.0 && time > 80.0){    
        vec3 sym = pos;
        p = sdRoundBox(fs+vec3(-0.0,20.0,0.0),vec3(0.1,20.00,0.1),0.1);
        p = min(p,length(vec3(fs.x,pos.y,fs.z))-1.0);
        l += vec3(3.0,3.0,0.0)  / (abs(p)+1.0);      
        lw += p;
        s = min(s,p); 
    }
    
           
    // pump screens
    vec3 pump = pos;
    pump.z = abs(pump.z);
    p = sdRoundBox(pump+vec3(-12.5,-1.8,-4.5),vec3(0.2,0.3,0.2),0.01);
    l += vec3(0.0,0.0,1.0) / (abs(p)+1.0);;
    lw += p;
    s = min(s,p); 

       
  
    // car
    vec3 car = pos+carpos;
    car.x = abs(car.x+0.8)-0.8; 
       
    // car lamps front
    p = length(car+vec3(0.0,0.0,2.0))-0.4;    
    l += vec3(5.1,5.0,5.1) / (abs(p)+1.0);   
    lw += p;
    s = min(s,p); 
    
    // car lamps back
    p = length(car+vec3(0.0,0.0,-2.0))-0.2;
    l += vec3(5.1,0.0,0.1) / (abs(p)+1.0);;    
    lw += p;
    s = min(s,p); 

    
    return vec4(l,s);
}

void march( vec3 ro, vec3 rd, int raymarchStepsMax,  float stepSizeMax, out vec3 march_normal,  out vec3 march_pos, out vec3 march_color ){
    
  vec3 pos = ro;
    float ts = 99999.9;
    float l = 99999.9;
    vec4 ls = vec4(0.0);
    vec3 lc = vec3(0.0);
    float stepMax = stepSizeMax; 
    float t = 9999.9;
    float dist = 0.0;
    // geometry
  
    for (int i=0;i < raymarchStepsMax;i++){
        // geometry
        float ts = terrain(pos);
        vec4 ls = lights(pos);
        t = min(ts,ls.w); 
        
        // step
        float cstep = min(stepMax+dist*0.01,t);
        
        // haze
        float h = pow(noise(pos*vec3(0.2,0.3,0.1)+vec3(0.0,time*-0.2,time*0.5)),4.0)*10.0;
        l = min(l,ls.w); 
        lc += clamp(cstep/ls.w,0.0,1000.0) * ls.rgb / (1.0+h) ;
           
        // move  
        pos += rd*cstep;
        dist += cstep;
        if (abs(t) < 0.001 || dist > 150.0) break;
        
    }
    
   
    
    float raylength = distance(ro,pos);
    vec4 posl = lights(pos);
    vec3 emission = (posl.rgb * smoothstep(0.001,0.0,posl.w)) * smoothstep(200.0,0.1,raylength); //emissive pieces;
    
    vec3 haze = lc/float(raymarchStepsMax); 
    float hazer = smoothstep(0.0,50.0,raylength); // hazyness;
        
    vec3 ns = vec3(0.0,0.0,0.01);
    vec3 norm = normalize(vec3(terrain(pos+ns.zxx),terrain(pos+ns.xzx),terrain(pos+ns.xxz))-terrain(pos)); 
    
    
    float ao = smoothstep(-2.0,2.0,terrain(pos+norm*5.0))*smoothstep(-1.0,1.0,terrain(pos+norm*0.5));
    
    // lights
    vec3 lightfield = max(posl.rgb-lights(pos-(norm*0.05)).rgb,vec3(0.0));
    vec3 lightmix = lightfield*150.0*ao;
    
       
    float rough = noise(pos.xyz*vec3(3.0,3.0,1.0))*0.02;
    float road = smoothstep(sdRoundBox(pos+vec3(10,8.5,0.0),vec3(3.0,3.0,40.0),6.0),-0.8,0.2);
    vec3 col = mix(vec3(rough),vec3(0.1,0.1,0.05)+rough*1.0,road);
    
    col = col * lightmix + emission; 
    
    
    col = mix(col,haze+emission,hazer);
    
    march_normal = norm;
    march_pos = pos;
    march_color = col.rgb;
       

}

void render( vec3 ro, vec3 rd, out vec3 color )
{ 
    
    
    vec3 n1 = vec3(0.0);
    vec3 p1 = vec3(0.0);
    vec3 col = vec3(0.0);
    march(ro, rd, 80, 1.0, n1,p1,col);
    vec3 texpos = p1*0.1;
    float texup = max(0.0,n1.y);
    float n = noise(texpos.xyz*100.0)*0.3+noise(texpos.xzz*5.0);
       
    
    vec3 n2 = vec3(0.0);
    vec3 p2 = vec3(0.0);
    vec3 col2 = vec3(0.0);
    march( p1 +(n1*0.01), reflect(rd,n1), 30, 100.0 ,n2,p2,col2);  
    
    
    vec3 col3 = col2*smoothstep(-0.2,1.3,n)*texup;
    float ref = smoothstep(0.3,0.55,noise(p1.xyz*vec3(0.5,0.001,0.3)));
    
    col += col3*0.03*ref;
    color = col+(ref*0.001*step(p1.y,0.5));
     
    
}

void main(void)
{
    vec2 mo = vec2(0.0);//mouse.xy*resolution.xy.xy/resolution.xy;
    float time2 = 10.0 + time;
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;

    // camera    
    float dist = 25.0 + (smoothstep(10.0,0.0,time)*30.0);
    float height = 3.0 + (smoothstep(10.0,0.0,time)*30.0);
    
    float rotime = time2 + (smoothstep(0.0,15.0,time)*30.0);
    vec3 ro = vec3( 10.0 +dist*cos(0.1*rotime + 6.0*mo.x), height + dist*mo.y, 0.5 + dist*sin(0.1*rotime + 6.0*mo.x) );
    vec3 ta = vec3( 1.5, 2.0, -4.0 );
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p.xy,1.8));

    float t = time2;
    saucerpos = vec3(sin(t*0.3)*20.0+30.0,sin(t*0.73)*8.0-20.0,sin(t*0.51)*16.0-15.0)-(smoothstep(40.0,30.0,t)*100.0);
    carpos = vec3(10.0,-1.5,mod(time2*30.0,800.0)-400.0);
        
    // render    
    vec3 col = vec3(0.0);
    render( ro, rd, col );    

    col = pow(col,vec3(0.44));
    col = max(vec3(0.0),col - pow(dot(p,p)*0.1,2.0));
    
    glFragColor = vec4( col,1.0);

}
