#version 420

// original https://www.shadertoy.com/view/wttfDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "CyrillRayMarching starting poin3" by sylvain69780. https://shadertoy.com/view/ttVcRG
// 2021-01-21 21:18:38

// Fork of "RayMarching starting point" by BigWIngs. https://shadertoy.com/view/WtGXDD
// 2020-11-29 14:59:32

// "RayMarching starting point" 
// by Martijn Steinrucken aka The Art of Code/BigWings - 2020
// The MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
// Facebook: https://www.facebook.com/groups/theartofcode/
//
// You can use this shader as a template for ray marching shaders

#define MAX_STEPS 256
#define MAX_DIST 100.
#define SURF_DIST .001

#define S smoothstep
#define T time

// https://www.iquilezles.org/www/articles/smin/smin.htm
float smin(float a, float b, float k) {
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a, b) - h*h*h*k*(1.0/6.0);
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.x -= clamp( p.x, -h / 2.0, h / 2.0 );
  return length( p ) - r;
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

vec2 sdStick(vec3 p, vec3 a, vec3 b, float r1, float r2) // approximated
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*h ) - mix(r1,r2,h*h*(3.0-2.0*h)), h );
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 opCheapBend( in vec3 p, float k )
{
    // const float k = 10.0; // or some other amount
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xy,p.z);
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoid( in vec3 p, in vec3 r ) 
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

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

float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
    // sampling independent computations (only depend on shape)
    vec3  ba = b - a;
    float l2 = dot(ba,ba);
    float rr = r1 - r2;
    float a2 = l2 - rr*rr;
    float il2 = 1.0/l2;
    
    // sampling dependant computations
    vec3 pa = p - a;
    float y = dot(pa,ba);
    float z = y - l2;
    float x2 = dot2( pa*l2 - ba*y );
    float y2 = y*y*l2;
    float z2 = z*z*l2;

    // single square root!
    float k = sign(rr)*rr*rr*x2;
    if( sign(z)*a2*z2 > k ) return  sqrt(x2 + z2)        *il2 - r2;
    if( sign(y)*a2*y2 < k ) return  sqrt(x2 + y2)        *il2 - r1;
                            return (sqrt(x2*a2*il2)+y*rr)*il2 - r1;
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float sdHear(vec3 p) {
    p.xz *= Rot(1.6);
    
    vec3 q = p.yxz;
    float dTorus = sdTorus(q, vec2(0.15, 0.05));
    float dCylinder = sdCappedCylinder(q - vec3(0.0, -0.025, 0.0), 0.15, 0.025);
    float d = min(dTorus, dCylinder);
    return d;
}

float sdFoot(vec3 p) {
    vec3 aFoot = vec3(0.6, -0.5, -0.1);
    p.xz *= Rot(0.0);
    float dFoot1 = sdStick(p, aFoot, aFoot - vec3(0.1, 0.07, 0.4), 0.15, 0.1).x;
    float dFoot2 = sdStick(p, aFoot, aFoot - vec3(0.0, 0.07, 0.4), 0.15, 0.1).x;
    return min(dFoot1, dFoot2);
}

vec2 GetDistMat(vec3 p) {
    float m=0.0;
    float alpha = sin(time) / 10.0;
    float alphab = sin(time - 1.0) / 10.0;

    vec3 pBody = p;
    pBody.zy *= Rot(alphab);
    float dbody = sdEllipsoid(pBody-vec3(0.0,-1.0,0.0),vec3(0.65,0.5,0.5));  // body

    float dgrnd = p.y + 2.0;
    
    p = p - vec3(0.0, -0.5, 0.0);
    p.zy *= Rot(alpha);
    p = p + vec3(0.0, -0.5, 0.0);

    float dhead = sdEllipsoid(p,vec3(0.65,0.5,0.5)); // head

    float dbodyhead = smin( dhead, dbody,1.5);  // body + head

    vec3 pNose = p-vec3(0.0,-0.20,-0.56);
    // pNose.y += pNose.x * p.x;
    pNose = opCheapBend( pNose, -2.0 );
    float dNose = sdVerticalCapsule(pNose, 0.2, 0.08); // Nose

    float dTruffle = sdEllipsoid(p-vec3(0.0,-0.15,-0.61),vec3(0.07,0.05,0.05)); // Truffle

    vec3 pArm = pBody;
    pArm.x = abs(pArm.x);
    vec3 a = vec3(0.6, -0.5, -0.1);
    float dArm = sdStick(pArm, a, a - vec3(-0.3, 0.3, 0.0), 0.1, 0.15).x; // Arm

    p.x = abs(p.x);

    float dTeeth = sdBox(p-vec3(0.050,-0.30,-0.57), vec3(0.03, 0.06, 0.006)) - 0.02;

    float dhear = sdHear(p-vec3(0.50,0.30,0.15));    
    
    float deyeW = length(p-vec3(0.3,0.0,-0.4))-0.25;
    float deyeB = length(p-vec3(0.3,0.0,-0.46))-0.20;
    
    vec3 pFoot = pBody;
    pFoot.x = abs(pFoot.x);
    pFoot = pFoot - vec3(-0.25, -0.95, 0.25);
    float dFoot = sdFoot(pFoot);
    // d-min
    
    float d = min(dbodyhead, dgrnd);
    d = min(d, deyeW);
    d = min(d, deyeB);
    d = min(d, dhear);
    d = min(d, dNose);
    d = min(d, dTruffle);
    d = min(d, dTeeth);
    d = min(d, dArm);
    d = min(d, dFoot);
    
    // color
    
    if ( deyeW == d )  m = 1.0;
    if ( deyeB == d )  m = 3.0;
    if ( dgrnd == d ) m = 2.0;
    if ( dbodyhead == d ) m = 4.0;
    if ( dhear == d ) m = 4.0;
    if ( dNose == d ) m = 5.0;
    if ( dTruffle == d ) m = 3.0;
    if ( dTeeth == d ) m = 1.0;
    if ( dArm == d ) m = 4.0;
    if ( dFoot == d ) m = 5.0;

    return vec2(d,m);
}

float GetDist(vec3 p) {
    return GetDistMat(p).x;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0),f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = GetDist( opos );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

float calcSoftshadow( in vec3 ro, in vec3 rd )
{
    float mint = SURF_DIST;
    float tmax = MAX_DIST;
    int technique =1;
    float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    
    for( int i=0; i<32; i++ )
    {
        float h = GetDist( ro + rd*t );

        // traditional technique
        if( technique==0 )
        {
            res = min( res, 10.0*h/t );
        }
        // improved technique
        else
        {
            // use this if you are getting artifact on the first iteration, or unroll the
            // first iteration out of the loop
            //float y = (i==0) ? 0.0 : h*h/(2.0*ph); 

            float y = h*h/(2.0*ph);
            float d = sqrt(h*h-y*y);
            res = min( res, 10.0*d/max(0.0,t-y) );
            ph = h;
        }
        
        t += h;
        
        if( res<0.0001 || t>tmax ) break;
        
    }
    return clamp( res, 0.0, 1.0 );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 ro = vec3(0, 1, -3.0);
    //if ( mouse*resolution.xy.x > 10.0 ) {
        vec2 m = mouse*resolution.xy.xy/resolution.xy-0.5;
        ro.yz *= Rot((m.y*0.5)*3.14);
        ro.xz *= Rot(m.x*6.2831);
    //}
    vec3 rd = GetRayDir(uv, ro, vec3(0.0, -0.5, 0.0), 1.);

    vec3 col = vec3(0.4, 0.4, 0.9) * (1.0 - rd.y);
    
    float d = RayMarch(ro, rd);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        // lighing  
        float matid = GetDistMat(p).y;
        if (matid == 1.0) {
            col = vec3(0.9,0.9,0.9);
        } else if (matid == 2.0) {
            col = vec3(0.6,0.6,0.6);
        } else if (matid == 3.0) {
            col = vec3(0.05,0.05,0.05);
        } else if (matid == 4.0) {
            col = vec3(0.1,0.5,0.5);
        } else {
            col = vec3(0.8, 0.6, 0.2);
        }
        vec3 sunDir = normalize(vec3(4, 4, 3));
        // lighting terms
        float occ = calcOcclusion(p, n);
        float sha = calcSoftshadow( p, sunDir );
        float sun = clamp( dot( n, sunDir ), 0.0, 1.0 );
        float sky = clamp( 0.5 + 0.5*n.y, 0.0, 1.0 );
        float ind = clamp( dot( n, normalize(sunDir*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );

        // compute lighting
        vec3 lin  = sun*vec3(1.64,1.27,0.99)*pow(vec3(sha),vec3(1.0,1.2,1.5));
                lin += sky*vec3(0.16,0.20,0.28)*occ;
                lin += ind*vec3(0.40,0.28,0.20)*occ;

// multiply lighting and materials
        col = col * lin;        
        
        
  //      float dif = dot(n, normalize(vec3(1,2,3)))*0.5+0.5;
 //       float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
//        col *= dif;  
    }
    
    col = pow(col, vec3(.4545));    // gamma correction    
    glFragColor = vec4(col,1.0);
}
