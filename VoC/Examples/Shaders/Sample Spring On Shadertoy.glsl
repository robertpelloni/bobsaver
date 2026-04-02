#version 420

// original https://www.shadertoy.com/view/7t2cRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

const float PI    = 3.14159265359;
const float TWOPI = 6.28318530717;

const float C = cos(3.1415/5.), S=sqrt(0.75-C*C);
const vec3 P35 = vec3(-0.5, -C, S);

const vec3 ICOMIDEDGE = vec3(0,0,1);
const vec3 ICOVERTEX = normalize(cross(vec3(0, 1, 0), P35));     
const vec3 ICOMIDFACE = normalize(cross(P35, vec3(1, 0, 0)));    

// https://en.wikipedia.org/wiki/Table_of_polyhedron_dihedral_angles
const float ICODIHEDRAL  = acos(sqrt(5.)/3.);  
const float DODEDIHEDRAL = acos(sqrt(5.)/5.);

vec3 opIcosahedron( vec3 p, out float parity )
{    
    vec3 par = sign(p);
    p = abs(p);

    float mirr = dot(p, P35);
    p -= 2.*min(0., mirr)*P35;
    par *= sign(vec3(p.xy,mirr));
    p.xy = abs(p.xy);
    
    mirr = dot(p, P35);
    p -= 2.*min(0., mirr)*P35;
    par *= sign(vec3(p.xy,mirr));
    p.xy = abs(p.xy);

    mirr = dot(p, P35);
    p -= 2.*min(0., mirr)*P35;

    parity = par.x*par.y*par.z*sign(mirr);
    return p;
}    

// List of some other 2D distances: https://www.shadertoy.com/playlist/MXdSRf
//
// and https://iquilezles.org/articles/distfunctions2d

float cro(in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

// uneven capsule
float sdUnevenCapsuleY( in vec2 p, in float ra, in float rb, in float h )
{
    p.x = abs(p.x);
    
    float b = (ra-rb)/h;
    vec2  c = vec2(sqrt(1.0-b*b),b);
    float k = cro(c,p);
    float m = dot(c,p);
    float n = dot(p,p);
    
         if( k < 0.0   ) return sqrt(n)               - ra;
    else if( k > c.x*h ) return sqrt(n+h*h-2.0*h*p.y) - rb;
                         return m                     - ra;
}
    
float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
      return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

#define S smoothstep
#define T (time)
// Fabrice
#define hue(v)  ( .6 + .6 * cos( 6.3*(v)  + vec3(0,23,21)  ) )

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

vec2 opPolar(vec2 p,int n) {
    float angle = TWOPI/float(n);
    float at=atan(p.y,p.x); 
    // IQ video about polar symetry https://youtu.be/sl9x19EnKng?t=1745
    float sector = round(at/angle); 
    p = Rot(angle*sector) * p;
    return p;
}

vec4 flower(vec3 q, float parity, int symmetry) {
    float phase = 0.0;
    int n;
    if ( symmetry == 5 ) { 
            q.xz *= Rot(DODEDIHEDRAL*.5);
            q.xy = q.yx;
            q.xy *= vec2(parity,-1); 
            n=10;
    }
    if ( symmetry == 3 ) {
        q.yz *= Rot(ICODIHEDRAL*.5);
        q.xy *= vec2(parity,-1); 
        n=9;
        phase = PI;
    }
    // at the end I have coordinates starting from the vertex of the ICO or DODE
    // signed x, and y pointing to center of the rhombic face
    //
    // stem
    float t = sin(time*.25+phase);
    float h = 1.05+.25*smoothstep(-0.5,-0.25,t);
    float d = length(q-vec3(0.,0.,min(q.z,h)));
    vec4 hit = vec4(d,2.0,q.z-h,d);
    hit.x -= .05;
    if (q.z < h) hit.x -= .002*min(1.0,cos((q.z-h)*150.)+.9);
    // petals
    q.z -= h;
    q.xy *= Rot(time*.5);
    q.yx = opPolar(q.yx,n);
    q.xy-=vec2(0.0,.07);
    q.zy *= Rot(.9-.3*smoothstep(-0.3,0.2,t));
    float fan = sdUnevenCapsuleY(q.xy-vec2(0.0,.015),.015,.08,.30);
    float fan3d = opExtrussion(q,fan,.0)-.02+.005*smoothstep(0.0,-0.03,fan);
    if ( fan3d < hit.x ) hit = vec4(fan3d,1.0,-fan,q.z);
    return hit;
}

vec4 map4(vec3 p) {
    p.xy *= Rot(T*.1);
    float parity;
   float center = length(p);
    vec4 hit = vec4(center-1.9,vec3(0));
    if ( center > 2. ) return hit; // nice optimization
    vec3 q = opIcosahedron(p,parity);
     float base = min(min(q.x,q.y),dot(q,P35))-.01;
    float h1 = length(q-ICOVERTEX*dot(q,ICOVERTEX))-.08;
    base = max(base,-h1);
    base = min(base,abs(h1)-.01);
    float h2 = length(q-ICOMIDFACE*dot(q,ICOMIDFACE))-.08;
    base = max(base,-h2);
    base = min(base,abs(h2)-.01);
    base = max(base,center-1.0);
    hit = vec4(base,4.0,center,0.0);
    vec4 fl1 = flower(q,parity,5);
    if ( fl1.x < hit.x ) { hit = fl1; }
    vec4 fl2 = flower(q,parity,3);
    if ( fl2.x < hit.x ) { hit = fl2; }
    return hit;
}

float map(vec3 p) {
    return map4(p).x;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = map(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = map(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    
    return normalize(n);
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.y;

    vec3 ro = vec3(0.5, 0, -3.4);

    //if ( mouse*resolution.xy.x > 0.0 ) {
    //    ro.yz *= Rot(-m.y*3.14);
    //    ro.xz *= Rot(-m.x*6.2831);
    //} else {   
    //}    
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.);
    vec3 bg = (hue(.55)*.5+vec3(.5))*(1.-abs(rd.y));;
    vec3 col = bg;
    float d = RayMarch(ro, rd);

    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        vec4 hit = map4(p);
        vec3 objCol = vec3(0);
        if ( hit.y < 1.5 ) {
            // petals
            objCol = mix(hue(.0),hue(.95),smoothstep(0.01,0.015,hit.z));
            objCol = mix(objCol,hue(.17),smoothstep(.06,.08,hit.z));
            objCol = mix(objCol,vec3(1),smoothstep(.005,-.02,hit.w));
        } else if ( hit.y <= 2.5 ) {
            // stem
            objCol = mix(hue(.29)*.7+.3,hue(.17),smoothstep(-0.25,0.0,hit.z));
        } else if ( hit.y <= 4.5 ) {
            // base
            objCol = mix(.3+.7*hue(.4),vec3(1),1.0-smoothstep(0.95,0.93,hit.z));
        }
        vec3 sun_lig = normalize(vec3(1,2,-3));
        float dif = max(0.1,dot(n, sun_lig));
        float spe = pow(clamp(dot(n,normalize( sun_lig-rd )),0.0,1.0),8.0) * dif;
        float occ = calcOcclusion(p,n);
        // IQ https://www.shadertoy.com/view/3lsSzf
        float bou_dif = sqrt(clamp( 0.1-0.9*n.y, 0.0, 1.0 ))*clamp(1.0-0.1*p.y,0.0,1.0);
        vec3 sun_col = vec3(1.64,1.27,0.99);
        vec3 lin = vec3(0);
        lin += spe * occ * sun_col;
        lin += dif * occ * sun_col;
        lin += bou_dif*vec3(0.20,0.70,0.10)*occ;
        col = objCol * lin * .5 ;
    }    
    col = pow(col, vec3(.4545));    // gamma correction
    col = mix(col,bg,smoothstep(3.0,3.9,d));
    glFragColor = vec4(col,1.0);
}
