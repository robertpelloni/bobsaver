#version 420

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// original https://www.shadertoy.com/view/4dl3Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float length2( in vec3 p ) { return dot(p,p); }

const vec3 va = vec3(  0.0,  0.57735,  0.0 );
const vec3 vb = vec3(  0.0, -1.0,  1.15470 );
const vec3 vc = vec3(  1.0, -1.0, -0.57735 );
const vec3 vd = vec3( -1.0, -1.0, -0.57735 );

// return distance and address
vec2 map( vec3 p )
{
    float a = 0.0;
    vec3 c;
    float dist, d, t;
    for( int i=0; i<7; i++ )
    {
        d = length2(p-va);                 c = va; dist=d; t=0.0;
        d = length2(p-vb); if (d < dist) { c = vb; dist=d; t=1.0; }
        d = length2(p-vc); if (d < dist) { c = vc; dist=d; t=2.0; }
        d = length2(p-vd); if (d < dist) { c = vd; dist=d; t=3.0; }
        p = c + 2.0*(p - c);
        a = t + a*4.0;
    }
    
    return vec2( (length(p)-1.41)/pow(2.0, 7.0), a/pow(4.0,7.0) );
}

const float precis = 0.001;

vec3 intersect( in vec3 ro, in vec3 rd )
{
    vec3 res = vec3( 1e20, 0.0, 0.0 );
    
    // plane
    float tp = (-1.0-ro.y)/rd.y;
    if( tp>0.0 ) res = vec3(tp, 1.0, 0.0 );
    
    // sierpinski
    float maxd = min( res.x, 8.0 );
    float h = 1.0;
    float t = 0.0;
    float m = 0.0;
    for( int i=0; i<80; i++ )
    {
        if( h>precis && t<maxd )
        {            
        vec2 h = map( ro+rd*t );
        m = h.y;
        t += h.x;
        }            
    }

    if( t<maxd && t<res.x )
        res = vec3( t, 2.0, m );

    return res;
}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3(precis*10.0,0.0,0.0);
    return normalize( vec3(
           map(pos+eps.xyy).x - map(pos-eps.xyy).x,
           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<40; i++ )
    {
        float h = map(ro + rd*t).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.01, 1.0 );
    }
    return clamp(res,0.0,1.0);
}

float occlusion( in vec3 pos, in vec3 nor )
{
    float totao = 0.0;
    float sca = 1.0;
    for( int aoi=0; aoi<8; aoi++ )
    {
        float hr = 0.01 + 1.2*pow(float(aoi)/8.0,1.5);
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        totao += -(dd-hr)*sca;
        sca *= 0.85;
    }
    return clamp( 1.0 - 0.6*totao, 0.0, 1.0 );
}

vec3 lig = normalize(vec3(1.0,0.7,0.9));

void main( void )
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
    vec2 m = vec2(0.5);

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
    
    float an = 3.2 + 0.5*time - 6.2831*(m.x-0.5);

    vec3 ro = vec3(2.51*sin(an),0.0,2.5*cos(an));
    vec3 ta = vec3(0.0,-0.5,0.0);
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

    //-----------------------------------------------------
    // render
    //-----------------------------------------------------

    vec3 col = vec3(0.0);

    // raymarch
    vec3 tm = intersect(ro,rd);
    if( tm.y>0.5 )
    {
        // geometry
        vec3 pos = ro + tm.x*rd;
        vec3 nor = vec3( 0.0 );
        vec3 maa = vec3( 0.0 );
        
        float occ = 1.0;
        
        if( tm.y<1.5 )
        {
            nor = vec3( 0.0, 1.0, 0.0 );
            maa = vec3( 0.5 );
        }
        else
        {
            nor = calcNormal( pos );
            maa = 0.5 + 0.5*cos( 6.2831*tm.z + vec3(0.0,1.0,2.0) );
            occ *= 0.5 + 0.5*clamp( (pos.y+1.0)/0.5, 0.0, 1.0 );
        }

        occ *= occlusion( pos, nor );

        // lighting
        float amb = (0.5 + 0.5*nor.y)*(1.0 - smoothstep( 10.0, 40.0, length(pos.xz) ));
        float dif = max(dot(nor,lig),0.0);
        float sha = 0.0; if( dif>0.01 ) sha=softshadow( pos+0.01*nor, lig, 0.0005, 32.0 );
        float att = 1.0 - smoothstep( 1.5, 2.5, length(pos.xz) );
        // lights
        vec3 lin = vec3(0.0);
        lin += 1.5*dif*vec3(1.00,0.90,0.70)*pow(vec3(sha*att),vec3(1.0,1.2,1.5));
        lin += 0.4*amb*vec3(0.30,0.35,0.40) * occ;

        // surface-light interacion
        col = maa * lin;
        
    }

    // gamma
    col = pow( clamp(col,0.0,1.0), vec3(0.45) );

    glFragColor = vec4( col, 1.0 );
}
