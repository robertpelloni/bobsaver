#version 420

// original https://www.shadertoy.com/view/3dVfDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Happy Christmas to you all the great Shadertoy community !

// SylvainLC 2020 
//
// I'am just an hobbyist, no comparison with Shadertoy's top contributors.
// But seems Shadertoy allows anybody to learn and have fun, that IS great.
// Thanks to IQ, BigWings, Shane, Fabrice and you all guys ! 
// You are so good at teaching modeling with curves, colors, lighing, fractals 
// all these magical procedural technics ... 
// many thanks for your great tutorials, demos, and also your kind comments.

// Here is my personal Shadertoy notebook if this can help someone to begin
// https://hackmd.io/@NmkGBTybRuKG4gBXN_rlmA/SkE6XqmDw

#define MAX_STEPS 256
#define MAX_DIST 100.
#define SURF_DIST .001
#define TAU 6.283185

#define S smoothstep
#define T time

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float sdCappedCylinder( vec3 p, float r, float h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdVerticalCapsule( vec3 p, float r, float h )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}
// https://www.shadertoy.com/view/lsS3WV
// arc length of archimedian spiral
float arclength(float theta) {
    const float a=1.0/TAU;
    float d = theta * sqrt(abs(1.0 - theta*theta));
    return 0.5 * a * (d + log(d+0.01));
}

// Sylvain LC based on https://www.shadertoy.com/view/lsS3WV
// The purpose of this fonction is to generate a distance field for bounding an archimedian spiral
// but at the same time generate coordinates for folding some primitives inside it.
// Hope this can be inspiring. I had a lot of fun to get it working.
vec2 spiral(vec2 p,float tmin,float tmax) {
    float rp = length(p);  // r of point p 
    float tpr = atan(p.y, p.x); // theta of p in Radian
    float tp = tpr/TAU;      // theta of p rotation value mapped to -0.5 ... 0.5
    float turn = (rp - tp);  // at first turn when the point is on the spiral then rp = tp (theta p).
                             // when (rp-tp) reaches 1 we get on the next turn of the spiral.
                             // we can find negative value here 
                             // in the inner part of the spiral
                             // I avoided this zone, my head is hatching !
                             // I will focus only starting the second turn where distance are well approximated
                             // Note : there is discontinuity for turn at x < 0 and y = 0
                             // rp reaches 0.5 and tp switch from 0.5 to -0.5
                             // but this is a continuous change in floor and fract, kind of magic to me.                            
    float count=floor(turn); // counting the turns / automatically manage atan discontinuity
    float delta=fract(turn); // 0 on the spiral
    float ts=tp+count;       // theta of inner border of the spiral regarding p (0 ... TAU mapped to 0 ... 1 ) 
    ts+=step(0.5,delta);     // after 0.5 we are more near the next turn of the spiral      
    delta = delta > 0.5 ? delta-1.0 : delta;  
      float d=delta;           // simplified distance when we are between 2 spires
    if ( ts <= tmin )   {    // starting point of the spiral
        delta-=floor(tmin-ts)+1.0;
        float dStart=-length(p-tmin*vec2(cos(tmin*TAU),sin(tmin*TAU))); 
        d=max(delta,dStart);
    }
    if ( ts >= tmax )   {    // ending point of the spiral
        delta+=floor(ts-tmax);
        float dEnd=length(p-(tmax+1.0)*vec2(cos(tmax*TAU),sin(tmax*TAU))); 
        d=min(delta,dEnd);
    }
    return vec2(d,ts);       // d is signed, allowing to use it as y coordinate
}

float sdHexagram( in vec2 p, in float r )
{
    const vec4 k = vec4(-0.5,0.86602540378,0.57735026919,1.73205080757);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= 2.0*min(dot(k.yx,p),0.0)*k.yx;
    p -= vec2(clamp(p.x,r*k.z,r*k.w),r);
    return length(p)*sign(p.y);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec2 niceSpiral(vec3 p) {
    float atime=0.0;
    float time=mod(T,20.0);
    if ( time < 10.0 )      atime=S(5.0,10.0,time); 
    else if ( time < 20.0 ) atime=S(20.0,15.0,time);
    p.xz*=Rot(atime*3.14159);
    float rr = 1.0+ 1.7*(0.5-0.5*atime); // to increase the inter spire size of the spiral
 //   rr = 1.00; // 1 = nominal value, the spiral is the more tight as possible
    float tmin = 1.0; // caped spiral not below 1.0 turn for good approximated distances
    float tmax = tmin+2./rr; //-.4*sin(time*.1);
    vec2 pStart = -rr*tmin*vec2(cos(tmin*TAU),sin(tmin*TAU)); // makes the starting point fixed in space
   // p.xz-=pStart;
    vec2 s = spiral(p.xz/rr,tmin,tmax); // side distance and theta01 of spiral
 //   p.y+=0.1*sin(time*.53+22.25*s.y); // you can try this for some waves
    float bound = length(vec2(p.y,s.x*rr));
    if ( bound >= rr*.5 ) return vec2(bound-rr*.49,0.0); // this is for bound the inner part of the spiral
    float d = bound;
    float lmin=arclength(tmin*TAU);
    float lmax=arclength((tmax+1.0)*TAU)-lmin;
    float lp=arclength(s.y*TAU)-lmin;

    vec3 q = vec3(lp *rr, p.y, s.x * rr ); // spiral space
    vec3 intube = q; // tube space
    intube.yz*=Rot(q.x*3.14159*.5);
    intube.yz = abs(intube.yz)-0.25; // 4 for the price of one
    intube.yz = (intube.yz + vec2(intube.z, -intube.y))*sqrt(0.5); // Shortcut for 45-degrees rotation https://www.shadertoy.com/view/WsGyWR
    vec2 ropeID=step(0.0,intube.yz);
    intube.yz = abs(intube.yz)-0.05;
    intube.yz*=Rot(q.x*3.14159*4.0);
    intube.yz = abs(intube.yz)-0.02;
    float dt = min(d,sdVerticalCapsule(intube.yxz-vec3(0.0,.1,0.0)*rr,0.02,rr*lmax-0.2));
    
    vec3 inStar = q; // -vec3(r*(lmax-0.5),0.0,0.0); // hexagram space
    float n = round(lmax*2.0*rr);
    float id = clamp(round(lp*2.0*rr),1.0,n-1.0);
    inStar.x-=id*.5;
    inStar.yz*=Rot(id*.25*3.14159); // can be replaced by 45-degree
    
    // Balls :-)
    vec3 inBalls = q; 
    float bid = clamp(round((lp*2.0+0.25)*rr),1.0,n-1.0);
    inBalls.x-=bid*.5-.25;
    inBalls.yz*=Rot(bid*.25*3.14159); // can be replaced by 45-degree
    inBalls.yz=abs(inBalls.yz);

    // materials : 1.0=spiral 2.x=tubes 3.x=stars and squares 4.0=inside spiral 5.0 Balls
    float m=0.0; // materials
    float outer = bound-.25;
    if ( outer < d ) { d = outer ; m = 1.0; }
    // change sign to have holes or bumps
    // Hello Shane, you recognized your blicking little windows trick :-) ?
    float stars = -min(sdHexagram(inStar.xy,0.045),(sdBox(abs(inStar.xz)-0.033,vec2(0.022)+.006)));
    if ( stars > d ) { d=stars ; m = 3.0; }
    float balls = length(inBalls-vec3(0.0,0.26,0.26))-.08*(fract(bid/2.0)*.4+.6);
    if ( balls < d ) { d=balls ; m = 5.0+bid/1024.0; }
    if ( dt < d ) { d=dt ; m= 2.0 + (ropeID.x+2.0*ropeID.y)/1024.0; };
    float inner=bound-.22;
    if ( inner < d ) { d = inner; m=4.0+id/1024.0 ; }
    // distance, material
    return vec2(d,m); 
}

vec2 GetDistAndMat(vec3 p) {
    float scale=1.0/2.0;
    
    vec2 model = niceSpiral(p.xyz/scale) ;
    model.x*=scale;
    if ( model.x > p.y+1.5 ) model = vec2(p.y+1.5,1.0);
    return model;
}

float GetDist(vec3 p) {
    return GetDistAndMat(p).x;
}

vec2 RayMarch(vec3 ro, vec3 rd) {
    float dO=0.0;  
    vec2 dS;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        dS = GetDistAndMat(p);
        dO += dS.x*.9; //bug
        if(dO>MAX_DIST || abs(dS.x)<SURF_DIST) break;
    }    
    return vec2(dO,dS.y);
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
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

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float calcLight(vec3 n) {
    float directionality=0.75;
    float sharpness=0.5;
    n = erot(n, vec3(0,1,0),0.0);
    float spec = length(sin(n * 3.) * directionality + (1. - directionality)) / sqrt(3.);
    spec = spec + pow(spec, 10. * sharpness);
    return spec;
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = GetDist( opos );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);
    vec3 bgcol=vec3(.1+.01*Hash21(uv))*(.5-abs(uv.y));
    
    vec3 target = vec3(0,-1.5,0);
    vec3 ro = vec3(0, 1.0, 2.3);
    vec2 m = mouse*resolution.xy.xy / resolution.xy-.5;
    float time=mod(T,30.0);
    float atime=1.0;
    //if ( mouse*resolution.xy.x > 0.0 ) {
    //    ro.yz *= Rot(m.y*3.14*.5);
    //    ro.xz *= Rot(-m.x*6.2831*2.0);
    //} else 
    if ( time < 15.0 ) { 
        atime=S(0.0,7.5,7.5-abs(time-7.5));
        ro = mix(ro,vec3(0, 1.0, 4.3),atime);
        ro.yz *= Rot(atime*.3*3.14*.5);
        target = mix(target,vec3(0,.5,0),atime);
     } else { 
        atime=S(0.0,7.5,7.5-abs(time-15.0-7.5));
        ro = mix(ro,vec3(0, 1.0, 4.0),atime);
        ro.yz *= Rot(-.3*3.14*.5*atime);
        target = mix(target,vec3(0,-.5,0),atime);
     }
    
    vec3 rd = GetRayDir(uv, ro, target, 1.);
    vec2 d = RayMarch(ro, rd);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        vec3 nor=n;
        vec3 pos=p;
        vec3 c=vec3(0);
        float ks = 1.0; // 
        // https://iquilezles.org/www/articles/outdoorslighting/outdoorslighting.htm
        // lighting , in these few lines there is all the magic thanks to IQ tutorials
        // I say magic because to me it sound like magic, but there is some true science here :-)
        // This one seems adapted for outdoor scene with Sun, Sky and bouncing light
        // Occlusion seems to add some details so I added it, but it has a performance cost.
        float occ = calcOcclusion( p, n );
        vec3  sun_lig = normalize( vec3(0.6, 0.35, 0.5) );
        float sun_dif = clamp(dot( nor, sun_lig ), 0.0, 1.0 );
        vec3  sun_hal = normalize( sun_lig-rd );
        // some workaround for isues with shadows
        float sun_sha = d.y == 1.0 ? step(MAX_DIST,RayMarch( pos+0.001*nor, sun_lig ).x) : 1.0;
        float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
        float sky_dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float bou_dif = sqrt(clamp( 0.1-0.9*nor.y, 0.0, 1.0 ))*clamp(1.0-0.1*pos.y,0.0,1.0);
        float blink = 0.0;
        // materials  
        if ( d.y >=5.0 ) {            // Balls
            float ballID = fract(d.y)*1024.0;
            c = fract(ballID*.5) > 0.0 ? vec3(0.6,0.1,0.2) : vec3(0.6,0.6,0.2);
            vec3 r = reflect(rd, n);
            c = .5*calcLight(r) * c;  //https://www.shadertoy.com/view/tlscDB            
            blink = 6.0*S(.2,1.0,abs(sin(5.0*ballID/TAU+2.0*T))); // noob blinking
        } else if ( d.y >=4.0 ) {     // bright inside spiral
            float starID=fract(d.y)*1024.0;
            blink = 6.0*S(.2,1.0,abs(sin(5.0*starID/TAU+3.0*T))); // noob blinking
            c = vec3(0.5,0.5,0.2)*.3;
        } else if ( d.y >=3.0 ) {     // stars and squares borders
            c = vec3(0.6,0.1,0.2);
            vec3 r = reflect(rd, n);
            c = .5*calcLight(r) * c;  // to get metal effect https://www.shadertoy.com/view/tlscDB            
        } else if ( d.y >=2.0 ) {     // tubes 
            float ropeID=fract(d.y)*1024.0;
            c = ropeID>2.0 ? vec3(0.5,0.5,0.01)*.25 : vec3(0.01,0.6,0.01)*.1;
        } else if ( d.y >=1.0 ) {     // spiral and floor 
            c = vec3(0.3,0.3,0.2);
            vec3 r = reflect(rd, n);
            c = calcLight(r) * vec3(.5,.5,.2)*.3;  //https://www.shadertoy.com/view/tlscDB
        }
        vec3 lin = vec3(0.0);
        time=mod(T,33.0);
        float suntime=1.0-(S(11.0,15.0,time)-S(25.0,30.0,time));
        lin += sun_dif*vec3(8.10,6.00,4.20)*sun_sha*suntime;  // seems the sun is raising
        lin += sky_dif*vec3(0.50,0.70,1.00)*occ*2.0;
        lin += bou_dif*vec3(0.40,1.00,0.40)*occ*2.0;
        col = c*lin;
        col += c*blink;
        col += sun_spe*vec3(8.10,6.00,4.20)*sun_sha;
        // Shane piece of advice
        float fog = 1./(1. + d.x*.125*0.0 + d.x*d.x*.05);
        col = mix(bgcol, col, fog);
        
    } else {
        col = bgcol;
    }
    
    col = pow(col, vec3(.4545));    // gamma correction    
    glFragColor = vec4(col,1.0);
}
