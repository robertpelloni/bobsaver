#version 420

// original https://www.shadertoy.com/view/wtByD3

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This is a demonstration of the Gram-Schmidt orthonormalization process.
// Feel free to just copy and use the gramSchmidt() function.

// The purple vectors are the input, and the green ones are the output. 

// If you would like to play around with the positions and stuff - they are in the demoGramSchmidt() function.

// Thanks to IQ for triangle and line intersections.

#define R resolution.xy
#define T time
#define AA 4.
#define NO_INTERSECTION -1.
#define pi acos(-1.)
#define tau (2.*pi)

#define rot(j) mat2(cos(j),-sin(j),sin(j),cos(j))
#define pmod(p,j) mod(p - 0.5*j, j) - 0.5*j

// _________________________________________ //

vec3 solveQuadratic(float a, float b, float c);

vec4 intersectPlane(vec3 ro, vec3 rd, vec3 n);
vec4 intersectLine( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, float ra );
vec2 intersectCylinder( vec3 ro, vec3 rd, vec3 cb, vec3 ca, float cr );
vec4 intersectSphere(vec3 ro, vec3 rd, float r, float first);
vec4 intersectTri( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2 );

float sdBox(vec2 p, vec2 s);

vec3 getRd(vec3 ro, vec3 lookAt, vec2 uv);

vec3 hsv2rgb( in vec3 c );
vec3 rgb2hsv( in vec3 c);

// _________________________________________ //

vec4 intersectPlane(vec3 ro, vec3 rd, vec3 n){
    n = normalize(n);
    //dot(n, ro + rd*t) = 0;
    //(ro.x + rd.x*t)*n.x + (ro.y + rd.y*t)*n.y + (ro.z + rd.z*t)*n.z = 0
    //ro.x*n.x + rd.x*t*n.x + ro.y*n.y + rd.y*t*n.y + ro.z*n.z + rd.z*t*n.z = 0
    // t  = - (ro.x*n.x +  ro.y*n.y  + ro.z*n.z)/( rd.x*n.x + rd.y*n.y + rd.z*n.z ) 
    //return vec4(-(dot(ro,n))/dot(rd,n), n);
    
    float dron = dot(ro, n); 
    if(dron > 0.){
        ro -= n * dron*2.;
        rd = -rd;
    }
    
    float nominator = dot(ro,n); 
        
    float denominator = dot(rd,n);
        
    if (denominator > 1e-9) { 
        return vec4( -nominator / denominator, n); 
    
    } else {
        return vec4(NO_INTERSECTION);
    }
}

vec3 solveQuadratic(float a, float b, float c){
    // returns vec3(xa,xb,solutions)
    
    float disc = b*b - 4.*a*c;

    float xa = (-b + sqrt(disc)) / (2. * a);

    float xb = (-b - sqrt(disc)) / (2. * a);

    if(disc >= 0.){
        return vec3(xa,xb,2);
    } else {
        return vec3(0);
    }    
}

vec4 intersectLine( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, float ra )
{
    vec3 ca = pb-pa;
    vec3 oc = ro-pa;
    float caca = dot(ca,ca);
    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    float a = caca - card*card;
    float b = caca*dot( oc, rd) - caoc*card;
    float c = caca*dot( oc, oc) - caoc*caoc - ra*ra*caca;
    float h = b*b - a*c;
    if( h<0.0 ) return vec4(NO_INTERSECTION); //no intersection
    h = sqrt(h);
    float t = (-b-h)/a;
    // body
    float y = caoc + t*card;
    if( y>0.0 && y<caca ) return vec4( t, (oc+t*rd-ca*y/caca)/ra );
    // caps
    t = (((y<0.0)?0.0:caca) - caoc)/card;
    if( abs(b+a*t)<h ) return vec4( t, ca*sign(y)/caca );
    return vec4(NO_INTERSECTION); //no intersection
}

vec2 intersectCylinder( vec3 ro, vec3 rd, vec3 cb, vec3 ca, float cr )
{
    vec3  oc = ro - cb;
    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    float a = 1.0 - card*card;
    float b = dot( oc, rd) - caoc*card;
    float c = dot( oc, oc) - caoc*caoc - cr*cr;
    float h = b*b - a*c;
    if( h<0. ) return vec2(NO_INTERSECTION); //no intersection
    h = sqrt(h);
    return vec2(-b-h,-b+h)/a;
}

vec4 intersectSphere(vec3 ro, vec3 rd, float r, float first){
    // x^2 + y^2 = r
    
    // (ro.x + rd.x*w)^2 + (ro.y + rd.y*w)^2 + (ro.z + rd.z*w)^2 = r  
    // F = ro.x
    // G = ro.y
    // H = ro.z
    // F*F + 2*F*rd.x*w + (rd.x*w)^2 + G*G + 2*G*rd.y*w + (rd.y*w)^2 = r  
    // w^2(rd.x^2 + rd.y^2 + rd.z^2 ) + w(2*F*rd.x + 2*G*rd.y + 2*H*rd.z) + (F*F + G*G + H*H - r) = 0

    
    float F = ro.x;
    float G = ro.y;
    float H = ro.z;
    
    float a = rd.x*rd.x + rd.y*rd.y + rd.z*rd.z;
    float b = 2.*F*rd.x + 2.*G*rd.y + 2.*H*rd.z;
    float c = F*F + G*G + H*H - r*r;
    
    
    vec3 Q = solveQuadratic(a, b, c);
    
    vec3 p;
    
    
    float d; 
    
    if( length(ro) < r){
        d = Q.x;
    } else {
        d = min(Q.x,Q.y);
    }
    vec3 n = normalize( (ro + rd*d) );
    
    if(Q.z > 0.){
        
        return vec4( d , n );
        
    } else {
        return vec4(NO_INTERSECTION);
    }
}

vec4 intersectTri( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2 )
{
    vec3 v1v0 = v1 - v0;
    vec3 v2v0 = v2 - v0;
    vec3 rov0 = ro - v0;
    vec3  n = cross( v1v0, v2v0 );
    vec3  q = cross( rov0, rd );
    float d = 1.0/dot( rd, n );
    float u = d*dot( -q, v2v0 );
    float v = d*dot(  q, v1v0 );
    float t = d*dot( -n, rov0 );
    if( u<0.0 || u>1.0 || v<0.0 || (u+v)>1.0 ) t = NO_INTERSECTION;
    
    vec3 normal = normalize(cross(v0 - v1, v2 - v1));
    return vec4( t, normal );
}

float sdBox(vec2 p, vec2 s){
    p = abs(p) - s;
    return max(p.x,p.y);  
}

vec3 getRd(vec3 ro, vec3 lookAt, vec2 uv){
    vec3 dir = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0,1,0),dir));
    vec3 up = normalize(cross(dir, right));
    return normalize(dir + right*uv.x + up*uv.y);
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 rgb2hsv( in vec3 c)
{
    float eps = 0.01;
    vec4 k = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.zy, k.wz), vec4(c.yz, k.xy), (c.z<c.y) ? 1.0 : 0.0);
    vec4 q = mix(vec4(p.xyw, c.x), vec4(c.x, p.yzx), (p.x<c.x) ? 1.0 : 0.0);
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y) / (6.0*d+eps)), d / (q.x+eps), q.x);
}

    

vec3 project(vec3 a, vec3 b){
    return dot(a,b)/dot(b,b)*(b);
}

void gramSchmidt(vec3 A, vec3 B, vec3 C, out vec3 Ao, out vec3 Bo, out vec3 Co ){
    Ao = A;
    
    Bo = B - project(B,A);
    
    Co = C - project(C,Bo) - project(C,Ao);
    
    Ao = normalize(Ao);
    Bo = normalize(Bo);
    Co = normalize(Co);
}

vec3 ro, rd, N, glow = vec3(0);
vec2 d;
bool assertion = true;

vec4[7] materials = vec4[](
    vec4(0.6,1.,0.4,1.),
    vec4(0.,.0,0.,1.),      // background
    vec4(0.1,0.2,0.4,0.9),  // guidelines
    vec4(0.,0.4,0.7,1.),    // diff A
    vec4(0.4,0.,0.2,0.8),
    vec4(0.,1.,0.,0.6),
    vec4(0.5,0.,1.,1.)       // diff B
);

void assert(bool);
vec2 dmin(vec2 , float , vec4 );
vec2 dmax(vec2 , float , vec4 );

void demoGramSchmidt(vec3 ro, vec3 rd){
    
    vec3 A = vec3(-0.4,0.6,-0.4);
    vec3 B = vec3(-0.7,0.3,0.1);
    vec3 C = vec3(-0.4,-0.2,-0.7);
    
    
    A = normalize(A)*0.5;
    B = normalize(B)*0.5;
    C = normalize(C)*0.5;
    
    
    float t = time*0.5; 
    B += vec3(sin(t),cos(t),sin(t))*0.2;
    C += vec3(cos(t),sin(t),sin(t))*0.2;
    A.xz *= rot(sin(t)*0.2);
    
    vec3 Ao, Bo, Co;
    
    gramSchmidt( A, B, C, Ao, Bo, Co );
    
    assert(abs(dot(Ao,Bo)) < 0.001);
    assert(abs(dot(Co,Bo)) < 0.001);
    assert(abs(dot(Bo,Co)) < 0.001);
    assert(abs(dot(Ao,Co)) < 0.001);
    
    
    float r = 0.02;
    
    vec4 sphere = intersectSphere(ro, rd, r,1.);
    
    d = dmin(d,3.,sphere);
    
    d = dmin(d,6.,intersectSphere(ro - A, rd, r,1.));
    d = dmin(d,6.,intersectSphere(ro - B, rd, r,1.));
    d = dmin(d,6.,intersectSphere(ro - C, rd, r,1.));
    
    d = dmin(d,5.,intersectSphere(ro - Ao, rd, r,1.));
    d = dmin(d,5.,intersectSphere(ro - Bo, rd, r,1.));
    d = dmin(d,5.,intersectSphere(ro - Co, rd, r,1.));
    
    
    d = dmin(d,6.,intersectLine( ro, rd,vec3(0),A, r*0.3));
    d = dmin(d,6.,intersectLine( ro, rd,vec3(0),B, r*0.3));
    d = dmin(d,6.,intersectLine( ro, rd,vec3(0),C, r*0.3));
    
    d = dmin(d,5.,intersectLine( ro, rd,vec3(0),Ao, r*0.5));
    d = dmin(d,5.,intersectLine( ro, rd,vec3(0),Bo, r*0.5));
    d = dmin(d,5.,intersectLine( ro, rd,vec3(0),Co, r*0.5));
    
    d = dmin(d,4.,intersectTri( ro, rd, Bo, vec3(0), Ao ));
    d = dmin(d,4.,intersectTri( ro, rd, Co, vec3(0), Ao ));
    d = dmin(d,4.,intersectTri( ro, rd, Co, vec3(0), Bo ));
}

vec3 shade( float id, float d, vec3 n){
    vec3 col = vec3(0);
    
    vec4 m = materials[int(id)];
    
    vec3 p = ro + rd*d;
    
    if( id == 2.){
        
        float ld = 10e4;
        
        vec3 q = p;
        
        q = pmod(q,0.5);
        
        float eps = 0.01;
           if(abs(p.y) < eps){
            ld = min(ld,abs(q.x));
            ld = min(ld,abs(q.z));
        } else if(abs(p.x) < eps){ 
            ld = min(ld,abs(q.y));
            ld = min(ld,abs(q.z));
        } else if(abs(p.z) < eps){ 
            ld = min(ld,abs(q.y));
            ld = min(ld,abs(q.x));
        }
        
        
        col = mix(col,vec3(0.2),smoothstep(0.01,0.,ld ));
        
        
        col *= smoothstep(1.,0.,d*0.16);
        
    } else {
        vec3 l = normalize(vec3(1,0.25,-1.));

        vec3 lcol = vec3(1,0.8,0.3);

        col = m.xyz + n*0.2;

        float diff = sin( dot(n,l) );
        diff += mix(length(asin(sin(n*1.)*.9)*0.5+0.5)/sqrt(3.),0.,.0)*0.1; // um ok blackle thx, I have no clue what this is tho lol
        float fres = pow(max( 1. - dot(n,-rd), 0.001), 5.);  

        vec3 r = reflect(rd,n);

        float spec1 = length(asin(sin(r*4.)*.9)*0.5+0.5)/sqrt(3.);

        
        vec3 hsv = rgb2hsv(col);

        vec3 darkened = hsv2rgb(vec3(hsv.x,hsv.y*2.,hsv.z*0.6));

        col += spec1*0.7*lcol;
        col = mix(col,darkened,1.-diff);;
        col = max(col,0.);
        col *= m.w;
    }
    
    
    return col;
}

vec3 get( vec2 U ){
    
    glow -= glow;
    vec2 uv = (U - 0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    d = vec2(10e4);
    
    ro = vec3(0);
    
    //float xz = sin(T*0.4)*0.4 - mouse.x*resolution.xy.x/resolution.x*2. + 5. ;
    //float y = sin(time)*0.25 + mouse.y*resolution.xy.y/resolution.x*4. + 0.4;
    float xz = sin(T*0.4)*0.4 + 5. ;
    float y = sin(time)*0.25 + 0.4;
    ro.xz += vec2(sin(xz), cos(xz))*3.;
    ro.y += y + 1.;
    
    ro *= 0.7;
    
    vec3 lookAt = vec3(0);
    
    rd = getRd(ro, lookAt, uv);
    
    
    
    float pipew = 0.01;
    
    // background
    d = dmin(d,1.,intersectSphere(ro, rd, 25.2,0.)); 

    
    // guidelines
    d = dmin(d,3.,intersectLine( ro, rd,vec3(0,0,-6),vec3(0,0,1150), pipew));
    d = dmin(d,3.,intersectLine( ro, rd,vec3(-6,0,0),vec3(1150,0,0), pipew));
    d = dmin(d,3.,intersectLine( ro, rd,vec3(0,-10,0),vec3(0,150,0), pipew));
    
    // guideplanes
    d = dmin(d,2.,intersectPlane(ro, rd, vec3(0.,-1,0.)));
    d = dmin(d,2.,intersectPlane(ro, rd, vec3(1.,0.,0.)));
    d = dmin(d,2.,intersectPlane(ro, rd, vec3(0.,0,1.)));
    
    

    demoGramSchmidt( ro, rd);
         
    
    vec3 p = ro + rd*d.x;
    
   
    col += shade( d.y, d.x, N);
    
    
    col += glow;
    
    
    return col;
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 C = glFragColor;

    vec2 uv = (U - 0.5*R)/R.y;
    vec3 col = vec3(0);
    for(float i =0.; i < AA*AA + min(float(frames),0.)   ; i++){
        col += get(U + vec2(mod(i,AA),floor(i/AA))/AA - .5);
    }
    col /= AA*AA;
    
    
    if(!assertion){
        col = mix(col,vec3(1,0.,0),smoothstep(dFdy(uv.y),0.,sdBox(uv - 0.5,vec2(0.1))));
    }
    
    col = max(col, 0.);
    C.xyz = pow(col.xyz,vec3(0.454545));
        
    C = vec4(col,1.0);

    glFragColor = C;
}

vec2 dmin(vec2 a, float id, vec4 b ){
    vec4 m = materials[int(id)];
    if (a.x < b.x ||  b.x == NO_INTERSECTION){
        return a;
    } else if (  m.w < 1. ){
        glow += shade(id,b.x,b.yzw);
        return a;
    } else {
        N = b.yzw;
        return vec2(b.x,id);
    }
    
}
void assert(bool thing){
    if(!thing)
        assertion = false;
}
