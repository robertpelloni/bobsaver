#version 420

// original https://www.shadertoy.com/view/4tXGWn

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

// Created by sebastien durand - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159279

float Anim;
mat2 Rotanim;

float ca3 = cos(.28), sa3 = sin(.28);   
mat2 Rot3 = mat2(ca3,-sa3,sa3,ca3);

// ----------------------------------------------------

float udRoundBox( vec3 p, vec3 b, float r ){
      return length(max(abs(p)-b,0.))-r;
}

vec2 sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    float dd = cos(3.14*h*2.5);  // Little adaptation
    return vec2(length(pa - ba*h) - r*(1.-.1*dd+.4*h), 30.-15.*dd); 
}

vec2 smin(in vec2 a, in vec2 b, in float k ) {
    float h = clamp( .5 + (b.x-a.x)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.-h);
}

float smin(in float a, in float b, in float k ) {
    float h = clamp( .5 + (b-a)/k, 0., 1. );
    return mix(b, a, h) - k*h*(1.-h);
}

vec2 min2(in vec2 a, in vec2 b) {
    return a.x<b.x?a:b;
}

// ----------------------------------------------------

vec2 spiralTail(in vec3 p) {
    float a = atan(p.y,p.x)+.2*Anim;
    float r = length(p.xy);
    float lr = log(r);
    float th = 0.475-.25*r; // epaisseur variable en fct de la distance
    float d = fract(.5*(a-lr*10.)/PI); //apply rotation and scaling.
    
    d = (0.5-abs(d-0.5))*2.*PI*r/10.; //length(c);
      d *= 1.1-1.1*lr;  // espacement variable en fct de la distance
   
    r+=.05*cos(a*60.); // bosse radiales
    r+=(.2-.2*(smoothstep(0.,.08, abs(p.z))));

    return vec2(
        max(sqrt(d*d+p.z*p.z)-th*r, length(p-vec3(.185,-.16,0))-1.05),
        abs(30.*cos(10.*d)) + abs(20.*cos(a*10.)));
}

vec2 body(in vec3 p) {
    const float scale = 3.1;
    
    p.y=-p.y;
    p.x += 2.;
    p/=scale;
    
    float a = atan(p.y,p.x);
    float r = length(p.xy);
    float d = (.5*a-log(r))/PI; //apply rotation and scaling.
    float th = .4*(1.-smoothstep(.0,1.,abs(a+.35-Anim*.05)));    
 
    d = (1.-2.*abs(d-.5))*r*1.5;
    
   // r +=.005*cos(80.*d); // bosse longitudinale
    r+=.01*cos(a*200.); // bosse radiales
    r-=.2*(smoothstep(0.,.1,abs(p.z)));
    
    float dis = sqrt(d*d+p.z*p.z)-th*r;
     dis *= scale;
    dis = max(dis, length(p-vec3(.77,.05,0))-.7);
    return vec2(dis, abs(30.*cos(17.*d)) + abs(20.*cos(a*20.)));
}

vec2 head(in vec3 p) {
    p.y += .2+.05*Anim;
    p.xy *= Rotanim;

    vec3 pa1 = p, ba = vec3(1.,-.2,-.3);
    pa1.z = p.z-.25;
    
    float h = clamp(dot(pa1, ba), 0.0, 1.0 );
    pa1.x -= h;

    // Head
    float dh = length(pa1) - .8*(-.5+1.3*sqrt(abs(cos(1.5701+h*1.5701))))+.08*(1.+h)*smoothstep(0.,.2,abs(p.z));
    dh = max(-p.y-.2, dh); 
    dh += -.04+.04*(smoothstep(0.,.2,abs(p.z)));
    dh = min(dh, max(p.x-1.35,max(p.y+.3, length(p-vec3(1.1-Anim*.15,.32,-.1))-.85)));//,.2);
    dh += .01*cos(40.*h) -.06;
    
    // Eyes
    const vec3 eye = vec3(-.16,-.05,.16);
  //eye.xy *= Rotanim;
    float de = max(length(p-vec3(.7,.26,.45))-.3, -(length(p-vec3(.7,.26,.45) - eye)-.08-.06*abs(Anim)));
    vec2 dee = min2(vec2(de,20.+1000.*abs(dot(p,eye))), vec2(length(p-vec3(.7,.26,.45))-.2, -102.));
  
    return smin(dee, vec2(dh*.8, 40.- abs(20.*cos(h*3.))) ,.06); 
}
    

vec2 support(vec3 p, vec2 c, float th) {
    p-=vec3(-2.5,-.7,0);
    float d = length(max(abs(p-vec3(0,-2,.75))-vec3(.5,2.5,.1),0.0))-.1; 
    d = min(d, length(p-vec3(0,-6.5,0)) - 3.);          
    
    p.xy *= Rot3; 
    d = min(d, max(length(max(abs(p)-vec3(4,3,.1),0.0))-.1,
                  -length(max(abs(p)-vec3(3.5,2.5,.5),0.0))+.1));
  
    return min2(vec2(d,-100.), 
                vec2(length(max(abs(p-vec3(0,0,.2))-vec3(3.4,2.4,.01),0.))-.3, -103.));
}

//----------------------------------------------------------------------

vec2 map( in vec3 pos) {
    vec2 res1 = vec2( pos.y+4.2, -101.0 );
    res1 = min2(support(pos+vec3(2.5,-0.56,0), vec2(.1,15.), 0.05), res1);

    vec2 res = smin(spiralTail(pos.xyz-vec3(0,-.05-.05*Anim,0)), body( pos.xyz-vec3(-.49,1.5,0)),.1 ); 
    
    pos.z = abs(pos.z);
    res = smin(res, head(pos - vec3(-2.8,3.65,0)), .5);
    
    // legs
    res = min2(res, min2(sdCapsule(pos, vec3(.23,-.1*Anim+1.3,.65), vec3(.75,-.1*Anim+.6,.05),.16),
                         sdCapsule(pos, vec3(.23,-.1*Anim+1.3,.65), vec3(-.35,1.35,.3),.16)));
    res = min2(res, vec2(length(pos-vec3(-.35,1.35,.1))- .33, 30.));   
    
    // arms 
    res = smin(res, min2(sdCapsule(pos, vec3(-.8+.06*Anim,2.5,.85),vec3(-1.25+.03*Anim,3.,.2), .16),
                         sdCapsule(pos, vec3(-.8+.06*Anim,2.5,.85), vec3(-1.25,2.1,.3),.16)),.15);
    res = min2(res, vec2(length(pos-vec3(-1.55,1.9,.1))- .3, 30.));
     
    return min2(res, res1);
}

vec2 castRay( in vec3 ro, in vec3 rd, in float maxd) {
    float precis = 0.0005;
    float h = precis*2.;
    float t = 2.0;
    float m = -1.0;
    for( int i=0; i<48; i++) {
        if( abs(h)<t*precis || t>maxd ) break;
        t += h;
        vec2 res = map( ro+rd*t );
        h = res.x;
        m = res.y;
    }

    if( t>maxd ) m = -200.0;
    return vec2( t, m );
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float maxt, in float k) {
    float res = 1.0;
    float t = mint;
    for( int i=0; i<26; i++ ) {
        if( t>maxt ) break;
        
        float h = map( ro + rd*t ).x;
        res = min( res, k*h/t );
        t += h;
        
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos ) {
    const vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

float calcAO( in vec3 pos, in vec3 nor) {
    float totao = 0.0;
    float sca = 1.0;
    for( int aoi=0; aoi<5; aoi++ ) {
        float hr = 0.01 + 0.05*float(aoi);
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        totao += -(dd-hr)*sca;
        sca *= .75;
    }
    return clamp( 1.0 - 4.0*totao, 0.0, 1.0 );
}

vec3 mandelbrot(in vec2 uv, vec3 col) {
    uv.x += 1.5;
    uv.x=-uv.x;

    float a=.05*sqrt(abs(Anim)), ca = cos(a), sa = sin(a);
    mat2 rot = mat2(ca,-sa,sa,ca);
    uv *= rot;
    float kk, k = abs(.15+.01*Anim);
    uv *= mix(.02, 2., k);
    uv.x-=(1.-k)*1.8;
    vec2 z = vec2(0);
    vec3 c = vec3(0);
    for(float i=0.;i<120.;i++) {
        z = vec2(z.x*z.x-z.y*z.y, 2.*z.y*z.x) + uv;
        if(length(z) >= 4.0) {
            kk = i*.07;
            break;
        }
    }
    return clamp(mix(vec3(.1,.1,.2), clamp(col*kk*kk,0.,1.), .6+.4*Anim),0.,1.);
}

vec3 render( in vec3 ro, in vec3 rd) { 
    vec3 col = vec3(0.0);
    vec2 res = castRay(ro,rd,60.0);
    float t = res.x;
    float m = res.y;
    vec3 cscreen = vec3(sin(.1+2.*time), cos(.1+2.*time),.5);
    cscreen *= cscreen;

    if( m>-150.)  {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);

        if( m>0. ) {
            col = vec3(.55) + .25*cscreen/*vec3(.5,.8,.5)*/ + 0.25*sin(1.57*.5*time + vec3(0.05,0.09,0.1)*(m-1.0) );
        } else if (m<-102.5) {
              col = (pos.z<0.) ? mandelbrot(pos.xy,cscreen) : vec3(.02);
        } else if (m<-101.5) {
            col = cscreen;
        } else if(m<-100.5) {
            float f = mod( floor(2.*pos.z) + floor(2.*pos.x), 2.0);
            col = 0.4 + 0.1*f*vec3(1.0);
            float dt = dot(normalize(pos-vec3(-4,-4,0)), vec3(0,0,-1));
             col += (dt>0.) ? .2*dt*cscreen: vec3(0);
            col = clamp(col,0.,1.);
        } else {
            col = vec3(.02);
        }
        
        float ao = calcAO( pos, nor );

        vec3 lig = normalize( vec3(-0.6, 0.7, -0.5) );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);

        float sh = 1.0;
        if( dif>0.02 ) { sh = softshadow( pos, lig, 0.02, 13., 8.0 ); dif *= sh; }

        vec3 brdf = vec3(0.0);
        brdf += 1.80*amb*vec3(0.10,0.11,0.13)*ao;
        brdf += 1.80*bac*vec3(0.15,0.15,0.15)*ao;
        brdf += 0.8*dif*vec3(1.00,0.90,0.70);

        float pp = clamp( dot( reflect(rd,nor), lig ), 0.0, 1.0 );
        float spe = 1.2*sh*pow(pp,16.0);
        float fre = ao*pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );

        col = col*brdf + vec3(1.0)*col*spe + 0.2*fre*(0.5+0.5*col);
        
    }

    col *= 2.5*exp( -0.01*t*t );

    return vec3( clamp(col,0.0,1.0) );
}

void main( void ) {
    
    Anim = clamp(2.6*cos(time)*cos(4.*time),-1.,1.);

    float a=.1+.05*Anim, ca = cos(a), sa = sin(a);
    Rotanim = mat2(ca,-sa,sa,ca);
    
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    //vec2 mo = iMouse.xy/iResolution.xy;
    vec2 mo=vec2(1.0,0.0);
         
    float time = 17. + 14.5 + time;

    float dist = 12.;
    // camera    
    vec3 ro = vec3( -0.5+dist*cos(0.1*time + 6.0*mo.x), 3.5 + 10.0*mo.y, 0.5 + dist*sin(0.1*time + 6.0*mo.x) );
    vec3 ta = vec3( -3.5, .5, 0. );
    
    // camera tx
    vec3 cw = normalize( ta-ro );
    vec3 cp = vec3( 0.0, 1.0, 0.0 );
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    vec3 rd = normalize( p.x*cu + p.y*cv + 2.5*cw );

    
    vec3 col = render( ro, rd );

    col = sqrt( col );

    glFragColor=vec4( col, 1.0 );
}
