#version 420

// original https://www.shadertoy.com/view/llKcR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Modified from https://www.shadertoy.com/view/Xds3zN by iq.

// Face coloring was a little more complicated than expected, 
// so I'm leaving the pentagons colored as circles for now.

#define AA 1

//------------------------------------------------------------------

float sdPlane( vec3 p )
{
    return p.y;
}

float lpnorm(vec3 p, float s){
    return pow(
        (
         pow(abs(p.x),s)+
         pow(abs(p.y),s)+
         pow(abs(p.z),s)), 
        1.0/s);
}

#define PI 3.14159265359
#define PHI (1.618033988749895)
#define TAU 6.283185307179586

// HG_SDF Icosahedron but truncated and rounded
vec2 football(vec3 p, float s){
    float d = 0.0;
    float M = 2.0;
    
    d = max(d, abs(dot(p, normalize(vec3(1.0,1,1))  )));
    d = max(d, abs(dot(p, normalize(vec3(-1,1,1)) )));
    d = max(d, abs(dot(p, normalize(vec3(1,-1,1)) )));
    d = max(d, abs(dot(p, normalize(vec3(1,1,-1)) )));
    
    d = max(d, abs(dot(p, normalize(vec3(0,1,PHI+1.))   )));
    d = max(d, abs(dot(p, normalize(vec3(0,-1,PHI+1.))  )));
    d = max(d, abs(dot(p, normalize(vec3(PHI+1.,0,1))   )));
    d = max(d, abs(dot(p, normalize(vec3(-PHI-1.0,0,1)) )));
    d = max(d, abs(dot(p, normalize(vec3(1,PHI+1.,0))   )));
    d = max(d, abs(dot(p, normalize(vec3(-1,PHI+1.,0))  )));
    
    // Truncation
    // FIXME: planarity not maintained when rounding. Circular pentagon material.
    //        May have to defer this to the material stage?
    float si = s*.04;
    
    float rnd = length(p);
    float rdg = 0.35;
    float ort = 0.49;
    
    float dprod = abs(dot(p, normalize(vec3(-PHI-1.0,PHI,0))  ));
    d = max(d, dprod - si);
    M = dprod>ort?99.0:M;
    dprod = abs( dot( p, normalize(vec3(PHI+1.0,PHI,0) ) ) );
    d = max(d, dprod - si);
    M = dprod>ort?99.0:M;
    dprod = abs(dot(p, normalize(vec3(0,-PHI,1.0)) ));
    d = max(d, dprod - si);
    M = dprod>ort?99.0:M;
    dprod = abs(dot(p, normalize(vec3(0,PHI,1.0)) ));
    d = max(d, dprod - si);
    M = dprod>ort?99.0:M;
    dprod = abs(dot(p, normalize(vec3(1.0,0,-PHI)) ));
    d = max(d, dprod -si);
    M = dprod>ort?99.0:M;
    dprod = abs(dot(p, normalize(vec3(1.0,0,PHI)) ));
    d = max(d, dprod -si);
    M = dprod>ort?99.0:M;
    
    //return vec2(d-s+abs(d-rnd)*1.5, M);
    return vec2(d-s+pow(abs(d-rnd)*8.0,2.0)*rdg, M);
}

//------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

// http://www.geeks3d.com/20141201/how-to-rotate-a-vertex-by-a-quaternion-in-glsl/
vec4 axis2quat(vec3 a, float angle){
    float hlf = (angle * 0.5) * 3.14159 / 180.0;
    return vec4(
        a.x * sin(hlf),
        a.y * sin(hlf),
        a.z * sin(hlf),
        cos(hlf)
    );
}

vec4 quat_conj(vec4 q){
    return vec4(-q.x,-q.y,-q.z, q.w);
}

vec4 quat_mul(vec4 q1, vec4 q2)
{ 
  vec4 qr;
  qr.x = (q1.w * q2.x) + (q1.x * q2.w) + (q1.y * q2.z) - (q1.z * q2.y);
  qr.y = (q1.w * q2.y) - (q1.x * q2.z) + (q1.y * q2.w) + (q1.z * q2.x);
  qr.z = (q1.w * q2.z) + (q1.x * q2.y) - (q1.y * q2.x) + (q1.z * q2.w);
  qr.w = (q1.w * q2.w) - (q1.x * q2.x) - (q1.y * q2.y) - (q1.z * q2.z);
  return qr;
}

//------------------------------------------------------------------

vec3 fbpos(){
    return vec3(sin(time*.8)*1.5,
                        abs(sin(time*3.1))*.7+.5,
                        0.0);
}

vec2 map_shapes( vec3 pos ) {
    
    vec3 p = pos - fbpos();
    
    vec4 qr = axis2quat(normalize(vec3(cos(time+PHI),0.0,sin(time+PHI))), mod(-time,1000.0)*150.0);
    vec4 qr_conj = quat_conj(qr);
    vec4 q_pos = vec4(p.xyz, 0.0);
    
    qr = quat_mul(quat_mul(qr, q_pos), qr_conj);
    vec3 q = vec3(qr.x, qr.y, qr.z);
    
    vec2 res = football(
        q, .5);
    
    return res;
}

vec2 map( in vec3 pos )
{
    vec2 res = vec2( sdPlane(pos), 1.0 );
    
    res = opU(res, map_shapes(pos));
    
    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 30.0;
    
    float t = tmin;
    float m = -1.0;
    for( int i=0; i<80; i++ )
    {
        float precis = 0.0001*t;
        vec2 res = map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x*.7;
        m = res.y;
    }

    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
                      e.yyx*map( pos + e.yyx ).x + 
                      e.yxy*map( pos + e.yxy ).x + 
                      e.xxx*map( pos + e.xxx ).x );
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

// http://iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
float checkersGradBox( in vec2 p )
{
    // filter kernel
    vec2 w = fwidth(p) + 0.001;
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)*0.5)-0.5)-abs(fract((p+0.5*w)*0.5)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;                  
}

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.7, 0.9, 1.0) +rd.y*0.8;
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = 0.45 + 0.35*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        if( m<1.5 )
        {
            
            float f = checkersGradBox( 1.2*pos.xz+time*3.0 );
            col = 0.3 + f*vec3(0.3);
        }
        if (m >= 2.0 ){
            col = vec3(0.6);
        }
        if (m >= 3.0){
            col = vec3(0.07);
        }

        // lighting        
        float occ = calcAO( pos, nor );
        vec3  lig = normalize( vec3(0.2, 0.7, 0.6) );
        vec3  hal = normalize( lig-rd );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        
        dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );
        dom *= calcSoftshadow( pos, ref, 0.02, 2.5 );

        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

        vec3 lin = vec3(0.0);
        lin += 1.30*dif*vec3(1.00,0.80,0.55);
        lin += 0.20*amb*vec3(0.40,0.60,1.00)*occ;
        lin += 0.20*dom*vec3(0.40,0.60,1.00)*occ;
        lin += 0.30*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.35*fre*vec3(1.00,1.00,1.00)*occ;
        col = col*lin;
        col += 10.00*spe*vec3(1.00,0.90,0.70);

        col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
    }

    return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;
    float time = 15.0 + time;

    
    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord+o))/resolution.y;
#else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif

        // camera    
        vec3 ro = vec3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 
                       2.0 + 2.0*mo.y, 
                       0.5 + 4.0*sin(0.1*time + 6.0*mo.x) );
        vec3 ta = vec3(0.0, 0.7, 0.0);
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta, 0.0 );
        // ray direction
        vec3 rd = ca * normalize( vec3(p.xy, 2.5) );

        // render    
        vec3 col = render( ro, rd );

        // gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    
    glFragColor = vec4( tot, 1.0 );
}
