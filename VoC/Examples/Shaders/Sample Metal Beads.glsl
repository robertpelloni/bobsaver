#version 420

// original https://www.shadertoy.com/view/4dGGDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on www.shadertoy.com/view/Xds3zN Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI_16TH 0.39269908169 
#define HALF_PI 1.57079632679
#define PI 3.14159265359

float sdSphere( vec3 p, float s , float a, float b)
{
    mat3 rot1 = mat3(vec3(sin(b),cos(b),0.0), 
                     vec3(cos(b),-sin(b),0.0),
                     vec3(0.0,0.0,1.0));
    mat3 rot2 = mat3(vec3(sin(a),0.0,cos(a)), 
                     vec3(0.0, 1.0, 0.0),
                     vec3(cos(a), 0.0, -sin(a)));
    p -= rot2*rot1*vec3(0.0,0.9,0.0);
    return length(p)-s;
}

float sdTorus( vec3 p, vec2 t , float a)
{
  mat3 rot = mat3(vec3(sin(a),0.0,cos(a)), 
                  vec3(0.0, 1.0, 0.0),
                  vec3(cos(a), 0.0, -sin(a)));
  
  p = rot*p;
  p -= -vec3( 0.0,0.0, 0.0);
  return length( vec2(length(p.yz)-t.x,p.x) )-t.y;
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 map( in vec3 pos )
{
    float time = 2.0 * time;
    vec2 res = vec2(11111111.0,0.0);

    for( int i=0; i<8; i++ )
    {
        res = opU( res, vec2( sdTorus(pos, vec2(0.90,0.01), float(i) * PI_16TH ), 25.0 ) );  
        res = opU(res, vec2( sdSphere(    pos, 0.13 , float(i) * PI_16TH, time + PI_16TH * float(i)), time + float(i)));
    }
    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.002;
    float t = tmin;
    float m = -1.0;
    for( int i=0; i<50; i++ )
    {
        vec2 res = map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        m = res.y;
    }

    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
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
        col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        
        if( m<1.5 )
        {
            
            float f = mod( floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
            col = 0.4 + 0.1*f*vec3(1.0);
        }

        // lighitng        
        float occ = calcAO( pos, nor );
        vec3  lig = normalize( vec3(-0.6, 0.7, -0.5) );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);
        
        dif *= softshadow( pos, lig, 0.02, 2.5 );
        dom *= softshadow( pos, ref, 0.02, 2.5 );

        vec3 lin = vec3(0.0);
        lin += 1.20*dif*vec3(1.00,0.85,0.55);
        lin += 1.20*spe*vec3(1.00,0.85,0.55)*dif;
        lin += 0.20*amb*vec3(0.50,0.70,1.00)*occ;
        lin += 0.30*dom*vec3(0.50,0.70,1.00)*occ;
        lin += 0.30*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.40*fre*vec3(1.00,1.00,1.00)*occ;
        col = col*lin;

        col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.002*t*t ) );

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
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;
         
    float time = 0.0 + time/3.0;
    float cra = HALF_PI - clamp(HALF_PI * (cos(time)), 0.0, HALF_PI); // camera rotation angle
    
    float y = (0.5 + 0.5 * cos(time))*3.0;
    
    // camera    
    vec3 ro = vec3( 0.0, sqrt(9.0-y*y), y);
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    // render    
    vec3 col = render( ro, rd );

    col = pow( col, vec3(0.4545) );

    glFragColor=vec4( col, 1.0 );
}
