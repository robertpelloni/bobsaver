#version 420

// original https://www.shadertoy.com/view/4tGXW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sum3(vec3 p) {
  return p.x + p.y + p.z;
}

//----------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

float sdPlane( vec3 p )
{
    return p.y;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

/*
vec3 opTx( vec3 p, mat4 m )
{
    vec3 q = invert(m)*p;
    return primitive(q);
}
*/

vec2 map( in vec3 pos )
{
  vec2 res = vec2(
          sdBox(pos-vec3(1.0, 0.0, 0.0),vec3(0.5, 0.6, 0.7)), 46.9);
  res = opU( res, vec2( sdTorus(pos-vec3( 0.0,0.5, 0.5), vec2(0.50,0.1) ), 25.0 ) );
  mat3 rotate90 = mat3(vec3(0, -1, 0), vec3(1, 0, 0), vec3(0, 0, 1));
  res = opU( res, vec2( sdTorus(rotate90 * (pos-vec3( 0.0,0.5, 1.0)), vec2(0.50,0.1) ), 25.0 ) );

  return opU(res, vec2(sdPlane(pos), 1.0));
}

// Copy'n paste from https://www.shadertoy.com/view/Xds3zN
// Then modified from anaglyph

vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 50.0;

#if 0
    float tp1 = (0.0-ro.y)/rd.y; if( tp1>0.0 ) tmax = min( tmax, tp1 );
    float tp2 = (1.6-ro.y)/rd.y; if( tp2>0.0 ) { if( ro.y>1.6 ) tmin = max( tmin, tp2 );
                                                 else           tmax = min( tmax, tp2 ); }
#endif

    float precis = 0.0001;
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
    vec3 eps = vec3( 0.00001, 0.0, 0.0 );
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

        // lightning

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

        float occ = calcAO( pos, nor );
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

    float time = 15.0 + time;

    // Camera
    float dist = 3.0;
    vec3 ro = vec3(
            -0.5+dist*cos(0.1*time + 6.0*mo.x),
            1.0 + 2.0*mo.y,
            -0.5 + dist*sin(0.1*time + 6.0*mo.x) );
    vec3 ta = vec3(0.0);
    vec3 eyes_line = normalize(cross(vec3(0.0, 1.0, 0.0), ro));
    float d_eyes_2 = 0.08;
    vec3 ro_left = ro + d_eyes_2 * eyes_line;
    vec3 ro_right = ro - d_eyes_2 * eyes_line;
    vec3 ta_left = ta + d_eyes_2 * eyes_line;
    vec3 ta_right = ta - d_eyes_2 * eyes_line;

    // camera-to-world transformation
    mat3 ca_left  = setCamera(ro_left, ta_left, 0.0);
    mat3 ca_right = setCamera(ro_right, ta_right, 0.0);

    // rays' direction
    vec3 rd_left = ca_left * normalize( vec3(p.xy,1.0) );
    vec3 rd_right = ca_right * normalize( vec3(p.xy,1.0) );

    // render both eye
    vec3 col_left = render( ro_left, rd_left );
    vec3 col_right = render( ro_right, rd_right );

    //vec3 col = vec3( col_right.r, col_left.g, col_left.b);
    vec3 col = vec3( col_left.r, col_right.g, col_right.b);
    col = pow( col, vec3(0.4545) );

    glFragColor=vec4( col, 1.0 );
}

