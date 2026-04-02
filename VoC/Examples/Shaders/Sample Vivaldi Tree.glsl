#version 420

// original https://www.shadertoy.com/view/XsS3Dm

uniform sampler2D backbuffer;
uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by sebastien durand /2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//#define FAST
//#define NO_LEAF

const float latitude=42., longitude=1.;

const vec3
    Julia=vec3(-0.1825,-0.905,-0.2085),
    ba=vec3(0.0,0.7,0.0),
    ba2=vec3(0.0,2.1,0.0);
const float 
    PI = 3.14159265358979323846,
    pi2 = 2.*PI,
    AU = 149597870.61, // Astronomical Unit = Mean distance of the earth from the sun - Km
    toRad = PI/180.,
    toDeg = 180./PI;

const float UTC_HOUR = 9.; 

const float 
    OLD_TREE = 1.3,
    VERY_OLD_TREE = 3.0;
float treeStep, frc, f2, thinBranch, rBranch, clpOld, clpVeryOld;  
int bEnd, fStart, fEnd;

float life, season;

float jGlobalTime;
float oobdb = 1.0/dot(ba,ba);
float oobd2 = 1.0/dot(ba2,ba2);

mat3 rotAA(in vec3 v, in float angle){//axis angle rotation
    float c=cos(angle);
    vec3  s=v*sin(angle);
    return mat3(v.xxx*v,v.yyy*v,v.zzz*v)*(1.0-c)+
           mat3(c,-s.z,s.y,s.z,c,-s.x,-s.y,s.x,c);
}

mat3 rmx =  rotAA(normalize(vec3(0.2174,1,0.02174)),1.62729)*1.35,
     mrot = rotAA(normalize(vec3(0.1,.95,.02)), 2.);

float hash(in float n) {return fract(sin(n) * 43758.5453123);}

// polynomial smooth min (k = 0.1);
float smin(in float a, in float b, in float k ){
    float h = clamp(.5+.5*(b-a)/k, .0, 1.);
    return mix(b,a,h) - k*h*(1.-h);
}

float Noise(in vec2 x) {
    vec2 p=floor(x), f=fract(x);
    f *= f*(3.-2.*f);
    float n = p.x + p.y*57.;
    return mix(mix(hash(n+ 0.), hash(n+ 1.),f.x),
               mix(hash(n+57.), hash(n+58.),f.x),f.y);

}

float noyz(vec2 x) {// a dumbed down version of iq's noise
//    return Noise(x);
    return .5;
    /*
    vec2 p=floor(x),f=fract(x);
    const float tw=117.0;
    float n=p.x+p.y*tw;
    float a=hash(n),b=hash(n+1.0),c=hash(n+tw),d=hash(n+tw+1.0);
    vec2 u=f*f*(3.0-2.0*f);
    return a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y;*/
}

vec2 opU(vec2 d1, vec2 d2 ) {
    return (d1.x<d2.x) ? d1 : d2;
}

float sdPlane( vec3 p ) {
    return p.y;
}

vec2 sdTree1(in vec3 p0) {
    float obj = 0.;
    //p.xz = mod(p.xz, 4.) - 2.;
        
    float text, dr=0.74074, dd, d0 = 100000., d = d0;

    // bounding round
//    d = distance(p0,vec3(0.,3.0,1.));
//    if (d>6.) return vec2(d-.1,10.);
    
    vec3 p = p0, pBest;
    vec2 pt;
    float brBest;
    float k=1.;
    for (int n = 0; n < 15; n++) {
        if (n<bEnd) {
            dd = (length(p-ba*clamp(dot(p,ba)*oobdb,0.0,1.05))-rBranch+p.y*thinBranch)*dr;
            if (dd < d) {
                d = smin(d,dd,.00155);
                pBest = p;
            }
        }
        else if(n==bEnd) {
            dd = (length(p-ba*clamp(dot(p,ba)*oobdb,-0.1,frc))-rBranch+p.y*thinBranch)*dr;
            if (dd < d) {
                d = smin(d,dd,dr*.055);
                pBest = p;
            }
            if (d<d0) {
                // TODO find best shade
                text = clamp(.7+.6*cos(pBest.y*50.+2.5*hash(pBest.x*pBest.y)), 0., 1.); //vec2(p.y*dr, atan(p.z,p.x)*0.003)*200.0)*dr;
                //d += (text*0.005);
                obj = 50. + 6.*text; // + (nBest<4 ? 100. : 0.);
            }
            k = .5;    
        }    
        else if (n>=fStart && n<=fEnd) { // Feuille
            if(n==fStart) { // Debut feuille
                p +=(noyz(p.zx*0.7900)*2.3 - vec3(0.5,0.2,0.5))*.08+sin(/*iGlobalTime*10. + */p.yzx*15.0)*.37;
            } 
            dd = (length(p-ba2*f2*clamp(dot(p.y,ba2.y)*oobd2,-5.,3.))-0.2+p.y*thinBranch)*dr;
            if (dd<d) {
                d = dd+.0001;
                obj = float(n-fStart+2);
            }
        }
        p.x = abs(p.x);
        p = p*rmx + k*Julia;
        dr *= 0.74074;
    }
    return vec2(d, obj);
}
    

vec2 sdTree(in vec3 p) {
    // Mix 2 tree to brake symetrie 

    p.z *= .8;
    p.xyz /= mix(life, 1.5, clpOld);

    p +=(.5-vec3(0.5,0.2,0.5))*0.2+sin(p.yzx*vec3(5.,6.,3.))*0.017;
    vec2 d1 = sdTree1(p);    
    p.y /= 1.3;
    //p.x-= .039;
    p.xyz *= mrot;
//    float scale  = mix(0.,1.,life*2.);
//    if (scale > 1.) scale = 1.;
//    p.xyz*= scale;
    vec2 d2 = sdTree1(p);    

    return vec2(smin(d1.x,d2.x, 0.05*clamp(3.-p.y,0.,10.)),  (d1.x<d2.x) ? d1.y : d2.y);
}
    
float sdLandscape(vec3 p) {
    float r = .4, d=.4*(1.-cos(p.x)*cos(p.z))+.2*Noise(p.zx);
    p.y += d+r;
    p.xz= mod(p.xz, .108) - .5*.108;
    return length(p)-r;
}

//----------------------------------------------------------------------

vec2 map( in vec3 pos )
{
    vec2 res = vec2(sdLandscape(pos), 1.0 );
    //return res;
    float a = mix(.025,.001,clpOld)*pos.y*cos(time*22.); // (life < OLD_TREE ? 22. : mix(22.,1.,clamp(life- OLD_TREE,0.,1.)))); 
    float  c = cos(a);
    float  s = sin(a);
    mat2   m = mat2(c,-s,s,c);
    vec2 v2 = m*pos.xz;
    pos = vec3(v2.x,pos.y,v2.y);
    pos.y *= (1.05+ mix(.04*cos(time/4.*6.28+0.8), 0., clpOld));

    return opU(res, sdTree(pos));
}

vec2 castRay( in vec3 ro, in vec3 rd, in float maxd )
{
    float precis = 0.004;
    float h=precis*2.0;
    float t = 0.0;
    float m = -1.0;
    vec2 res;
    for( int i=0; i<90; i++ )
    {        
        if (abs(h) > precis && t <= maxd ) { 
            t += h;
            res = map(ro+rd*t );
            h = res.x;

        }
    }
    m = res.y;
    if(t>maxd ) m=-1.0;
    return vec2( t, m );
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float maxt, in float k )
{
#ifdef FAST
    return 1.;
#else
    float res = 1.0, h, t = mint;
    for( int i=0; i<10; i++ ) {
        if (t < maxt) {
            h = map( ro + rd*t ).x;
            res = min( res, k*h/t );
            t += 0.04;
        }
    }
    return clamp( res, 0.0, 1.0 );
#endif    

}

vec3 eps = vec3( 0.001, 0.0, 0.0 );

vec3 calcNormal( in vec3 pos )
{
#ifdef FAST    
    float d = map(pos+eps.xyy).x;
    return normalize(vec3(
        map(pos+eps.xyy).x - d,
        map(pos+eps.yxy).x - d,
        map(pos+eps.yyx).x - d));
#else    
    return normalize(vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x));
#endif
}

float calcAO( in vec3 pos, in vec3 nor )
{
#ifdef FAST    
    return 1.;
#else
    float dd, hr=0.01, totao = 0.0, sca = 1.0;    
    for(int aoi=0; aoi<5; aoi++ )
    {
        dd = map(nor * hr + pos).x;
        totao += -(dd-hr)*sca;
        sca *= 0.75;
        hr += 0.05;
    }
    return clamp( 1.0 - 4.0*totao, 0.0, 1.0 );
#endif
}

//--------------------------------------------------------------------------
// Rolling hills by Dave Hoskins (https://www.shadertoy.com/view/Xsf3zX)
//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
vec3 sunLight  = normalize( vec3(  0.35, 0.2,  0.3 ) );
vec3 cameraPos;
vec3 sunColour = vec3(1.0, .75, .6);

vec3 GetSky(in vec3 rd, in bool withSun) {
    float sunAmount = withSun ? max( dot( rd, sunLight), 0.0 ) : 0.0;
    return clamp( 
            mix(vec3(.1, .2, .3), vec3(.32, .32, .32), pow(1.0-max(rd.y,0.0),6.)) +
            sunColour * sunAmount * sunAmount * .25 +
            sunColour * min(pow(sunAmount, 800.0)*1.5, .3)
        , 0.0, 1.0);
}

//--------------------------------------------------------------------------
// Merge grass into the sky background for correct fog colouring...
vec3 ApplyFog(in vec3  rgb, in float dis, in vec3 sky){
    return mix(rgb, sky, clamp(dis*dis*0.003, 0.0, 1.0));
}

// Calculate sun light...
void DoLighting(inout vec3 mat, in vec3 pos, in vec3 normal, in vec3 eyeDir, in float dis)
{
    float h = dot(sunLight, normal);
    mat = mat * (max(h, 0.0)+.2);
    // Specular...
    vec3 R = reflect(sunLight, normal);
    float specAmount =.2* pow( max(dot(R, normalize(eyeDir)), 0.0), 40.0) * (.5+smoothstep(8.0, 0.0, pos.y)*4.0);
    mat = mix(mat, sunColour, specAmount);
}

vec3 render(in vec3 ro, in vec3 rd) { 
    vec3 col = vec3(0.0);
    vec2 res = castRay(ro,rd,20.0);
    float t = res.x, m = res.y;

    if( m>-0.5 ) {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );

        if (m >= 2. && m<10.) {
            col = mix(vec3(.35*m,3.-.08*m,0.), vec3(3.-.08*m,(m*.35),0.), season*1.3); // Automne
        }
        else if (m>=50.) {
            col = vec3(.8) + vec3(.2,.2,.2)*(m-50.);
        } else {
            col = vec3(0.3,0.9,0.3);
        } 
        col *= .5;
        
        float ao = calcAO( pos, nor );

    //    vec3 lig = sunLight; //normalize( vec3(-0.6, 0.7, -0.5) );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, sunLight ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-sunLight.x,0.0,-sunLight.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);

        float sh = 1.0;
        if( dif>0.02 ) { sh = softshadow( pos, sunLight, 0.02, 10.0, 7.0 ); dif *= sh; }

        vec3 brdf = 
            ao*0.20*(amb*vec3(0.10,0.11,0.13) +
                     bac*vec3(0.15,0.15,0.15)) +
            1.20*dif*vec3(1.00,0.90,0.70);

        float pp = clamp( dot( reflect(rd,nor), sunLight ), 0.0, 1.0 );
        float spe = sh*pow(pp,16.0);
        float fre = ao*pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );

        col = col*brdf + vec3(1.0)*col*spe + 0.2*fre*(0.5+0.5*col);
        col *= exp( -0.01*t*t );    
        col = ApplyFog( col, res.x, GetSky(rd, true));

//        DoLighting(col, pos, nor, rd, res.x);

    } else {
        col = GetSky(rd, true);
        col = ApplyFog( col, res.x, col);
    }
    
    return vec3( clamp(col,0.0,1.0) );
}

//*********************************************************************************
//    +----------------------------------------------------------------+
//    |   Position of the sun in the sky at a given location and time  |
//    +----------------------------------------------------------------+
// based on LOW-Precision formulae for planetary positions by T.C. Van Flandern and H-F. Pulkkinen
// http://articles.adsabs.harvard.edu/cgi-bin/nph-iarticle_query?1979ApJS...41..391V&defaultprint=YES&filetype=.pdf

float julianDay2000(in int yr, in int mn, in int day, in int hr, in int m, in int s) {
    int im = (mn-14)/12, 
        ijulian = day - 32075 + 1461*(yr+4800+im)/4 + 367*(mn-2-im*12)/12 - 3*((yr+4900+im)/100)/4;
    float f = float(ijulian)-2451545.;
    return f - 0.5 + float(hr)/24. + float(m)/1440. + float(s)/86400.;
}

float julianDay2000(in float unixTimeMs) {
    return (unixTimeMs / 86400.0) - 10957.5;// = + 2440587.5-2451545; 
}

vec2 SunAtTime(in float julianDay2000, in float latitude, in float longitude) {
    float zs,rightAscention, declination, sundist,
        t  = julianDay2000,    //= jd - 2451545., // nb julian days since 01/01/2000 (1 January 2000 = 2451545 Julian Days)
        t0 = t/36525.,             // nb julian centuries since 2000      
        t1 = t0+1.,                 // nb julian centuries since 1900
        Ls = fract(.779072+.00273790931*t)*pi2, // mean longitude of sun
        Ms = fract(.993126+.0027377785 *t)*pi2, // mean anomaly of sun
        GMST = 280.46061837 + 360.98564736629*t + (0.000387933 - t0/38710000.)*t0*t0, // Greenwich Mean Sidereal Time   
// position of sun
        v = (.39785-.00021*t1)*sin(Ls)-.01*sin(Ls-Ms)+.00333*sin(Ls+Ms),
        u = 1.-.03349*cos(Ms)-.00014*cos(2.*Ls)+.00008*cos(Ls),
        w = -.0001-.04129 * sin(2.*Ls)+(.03211-.00008*t1)*sin(Ms)
            +.00104*sin(2.*Ls-Ms)-.00035*sin(2.*Ls+Ms);
// calcul distance of sun
    sundist = 1.00021*sqrt(u)*AU;
// calcul right ascention
    zs = w / sqrt(u-v*v);
    rightAscention = Ls + atan(zs/sqrt(1.-zs*zs));
// calcul declination
    zs = v / sqrt(u);
    declination = atan(zs/sqrt(1.-zs*zs));

// position relative to geographic location
    float
        sin_dec = sin(declination),   cos_dec = cos(declination),
        sin_lat = sin(toRad*latitude),cos_lat = cos(toRad*latitude),
        lmst = mod((GMST + longitude)/15., 24.);
    if (lmst<0.) lmst += 24.;
    lmst = toRad*lmst*15.;
    float
        ha = lmst - rightAscention,       
        elevation = asin(sin_lat * sin_dec + cos_lat * cos_dec * cos(ha)),
        azimuth   = acos((sin_dec - (sin_lat*sin(elevation))) / (cos_lat*cos(elevation)));
    
    return vec2(sin(ha)>0.? azimuth:pi2-azimuth, elevation);
}

// X = north, Y = top
vec3 getSunVector(in float jd, in float latitude, in float longitude) {
    vec2 ae = SunAtTime(jd, latitude, longitude);
    return normalize(vec3(-cos(ae.x)*cos(ae.y), sin(ae.y), sin(ae.x)*cos(ae.y)));
}
//*********************************************************************************

void main( void )
{
    // For Benjamin button tree, inverse the sign !
    jGlobalTime = 8.+time;
        
    life =.5+mod(jGlobalTime,68.)/24.;
    season = mod(jGlobalTime, 4.)/4.;
    
    // Tree params    
    treeStep = clamp(life*life,0.,1.);
    frc = fract(treeStep*10.);
    bEnd = int(treeStep*10.);
    //float a = season*(3.14/.8);
    
    f2 = sin(season*(3.14/.8)); /*- .33*cos(a*3.) + .2*cos(a*5.)*/;
    f2 = treeStep*treeStep*clamp(2.*f2,0.,1.);
    f2 = mix(f2, 0., clamp(2.*(life-OLD_TREE),0.,1.));
#ifdef NO_LEAF
    fEnd = fStart = 20;
#else
    fStart = (season>.8||life<.6||life>1.5*OLD_TREE) ? 20 : bEnd+2;//bEnd>6? bEnd+2:8; //1+int(3.*(sin(season*(3.14/.8))));
    fEnd =  fStart + (bEnd<8 ? 1:3);
#endif
    thinBranch=0.018;
    rBranch = mix(0.01,0.07,treeStep);
    clpOld = clamp(life-OLD_TREE,0.,1.);
    clpVeryOld = clamp(life-VERY_OLD_TREE,0.,1.);
    
    float day = floor(season*365.)+100.;
    float jd2000 = julianDay2000((day*24.+UTC_HOUR)*3600.);
    sunLight = getSunVector(jd2000, latitude, longitude).xyz;
    
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    vec2 mo = vec2(0.0,0.0);
         
    float time = 15.0; // + iGlobalTime;

    // camera    
    vec3 ro = vec3( -6.+3.*cos(0.1*time + 2.*PI*mo.x), max(.75,-.5 + 2.*PI*mo.y), 6. + 3.*sin(0.1*time + 2.*PI*mo.x) );
    vec3 ta = vec3( -0.5, 1.4, 0.5 );
    
    // camera tx
    vec3 cw = normalize( ta-ro );
    vec3 cp = vec3( 0.0, 1.0, 0.0 );
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    vec3 rd = normalize( p.x*cu + p.y*cv + 2.5*cw );
    
    vec3 col = render( ro, rd );

    col = sqrt( col );

    col *= mix(1., 5., 3.*clpVeryOld); // I see the light !
    col *= pow(16.0*q.x*q.y*(1.-q.x)*(1.-q.y), mix(.05, .2, clamp(life-VERY_OLD_TREE-.3,0.,1.))); // vigneting
    glFragColor=vec4( col, 1.0 );
}
