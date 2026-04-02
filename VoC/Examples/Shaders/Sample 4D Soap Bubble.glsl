#version 420

// original https://www.shadertoy.com/view/4d2Gzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//various noises borrowed from iq

#define FULL_PROCEDURAL

#ifdef FULL_PROCEDURAL

// hash based 3d value noise
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}
#else

// LUT based 3d value noise
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}
#endif

//x3
vec3 noise3( in vec3 x)
{
    return vec3( noise(x+vec3(123.456,.567,.37)),
                noise(x+vec3(.11,47.43,19.17)),
                noise(x) );
}

//http://dept-info.labri.fr/~schlick/DOC/gem2.ps.gz
float bias(float x, float b) {
    return  x/((1./b-2.)*(1.-x)+1.);
}

float gain(float x, float g) {
    float t = (1./g-2.)*(1.-(2.*x));    
    return x<0.5 ? (x/(t+1.)) : (t-x)/(t-1.);
}

mat3 rotation(float angle, vec3 axis)
{
    float s = sin(-angle);
    float c = cos(-angle);
    float oc = 1.0 - c;
    vec3 sa = axis * s;
    vec3 oca = axis * oc;
    return mat3(    
        oca.x * axis + vec3(    c,    -sa.z,    sa.y),
        oca.y * axis + vec3( sa.z,    c,        -sa.x),        
        oca.z * axis + vec3(-sa.y,    sa.x,    c));    
}

vec3 fbm(vec3 x, float H, float L, int oc)
{
    vec3 v = vec3(0);
    float f = 1.;
    for (int i=0; i<10; i++)
    {
        if (i >= oc) break;
        float w = pow(f,-H);
        v += noise3(x)*w;
        x *= L;
        f *= L;
    }
    return v;
}

vec3 smf(vec3 x, float H, float L, int oc, float off)
{
    vec3 v = vec3(1);
    float f = 1.;
    for (int i=0; i<10; i++)
    {
        if (i >= oc) break;
        v *= off + f*(noise3(x)*2.-1.);
        f *= H;
        x *= L;
    }
    return v;    
}

vec4 map( in vec3 p )
{
    float d = 0.2 - p.y;

    vec3 q = p - vec3(1.0,0.1,0.0)*time;
    
#if 0    
    float f;
    f  = 0.5000*noise( q ); q = q*2.02;
    f += 0.2500*noise( q ); q = q*2.03;
    f += 0.1250*noise( q ); q = q*2.01;
    f += 0.0625*noise( q );

    d += 3.0 * f;

    d = clamp( d, 0.0, 1.0 );
    
    vec4 res = vec4( d );

    res.xyz = mix( 1.15*vec3(1.0,0.95,0.8), vec3(0.7,0.7,0.7), res.x );
#endif
    
//    vec3 p = vec3(uv*.2,slow+change);                    //coordinate + slight change over time
    p -= vec3(1.0,0.1,0.0)*time*.01;
    p *= 4.;
    
    vec3 axis = 4. * fbm(p, 0.5, 2., 8);                //random fbm axis of rotation
    
    vec3 colorVec = 0.5 * 5. * fbm(p*0.3,0.5,2.,7);        //random base color
    p += colorVec;
    
//    float mag = 4e5;    //published, rather garish?
    float mag = 0.75e5; //still clips a bit
//    mag = mag * (1.+sin(2.*3.1415927*ts)*0.75);
    vec3 colorMod = mag * smf(p,0.7,2.,8,.2);            //multifractal saturation
    colorVec += colorMod;
    
    colorVec = rotation(3.*length(axis),normalize(axis))*colorVec;

    colorVec *= 0.1;
    
    vec4 res;
    res.xyz = colorVec;
    res.w = length(colorVec)*8.;
//    res.xyz = vec3(pow(res.w,100.));
//    res.w = pow(res.w,100.);
    res = clamp(res, vec4(0),vec4(1));
//#endif    
    return res;
}

vec3 sundir = vec3(-1.0,0.0,0.0);

vec4 raymarch( in vec3 ro, in vec3 rd )
{
    vec4 sum = vec4(0, 0, 0, 0);

    float t = 0.1;
    for(int i=0; i<64; i++)
    {
        if( sum.a > 0.99 ) continue;

        vec3 pos = ro + t*rd;
        vec4 col = map( pos );
        
        #if 0
        float dif =  clamp((col.w - map(pos+0.3*sundir).w)/0.6, 0.0, 1.0 );

        vec3 lin = vec3(0.65,0.68,0.7)*1.35 + 0.45*vec3(0.7, 0.5, 0.3)*dif;
        col.xyz *= lin;
        #endif
        
        col.a *= 0.35 * (t*8.);
        col.rgb *= col.a;

        sum = sum + col*(1.0 - sum.a);    

        #if 0
        t += 0.1;
        #else
        t += max(0.1,0.025*t);
        #endif
    }

    sum.xyz /= (0.001+sum.w);

    return clamp( sum, 0.0, 1.0 );
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= resolution.x/ resolution.y;
    vec2 mo = vec2(0);//-1.0 + 2.0*mouse.xy / resolution.xy;
    mo.x = sin(time*0.0125);
    // camera
    vec3 ro = 4.0*normalize(vec3(cos(2.75-3.0*mo.x), 0.7+(mo.y+1.0), sin(2.75-3.0*mo.x)));
    vec3 ta = vec3(0.0, 1.0, 0.0);
    vec3 ww = normalize( ta - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

    
    vec4 res = raymarch( ro, rd );
#if 0
    float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
    vec3 col = vec3(0.6,0.71,0.75) - rd.y*0.2*vec3(1.0,0.5,1.0) + 0.15*0.5;
    col += 0.2*vec3(1.0,.6,0.1)*pow( sun, 8.0 );
    col *= 0.95;
    col = mix( col, res.xyz, res.w );
    col += 0.1*vec3(1.0,0.4,0.2)*pow( sun, 3.0 );
#else
    vec3 col = res.xyz;
#endif    
    glFragColor = vec4( col, 1.0 );
}
