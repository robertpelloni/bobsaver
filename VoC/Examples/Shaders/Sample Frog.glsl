#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dcBRr

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1

mat3 rotate_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rotate_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rotate_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdCone( in vec3 p, in vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}
float sdEllipsoid( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float sdCappedCone( vec3 p, float h, float r1, float r2 )
{
  vec2 q = vec2( length(p.xz), p.y );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
    //float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    //return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
    //float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    //return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}
vec2 map( in vec3 p, float atime )
{
    
    
    p.z-=0.3;
    
    vec3 pc=p;
    p.y+=0.01;
    vec3 p1=p;
    vec3 p2=p;
    vec3 p3=vec3(p.x,p.y,abs(p.z));
    
    vec3 p4=vec3(p.x,p.y,abs(p.z));
    p4/=vec3(0.2);
    p4+=vec3(-0.9,0.3,-1.4);
    p4*=rotate_x(2.2);
    p4*=rotate_z(-0.4);
    
    
    vec3 p8=vec3(p.x,p.y,abs(p.z));
    p8/=vec3(0.2);
    p8+=vec3(-0.9,0.3,-1.4);
    p8*=rotate_x(1.5);
    p8*=rotate_z(-0.2);
    p8*=rotate_y(0.4);
    
    vec3 p9=vec3(p.x,p.y,abs(p.z));
    p9/=vec3(0.2);
    p9+=vec3(-1.5,0.7,-1.4);
    p9*=rotate_x(1.5);
    p9*=rotate_z(-0.2);
    p9*=rotate_y(0.4);
    
    
    vec3 p10=vec3(p.x,p.y,abs(p.z));
    p10/=vec3(0.15);
    p10+=vec3(-2.7,1.0,-1.8);
    p10*=rotate_x(1.5);
    p10*=rotate_z(-0.2);
    p10*=rotate_y(0.4);
    
    vec3 p12=vec3(p.x,p.y,abs(p.z));
    p12/=vec3(0.1);
    p12+=vec3(-4.5,0.8,-2.8);
    p12*=rotate_x(1.5);
    p12*=rotate_z(-0.2);
    p12*=rotate_y(0.4);
    
    
    vec3 p5=vec3(p.x,p.y,abs(p.z));
    p5/=vec3(0.2);
    p5+=vec3(0.5,0.9,-1.3);
    p5*=rotate_x(2.2);
    p5*=rotate_z(-0.4);
 
    
    
    vec3 p6=vec3(p.x,p.y,abs(p.z));
    p6/=vec3(0.2);
    p6+=vec3(0.0,1.3,-1.6);
    p6*=rotate_x(1.5);
    p6*=rotate_y(0.3);
    p6*=rotate_y(0.5);
    
    
    vec3 p7=vec3(p.x,p.y,abs(p.z));
    p7/=vec3(0.2);
    p7+=vec3(0.3,1.85,-1.6);
    p7*=rotate_x(1.5);
   
    p7*=rotate_y(0.1);
    
    
    vec3 p11=vec3(p.x,p.y,abs(p.z));
    p11/=vec3(0.2);
    p11+=vec3(0.55,2.1,-1.6);
    p11*=rotate_x(1.5);
   
    p11*=rotate_y(-1.3);
    
    
    vec3 p13=vec3(p.x,p.y,abs(p.z));
    p13/=vec3(0.12);
    p13+=vec3(-0.0,3.8,-2.8);
    p13*=rotate_x(1.5);
   
    p13*=rotate_y(-1.3);
    
    p3+=vec3(-0.2,-0.25,-0.1);

    p2+=vec3(0.45,0.15,0.0);
    
    p2*=rotate_z(-1.4);
    
    
    float body= sdEllipsoid(p1,vec3(0.3,0.32,0.3));
    float rabo=sdRoundCone(p2,0.05,0.2,0.3);
    float olho=sdSphere(p3,0.08);
    float irisC=sdSphere(p3+vec3(-0.1,0.0,0.0),0.05);
    float irisN=sdSphere(p3+vec3(-0.0,0.0,0.0),0.07);
    float irisN2=sdSphere(p3+vec3(-0.035,0.0,0.0),0.04);
    float braco1= sdCappedCone(p4,0.1,0.15,0.2)*0.2;
    float braco2= sdEllipsoid(p8,vec3(0.5,0.2,0.2))*0.2;
    float braco3= sdEllipsoid(p9,vec3(0.5,0.2,0.2))*0.2;
    float perna1= sdCappedCone(p5,0.1,0.15,0.2)*0.2;
    float perna2=sdEllipsoid(p6,vec3(0.8,0.2,0.4))*0.2;
    float perna3=sdEllipsoid(p7,vec3(0.5,0.2,0.2))*0.2;
    float mao1= sdEllipsoid(p10,vec3(0.2,0.2,0.25))*0.2;
    float pe1= sdEllipsoid(p11,vec3(0.15,0.3,0.3))*0.2;
    float dedo1= sdEllipsoid(p12,vec3(0.1,0.1,0.15))*0.1;
    float dedo2= sdEllipsoid(p12+vec3(0.0,0.5,0.0),vec3(0.1,0.1,0.15))*0.1;
    float dedo3= sdEllipsoid(p12+vec3(0.0,1.0,-0.3),vec3(0.1,0.1,0.15))*0.1;
    
    float dedoPe1= sdEllipsoid(p13,vec3(0.1,0.1,0.15))*0.1;
    float dedoPe2= sdEllipsoid(p13+vec3(0.0,0.5,0.0),vec3(0.1,0.1,0.15))*0.1;
    float dedoPe3= sdEllipsoid(p13+vec3(0.0,-0.5,0.0),vec3(0.1,0.1,0.15))*0.1;
    
    float boca1=sdCappedCylinder(p+vec3(-0.25,0.0,0.0),0.2,0.001);
    
    
  
    
    body=opSmoothSubtraction(boca1,body,0.02);

    
    body=opSmoothUnion(dedoPe1,body,0.05);
    body=opSmoothUnion(dedoPe2,body,0.05);
    body=opSmoothUnion(dedoPe3,body,0.05);
    
    body=opSmoothUnion(dedo3,body,0.05);
    body=opSmoothUnion(dedo2,body,0.05);
    body=opSmoothUnion(dedo1,body,0.05);
    
    
    body=opSmoothUnion(pe1,body,0.1);
    
    body=opSmoothUnion(mao1,body,0.1);
    
    body=opSmoothUnion(perna1-0.01,body,0.1);
    
    body=opSmoothUnion(perna2,body,0.05);
    
    body=opSmoothUnion(perna3,body,0.035);
    
    body=opSmoothUnion(braco1-0.01,body,0.1);
    body=opSmoothUnion(braco2,body,0.05);
    body=opSmoothUnion(braco3,body,0.1);
    
    olho=opSmoothSubtraction(irisC,olho,0.1);
    olho=min(irisN,olho);
    
     
    
    body=min(body,olho);
    
    body=opSmoothUnion(rabo,body,0.1);
    
    vec2 res = vec2( body, 1.0 );
    res = opU(res,vec2(irisN,2.0));
    res = opU(res,vec2(irisN2,2.5));
    res = opU(res,vec2(pc.y+0.5,3.5));

    
    
    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd, float time )
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 0.5;
    float tmax = 20.0;
    
    float t = tmin;
    for( int i=0; i<512 && t<tmax; i++ )
    {
        vec2 h = map( ro+rd*t, time );
        if( h.x<0.001 )
        { 
            res = vec2(t,h.y); 
            break;
        }
        t += h.x;
    }
    
    return res;
}

vec3 calcNormal( in vec3 pos, float time )
{
/*
    vec2 e = vec2(0.0005,0.0);
    return normalize( vec3( 
        map( pos + e.xyy, time ).x - map( pos - e.xyy, time ).x,
        map( pos + e.yxy, time ).x - map( pos - e.yxy, time ).x,
        map( pos + e.yyx, time ).x - map( pos - e.yyx, time ).x ) );
*/
    vec3 n = vec3(0.0);
    for( int i=min(frames,0); i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e,time).x;
    }
    return normalize(n);    
}

float calcOcclusion( in vec3 pos, in vec3 nor, float time )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos, time ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 render( in vec3 ro, in vec3 rd, float time )
{ 
    // sky dome
    vec3 col = vec3(0.5, 0.8, 0.9) - max(rd.y,0.0)*0.5;
    
    vec2 res = castRay(ro,rd, time);
    if( res.y>-0.5 )
    {
        float t = res.x;
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos, time );
        vec3 ref = reflect( rd, nor );
        
        col = vec3(0.2);
        float ks = 1.0;

        if( res.y==3.5 ) // eyeball
        { 
            col = vec3(0.4,0.5,0.6);
        } 
        else if( res.y==2.5 ) // iris
        { 
            col = vec3(0.0);
        } 
        else if( res.y==2.0 ) // body
        { 
            col = vec3(1.0);
        }
        else // terrain
        {
            col = vec3(0.05,0.09,0.02);
        }
        
        // lighting
        vec3  sun_lig = normalize( vec3(0.6, 0.35, 0.5) );
        float sun_dif = clamp(dot( nor, sun_lig ), 0.0, 1.0 );
        vec3  sun_hal = normalize( sun_lig-rd );
        float sun_sha = step(castRay( pos+0.001*nor, sun_lig,time ).y,0.0);
        float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
        float sky_dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float bou_dif = sqrt(clamp( 0.1-0.9*nor.y, 0.0, 1.0 ))*clamp(1.0-0.1*pos.y,0.0,1.0);

        vec3 lin = vec3(0.0);
        lin += sun_dif*vec3(8.10,6.00,4.20)*sun_sha;
        lin += sky_dif*vec3(0.50,0.70,1.00);
        lin += bou_dif*vec3(0.40,1.00,0.40);
        col = col*lin;
        col += sun_spe*vec3(8.10,6.00,4.20)*sun_sha;
        
        col = mix( col, vec3(0.5,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

#define ZERO (min(frames,0))
void main(void)
{
    
         vec3 tot = vec3(0.0);

    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5; 
    
    
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy+o)/resolution.y;
    float time = time;

    time *= 0.9;

    // camera    
    float an = 10.57*mouse.x*resolution.xy.x/resolution.x;
    vec3  ta = vec3( 0.0, 0.0, 0.4);
    vec3  ro = ta + vec3( 1.3*cos(an), -0.250, 1.3*sin(an) );

    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 rd = ca * normalize( vec3(p,1.8) );

    vec3 col = render( ro, rd, time );

    col = pow( col, vec3(0.4545) );

    tot += col;
    }
     tot /= float(AA*AA);
    glFragColor = vec4(tot,1.0);
}
