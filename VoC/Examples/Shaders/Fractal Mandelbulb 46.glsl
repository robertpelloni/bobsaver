#version 420

// original https://www.shadertoy.com/view/WsGyRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANIMATE 0
#define MAX_STEPS 255
#define MIN_DIST 0.0
#define MAX_DIST 100.0
#define EPSILON 0.0001
#define AA 3

float dot2(in vec2 v) { return dot(v,v); }

/* SIGNED DISTANCE FUNCTIONS */
// ============================================================== //
float sphereSDF(vec3 p,  float r) 
{
    return length(p) - r;
}

float boxSDF(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y,q.z)), 0.0);
}

float roundBoxSDF(vec3 p, vec3 b, float r)
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.x)),0.0) - r;
}

float boundingBoxSDF( vec3 p, vec3 b, float e )
{
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float torusSDF(vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float cappedTorusSDF(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float linkSDF( vec3 p, float le, float r1, float r2 )
{
  vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
  return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float cylinderSDF( vec3 p, vec3 c )
{
  return length(p.xz - c.xy)-c.z;
}

float coneSDF( in vec3 p, in vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp(w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y - w.y*q.x), k*(w.y - q.y));
  return sqrt(d) * sign(s);
}

float infConeSDF( vec3 p, vec2 c )
{
    vec2 q = vec2( length(p.xz), -p.y );
    float d = length( q - c*max(dot(q,c), 0.0) );
    return d*( (q.x*c.y - q.y*c.x < 0.0) ? -1.0 : 1.0);
}

float planeSDF( vec3 p, vec3 n, float h )
{
  // n must be normalized!!
  return dot(p,n) + h;
}

float sdfHexPrime( vec3 p, vec2 h )
{
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float triPrismSDF( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.z - h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float capsuleSDF( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a;
  vec3 ba = b - a;
  float h = clamp( dot(pa,ba) / dot(ba,ba), 0.0, 1.0 );
  return length(pa - ba*h) - r;
}

float cappedCylinderSDF( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float roundCylinderSDF( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float cappedConeSDF( vec3 p, float h, float r1, float r2 )
{
  vec2 q = vec2( length(p.xz), p.y );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float roundConeSDF( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

// NOTE: approximation
float ellipsoidSDF( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p / (r*r));
  return k0*(k0 - 1.0)/k1;
}

float octahedronSDF( vec3 p, float s)
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

float pyramidSDF( vec3 p, float h)
{
  float m2 = h*h + 0.25;
    
  p.xz = abs(p.xz);
  p.xz = (p.z > p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
   
  float s = max(-q.x,0.0);
  float t = clamp( (q.y - 0.5*p.z)/(m2 + 0.25), 0.0, 1.0 );
    
  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    
  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}

float mandelbulb(vec3 pos) {
    float Power = 3.0 + 5.0;
    float ThetaShift = time * .2;
    float PhiShift = time * .2;
    
    if(length(pos) > 1.5) return length(pos) - 1.2;
    vec3 z = pos;
    float dr = 1.0, r = 0.0, theta, phi;
    for (int i = 0; i < 15; i++) {
        r = length(z);
        if (r>1.5) break;
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        theta = acos(z.z/r) * Power + ThetaShift;
        phi = atan(z.y,z.x) * Power + PhiShift;
        float sinTheta = sin(theta);
        z = pow(r,Power) * vec3(sinTheta*cos(phi), sinTheta*sin(phi), cos(theta)) + pos;
    }
    return 0.5*log(r)*r/dr;
}

// Combinations
float unionOp(float d1, float d2) { return min(d1,d2); }
vec2 unionOp(vec2 d1, vec2 d2) { return (d1.x<d2.x) ? d1 : d2; }
float subtractOp(float d1, float d2) { return max(-d1,d2); }
vec2 subtractOp(vec2 d1, vec2 d2) { return (-d1.x > d2.x) ? -d1 : d2; }
float intersectOp(float d1, float d2) { return max(d1,d2); }
vec2 intersectOp(vec2 d1, vec2 d2) { return (d1.x > d2.x) ? d1 : d2; }

float smoothUnionOp( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}
vec2 smoothUnionOp( vec2 d1, vec2 d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2.x-d1.x)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float smoothSubOp( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

vec2 smoothSubOp( vec2 d1, vec2 d2, float k ) 
{
    float h = clamp(0.5 - 0.5*(d2.x + d1.x)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0 - h); 
}

float smotherIntersectOp( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2 - d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0 - h); 
}

vec2 smotherIntersectOp( vec2 d1, vec2 d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2.x - d1.x)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*h*(1.0 - h); 
}

/* Experimental smooth minimum function s*/
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

// polynomial smooth min (k = 0.1);
float sminA( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

// polynomial smooth min (k = 0.1);
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

// power smooth min (k = 8);
float sminB( float a, float b, float k )
{
    a = pow( a, k ); b = pow( b, k );
    
    
    return pow( (a*b)/(a+b), 1.0/k );
}

/* Transformations */

// rotation and scaling
vec3 linearTOp(vec3 p, mat4 transform)
{
    return (inverse(transform)*vec4(p,1.0)).xyz;
}

vec3 translateOp(vec3 p, vec3 h)
{
    return p - h;
}

// NOTE: YOU MUST MULTIPLY RESULTING DISTANCE BY 's'
vec3 scaleOp(vec3 p, float s)
{
    return p / s;
}

/* Deformations */

// Displacement: SDF(p) + displace(p)

// ALTERATIONS

vec4 elongateOP(vec3 p, vec3 h)
{
    vec3 q = abs(p)-h;
    return vec4( max(q,0.0), min(max(q.x,max(q.y,q.z)),0.0));
}

float roundOp(float d, float h)
{
    return d - h;
}

vec3 twistOp(vec3 p, float k)
{
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2 m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
    
}

vec3 bendOp(vec3 p)
{
    const float k = 10.;
    float c =  cos(k*p.x);
    float s = sin(k*p.x);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m*p.xy, p.z);
}

// ============================================================== //
// PLAY WITH CODE HERE
// ============================================================== //

/* SDF FOR THE ENTIRE SCENE */

vec2 map(vec3 p)
{
    vec2 result = vec2(1e10, 0.0);
    {
        // PLANE COLOR CODE MUST BE < 1.5
        result = unionOp(result, vec2(mandelbulb(p), 4.1)); 
}
    
    return result;
}

const float sunIntensity = 1.2;
const vec3 sunColor = sunIntensity*vec3(1.30,1.00,0.60);

vec3 background(vec3 q)
{
    return mix( vec3(0.3,0.3,0.8)*0.5, vec3(0.6, 0.8, 1.0), 0.7 + 0.5*q.y );
}

// ============================================================== //

// intersect ray with the scene
vec2 raycast(vec3 ro, vec3 rd)
{
    vec2 result = vec2(-1.0);
    float t = MIN_DIST;
    for (int i =0; i < MAX_STEPS && t < MAX_DIST; i++) {
        vec2 h = map(ro + t*rd);
        if (abs(h.x) < (EPSILON*t)) {
            result = vec2(t, h.y);
            break;
        }
        t += h.x;
    }
    
    return result;
}

// get direction of ray with just device coordinates
vec3 rayDirection(float fieldOfView, vec2 size, vec2 d) {
    vec2 xy = d - size / 2.;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

// calculate the normal via finite differences
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
                      e.yyx*map( pos + e.yyx ).x + 
                      e.yxy*map( pos + e.yxy ).x + 
                      e.xxx*map( pos + e.xxx ).x );
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    // bounding volume
    float tp = (0.8-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = mint;
    for( int i=0; i<24; i++ )
    {
        float h = map( ro + rd*t ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 light = normalize( vec3(-0.5, 0.4, 0.6) );

vec3 render(vec3 ro, vec3 rd, vec3 rdx, vec3 rdy)
{
    // background
    vec3 col = background(rd);
    
    vec2 tmat = raycast(ro, rd);
    float t = tmat.x;
    float m = tmat.y;
    if (m > -1.) {
    
        
        col = 0.2 + 0.2*sin( m*2.0 + vec3(0.0,1.0,2.0) );
        float ks = 1.0;
    
        vec3 pos = ro + tmat.x*rd;
        vec3  hal = normalize(light - rd );
        vec3 norm = (m < 1.5) ? vec3(0.0,1.0,0.0) : calcNormal( pos );
        vec3 ref = reflect( rd, norm );
        
        if( m<1.5 )
        {
            // project pixel footprint into the plane
            //vec3 dpdx = ro.y*(rd/rd.y-rdx/rdx.y);
            //vec3 dpdy = ro.y*(rd/rd.y-rdy/rdy.y);

            col = vec3(0.30);
            ks = 0.1;
        }
        
        float occ = calcAO(pos, norm); 
        vec3 lin = vec3(0.0);
        
        // sun
        {
            vec3  hal = normalize( light-rd );
            float dif = clamp( dot( norm, light ), 0.0, 1.0 );
                  dif *= calcSoftshadow( pos, light, 0.02, 2.5 );
            float spe = pow( clamp( dot( norm, hal ), 0.0, 1.0 ),16.0);
                  spe *= dif;
                  spe *= 0.04+0.16*pow(clamp(1.0-dot(hal,light),0.0,1.0),2.0);
            lin += col*2.20*dif*sunColor;
            lin +=     5.00*spe*sunColor*ks;
        }
        
        // sky
        {
            float dif = sqrt(clamp( 0.5+1.5*norm.y, 0.0, 1.0 ));
            dif *= occ;
            float spe = smoothstep( -0.2, 0.2, ref.y );
            spe *= dif;
            spe *= 0.04+0.96*pow(clamp(1.0+dot(norm,rd),0.0,1.0), 5.0 );
            spe *= calcSoftshadow( pos, ref, 0.02, 4.2 );
            lin += col*0.70*dif*background(rd);
            lin +=     1.30*spe*background(rd)*ks;
        }
        col = lin;

        // falloff (fakes a depth blur)
        col = mix( col, vec3(0.7,0.7,0.9), 1.0-exp( -0.00002*t*t*t ) );
    }
    
    return vec3( clamp(col,0.0,1.0) );
}

void main(void) {

    vec3 tot = vec3(0.);
    for (int m =0; m < AA; m++)
    for (int n =0; n < AA; n++)
    {
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec3 viewDir = rayDirection(45.0, resolution.xy, gl_FragCoord.xy + o);
        vec3 eye = vec3(-2.0, 3.0, 6.0);
        
        mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    
        vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
          // ray derivatives
        vec2 px = (2.0*(gl_FragCoord.xy+vec2(1.0,0.0))-resolution.xy)/resolution.y;
        vec2 py = (2.0*(gl_FragCoord.xy+vec2(0.0,1.0))-resolution.xy)/resolution.y;
        vec3 rdx = (viewToWorld * normalize( vec4(px,2.5, 1.0) )).xyz;
        vec3 rdy = (viewToWorld * normalize( vec4(py,2.5, 1.0) )).xyz;
    
        vec3 col = render(eye, worldDir, rdx, rdy);
        tot += col;
    
    }
    
    tot /= float(AA*AA);

    glFragColor = vec4(tot, 1.0);
}
