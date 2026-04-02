#version 420

//original https://www.shadertoy.com/view/XdSXDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Pustules by nimitz (twitter: @stormoid)

/*
    Trying to achive high percieved detail with while keeping
    computational cost to a minimum.

    The render is done in 3 steps. The base raymarched geometry,
    which is then followed by a refined domain raymarching loop    on more 
    complex geometry (2 layers of 8-tap 3d voronoi displacement).
    And finally fine detail is added with gradient bump mapping on a 3d field.

    Should run pretty fast even in fullscreen.
*/

//#define USE_DISNEYS_DIFFUSE

#define FAR 7.
#define time2 time*0.5
#define PI 3.14159265

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}

float smin( in float a, in float b, in float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 rand22(in vec2 p){
    return fract(vec2(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * 49.077)));
}
float hash( float n ) { return fract(sin(n)*43758.5453); }

//Trying to get away with 8-tap 3d voronoi
vec3 vor(in vec3 p)
{
    p *= 4.;
    float pri = -1.;
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float rid = -1.;
    vec2 rz = vec2(2.);
    float dc = 0.;
    for (int i=-1; i<=0; i++) 
    for (int j=-1; j<=0; j++) 
    for (int k=-1; k<=0; k++) 
    {
        vec3 ir = ip + vec3(i, j, k);
        vec3 fr = fp - vec3(i, j, k);
        vec2 uid = ir.xy * vec2(0.037, 0.119) + ir.z * 0.00301;
        vec2 rand = rand22(uid)*.66+.67;
        vec3 pp = fr -(vec3(rand.x));
        float d = dot(pp, pp);
        if (d < rz.x)
        {
            rz.y = rz.x;
            rz.x = d;
            dc = d;
            rid = hash(dot(uid,vec2(1.01,17.01)));
        }
        else if(d < rz.y)
    {
        rz.y = d;
    }
    }

    rz.y = rz.y-rz.x;
    return vec3(rz,rid);
}

float map(vec3 p)
{
    float mv =sin(time2*1.5+sin(time2*2.7))*0.51;
    float d = length(p-mv)-.51;
    d = smin(d,length(p+mv)-.45,1.9);
    
    return d;
}

float march(in vec3 ro, in vec3 rd)
{
    float precis = 0.001;
    float h=precis*2.0;
    float d = 0.;
    for( int i=0; i<70; i++ )
    {
        if( abs(h)<precis || d>FAR ) break;
        d += h;
        float res = map(ro+rd*d)*1.1;
        h = res;
    }
    return d;
}
vec2 mapHD(vec3 p)
{
    float d = map(p);
    float id = 0.;
    vec3 rz = vor(p*1.1)*0.1;
    d += rz.x;
    id = rz.y+rz.z*0.7;
    rz =  vor(p*2.1)*0.05;
    d += rz.x;
    id += rz.y+rz.z;
    
    return vec2(d*0.9,id);
}

vec2 marchHD(in vec3 ro, in vec3 rd, in float d)
{
    float maxd = FAR;
    float precis = 0.008;
    float h=precis*2.0;
    float id = 0.;
    for( int i=0; i<100; i++ )
    {
        if( abs(h)<precis || d>maxd ) break;
        d += h;
        vec2 res = mapHD(ro+rd*d);
        h = res.x;
        id = res.y;
    }
    if (d>maxd)d = 1000.;
    return vec2(d,id);
}

vec3 normal(in vec3 p, in vec3 rd)
{  
    vec2 e = vec2(-1., 1.)*0.005;   
    vec3 n = normalize(e.yxx*mapHD(p + e.yxx).x + e.xxy*mapHD(p + e.xxy).x + 
                     e.xyx*mapHD(p + e.xyx).x + e.yyy*mapHD(p + e.yyy).x ); 
    
    float k = dot(-rd,n);
    return n + rd*k*(0.5-0.5*sign(k));
}

//from iq
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

float ssin(float x) 
{
    float rz = sin(x)*0.5+0.5;
    return rz*rz;
}

float fbm(vec3 p) 
{
    float t = 0.;
    float z = 4.;
    for (int i=0;i<3;i++)
    {
        t += (noise(p) / z);
        z *= 3.;
        p *= 2.8;
    }
    return t;
}

float bnoise(in vec3 p)
{
    float n = ssin(fbm(p*21.)*40.)*0.003;
    return n;
}

vec3 bump(in vec3 p, in vec3 n)
{
    vec2 e = vec2(.01,0);
    float n0 = bnoise(p);
    vec3 d = vec3(bnoise(p+e.xyy)-n0, bnoise(p+e.yxy)-n0, bnoise(p+e.yyx)-n0)/e.x;
    n = normalize(n-d*2.);
    return n;
}

//shadows and AO from iq
float shadow(in vec3 ro, in vec3 rd, in float mint, in float tmax)
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<10; i++ )
    {
        float h = mapHD(ro + rd*t).x;
        res = min( res, 4.*h/t );
        t += clamp( h, 0.02, .20 );
        if(h<0.001 || t>tmax) break;
    }
    return clamp( res, 0.0, 1.0 );

}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = mapHD( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

float hornerD(in float f, in float x){return 1. + (f - 1.) * exp2((-5.55473 * x - 6.98316) * x);}

//mostly from: http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
vec3 shade(in vec3 pos, in vec3 n, in vec3 rd, in vec3 l, in vec3 lcol, in vec3 alb)
{
    //material data (could be passed in)
    const float rough = 0.45;
    const vec3 F0 = vec3(.4);
    const float kr = .4; //diff/spec ratio
    
    float nl = dot(n, l);
    float nv = dot(n, -rd);
    vec3 col = vec3(0.);
    float ao = calcAO(pos, n);
    if (nl > 0. && nv > 0.)
    {
        vec3 haf = normalize(l - rd);
        float nh = dot(n, haf); 
        float vh = dot(-rd, haf);
        
        #ifdef USE_DISNEYS_DIFFUSE
        float fd90 = 0.5+ 2.*vh*vh*rough;
        vec3 dif = nl*alb*hornerD(fd90, nl)*hornerD(fd90, nv);
        #else
        vec3 dif = alb*nl;
        #endif
        
        float a = rough*rough;
        float a2 = a*a;
        float dn = nh*nh*(a2 - 1.) + 1.;
        float D = a2/(PI*dn*dn);
        
        float k = pow( rough*0.5 + 0.5, 2.0 )*0.5;
        float nvc = max(nv,0.);
        float gv = nvc/(nvc*(1.-k) + k);
        float gl = nl/(nl*(1.-k) + k);
        float G = gv*gl;

        vec3 F = F0 + (1. - F0) * exp2((-5.55473 * vh - 6.98316) * vh); //Horner       
        
           vec3 spe = D*F*G/(4.*nl*nv);
        col = mix(spe,dif,kr);
        #if 0 //clearcoat
        n = normalize(n - normalize(pos) * 0.5);    
        col += vec3(specular(n,l,rd,50.0))*0.2;
        #endif
        col *= shadow( pos, l, 0.05, 10.);
        col *= lcol;
    }
    else //complete hack
    {
        col = alb*exp2(rough)*0.02*ao*(.5+ao);
    }
    col += 0.2*alb*ao;
    return col;
}

//Reinhard based tone mapping
vec3 tone(vec3 color, float gamma)
{
    float white = 2.;
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
    color *= toneMappedLuma / luma;
    color = pow(color, vec3(1. / gamma));
    return color;
}

void main(void)
{    
    vec2 bp = gl_FragCoord.xy/resolution.xy;
    vec2 p = bp*2.-1.;
    p.x*=resolution.x/resolution.y;
    //vec2 mo = iMouse.xy / iResolution.xy-.5;
    vec2 mo=vec2(0.0,0.0);
    mo = (mo==vec2(-.5))?mo=vec2(0.5,0.3):mo;
    mo.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(0.,0.,4.5);
    vec3 rd = normalize(vec3(p,-3.6));
    mat2 mx = mm2(time2*.04+mo.x*6.);
    mat2 my = mm2(time2*0.06+mo.y*6.); 
    ro.xz *= mx;rd.xz *= mx;
    ro.xy *= my;rd.xy *= my;
    
    vec3 ligt = normalize( vec3(-.5, 0.2, -0.2) );
    float edl = dot(rd,ligt)*0.5+.5;
    vec3 bgvor = vor(rd*4.2)*0.35;
    bgvor += vor(rd*9.)*0.25;
    bgvor += vor(rd*25.)*0.1;
    vec3 bgcol = ((bgvor.z*.5 + 0.1)*(.5 - bgvor.x*1.5*(1.5 - bgvor.y*10.)))
        *(sin(vec3(1,1.5,1.7) + noise(rd*24.))*0.5 + 0.5);
    vec3 lcol = vec3(.9,.85,.75)*1.5;
    vec3 col = bgcol*0.8+edl*bgcol+(pow(edl,150.)+smoothstep(0.998,1.,edl))*lcol;
    
    float rz = march(ro,rd);
    if ( rz < FAR )
    {
        vec2 rzH = marchHD(ro,rd,rz);
        float rzHD = rzH.x;
        rz = rzH.x;
        if (rzHD < FAR)
        {
            vec3 pos = ro+rzHD*rd;
            vec3 nor= normal(pos, rd);
            nor = bump(pos,nor);
            col = sin(vec3(1.95,1.63,1.4)+rzH.y*13.+8.55)*.6+.9;
            col = shade(pos, nor, rd, ligt, lcol,col);
        }
    }
    
   col = tone(col,.9)*1.4;
   col *= pow(16.0*bp.x*bp.y*(1.0-bp.x)*(1.0-bp.y),0.1);
   
    glFragColor = vec4( col, 1.0 );
}
