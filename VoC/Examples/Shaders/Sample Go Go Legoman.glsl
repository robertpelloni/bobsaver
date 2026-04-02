#version 420

// original https://www.shadertoy.com/view/MsB3zK

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

// Created by sebastien durand - 01/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

    
#define TAO 6.28318530718
#define NB_ITER 80
#define MAX_DIST 400.
#define PRECISION .002
//#define ANTIALIASING
/*
precision mediump float;
precision mediump vec2;
precision mediump vec3;
*/

const vec2 V01 = vec2(0,1);
const vec2 Ve = vec2(.001,0);
const vec2 leg1 = vec2(0,-.1);
const vec2 leg2 = vec2(0,-.8);
const vec2 hand2 = vec2(-.1,.25);    

const vec3 v0 = vec3(0);
const vec3 head0 = vec3(0,-1.4,0);
const vec3 body0 = vec3(0,-.15,0);
const vec3 middle1 = vec3(0,.44,0);
const vec3 middle2 = vec3(.65,.1,.325);
const vec3 middle3 = vec3(.76,0,0);
const vec3 arm0 = vec3(.7,-.55,0);
const vec3 hand0 = vec3(.4,1.,.5);
const vec3 bbody = vec3(.47,.14,.45);
const vec3 bbody1 = vec3(.75,.6,1.);
const vec3 arm1 = vec3(-.25,-.5,0);
const vec3 arm2 = vec3(-.4,-1.,-.5);
const vec3 hand1 = vec3(.02,.15,0);

const float legh = 1.;
const float lege=.34; 
const float legx=.31; 
const float handa = -.7;
const float face_a = 1.1;
const float face_r = 27.;

 
const float face_x = 27.*0.453596121; //face_r*cos(a); // precalcul
const float face_y = -27.*0.89120736; //face_r*sin(a); // precalcul

// Global variables
float time2;
vec3 sunLight, deltaMan, armn;
vec2 boby2;
mat2 handmat;
vec2 fragCoord;

float sdCapsule(in vec3 p, in vec3 a, in vec3 b, in float r0, in float r1 ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1.);
    return length( pa - ba*h ) - mix(r0,r1,h);
}

float smin(in float a, in float b, in float k ) {
    float h = clamp( .5+.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.-h);
}

// h = .5, //  half of height
// r1 = 1., //main rayon
// r2 = .2, // top border
float roundCylinder(in vec3 p, in float h, in float r1, in float r2) {
    float
        a = abs(p.y)-(h-r2),
        b = length(p.xz)-r1;
    return min(min(max(a, b), max(a-r2, b+r2)), length(vec2(b+r2,a))-r2);
}

float head(in vec3 p) {
    float d = max(abs(p.y+.4)-.3, length(p.xz)-.326);
    d = min(d, roundCylinder(p, .425,.51,.1));
    p.y -=.425;
    return min(d, roundCylinder(p, .173, .245,.025));
}

float body(in vec3 p) {
    vec3 vd = abs(p) - bbody1;
    float d = min(max(vd.x,max(vd.y,vd.z)),0.0) + length(max(vd,0.0));
    p.x = abs(p.x);
    d = max(dot(p.xy, boby2)-.7,d);
    p.y -= .4;    
    d = min(d, length(max(abs(p)-bbody,0.0))-.16);
    return max(abs(p.z)-.392, d);
}

float leg(in vec3 p) {
    float d = length(p.zy)-lege;
    d = min(d, length(max(abs(p+vec3(0.,legh*.5,-.08))-vec3(legx,legh*.5,lege-.08),0.)));
    d = min(d, length(max(abs(p+vec3(0.,legh,.02))-vec3(legx,.15,lege+.02),0.)));
    d = max(abs(p.x)-legx, d)-.02;
    vec3 dd = abs(p+vec3(0.,legh,-.08))-vec3(legx-.1,legh+.2,lege-.18);
    float d2 = min(max(dd.x,max(dd.y,dd.z)),0.) + length(max(dd,0.));
    dd = abs(p+vec3(0.,legh+.1,.02))-vec3(legx-.1,.15,lege-.98);
    d2 = min(d2, min(max(dd.x,max(dd.y,dd.z)),0.0) + length(max(dd,0.)));
    d2 = min(d2, max(-p.z-.05, length(p.xy-leg1)-.24));
    d2 = min(d2, max(-p.z-.05, length(p.xy-leg2)-.24));
    return max(-d2,d);
}

float arm(in vec3 p) {
    float d = smin(sdCapsule(p, v0, arm1, .22, .23), 
                   sdCapsule(p, arm1, arm2, .23, .24),.02); 
    return max(dot(p, armn) - .9, d);
}

float hand(in vec3 p) {
    p.yz *= handmat;
    float d1 = length(p-hand1)-.15;
    p.zy+=.08;
    float d = length(p.xy);
    d = max(-d+.18, smin(d1, d-.26,.02));
    d = max(-length(p.xy+hand2)+.2,d);
    return max(abs(p.z)-.2, d);
}

vec2 minObj(in vec2 o1, in vec2 o2) {
    return (o1.x<o2.x) ? o1 : o2;
}

ivec2 getId(in vec3 p) {
    float k = 5.;
    return (ivec2((k*100.+p.x)/k, (k*100.+p.z)/k)-100);
}

vec2 legoman(in vec3 p, in ivec2 id) {

    float a;
    vec3 p0 = p;

    p += deltaMan;
    vec2 dHead = vec2(head(p+head0),1.);
    vec2 dBody = vec2(body(p+body0),2.);
   
    float middle = length(max(abs(p+middle1)- middle2,0.0))-.05;
    middle = min(middle,roundCylinder(p.yxz+middle3,.06,.39,.02));
    vec2 dMiddle = vec2(middle,3.);   
    p.x = -abs(p.x);
           
    vec3 p1 = p;
    p1.y +=.77;
   // if (id.x==0 && id.y==0) {
        a = -.001 + .4*cos(((p0.x<0.) ? -3.14 : 0.) + 6.*time);
        p1.yz *= mat2(cos(a), -sin(a), sin(a), cos(a));
    //}

    vec2 dLeg = vec2(leg(p1+vec3(.38,.77-.77,0)),4.);

    p += arm0;
    //if (id.x==0 && id.y==0) {
        a = -.5 + cos(((p0.x<0.) ? 0.: -3.14) + 6.*time);
        p.yz *= mat2(cos(a), -sin(a), sin(a), cos(a));
    //}

    vec2 dArm = vec2(arm(p),5.);
    vec2 dHand = vec2(hand(p+hand0),6.);

    return minObj(minObj(minObj(minObj(minObj(dHead, dBody),dHand),dArm),dMiddle),dLeg);
   
    // TODO utiliser ca pour ne pas tout calculer
    //float d = DEBox(p0, vec3(1.5,2.,.65));
    //return vec2(max(d,v.x),v.y);
}

vec2 DE(in vec3 p) {
    float k = 5.;
    ivec2 id = getId(p);
    p.xz = mod(p.xz, k)-0.5*k;
    return minObj(legoman(p, id), vec2(p.y+1.93,10.));
}

vec3 N(vec3 p) {
    return normalize(vec3(
        DE(p+Ve.xyy).x - DE(p-Ve.xyy).x,
        DE(p+Ve.yxy).x - DE(p-Ve.yxy).x,
        DE(p+Ve.yyx).x - DE(p-Ve.yyx).x
    ));
}

float softshadow(in vec3 ro, in vec3 rd, in float mint, in float maxt, in float k) {
    float res = 1.0, h, t = mint;
    for( int i=0; i<17; i++ ) {
        if (t < maxt) {
            h = DE( ro + rd*t ).x;
            res = min( res, k*h/t );
            t += 0.2;
        }
    }
    return clamp(res, 0., 1.);
}

float calcAO(in vec3 pos, in vec3 nor) {
    float dd, hr=.01, totao=.0, sca=1.;
    for(int aoi=0; aoi<5; aoi++ ) {
        dd = DE(nor * hr + pos).x;
        totao += -(dd-hr)*sca;
        sca *= .75;
        hr += .05;
    }
    return clamp(1.-4.*totao, 0., 1.);
}

vec3 mandelbrot(in vec2 uv) {
    float k = .5+.5*cos(time);
    uv *= mix(.02, 2., k);
    uv.x-=(1.-k)*1.8;
    vec2 z = vec2(0);
    vec3 c = vec3(0);
    for(float i=0.;i<14.;i++) {
        if(length(z) >= 4.) continue;
        z = vec2(z.x*z.x-z.y*z.y, 2.*z.y*z.x) + uv;
        if(length(z) >= 2.0) {
            c.r = i*.05;
            c.b = sin(i*.2);
        }
    }
    return sqrt(c);
}

vec3 getTexture(in vec3 p, in float m) {
    ivec2 id = getId(p);

    vec3 p0 = p;
    float k = 5.;
    p.xz = mod(p.xz, k)-0.5*k;
    
    p += deltaMan;
    vec3 c;   
  
    if (m==1.) {
        c = vec3(1.,1.,0);
        if (id.x==0 && id.y==0 && mod(time, TAO*3.) > 2.*TAO) {
            float a = .8*cos(time+1.57);
            p.xz*= mat2(cos(a), -sin(a), sin(a), cos(a));
        }
        if (p.z<0.) {
            // Draw face
            vec2 p2 = p.xy;
            p2.y -= 1.46;
            p2 *= 100.;
            float px = abs(p2.x);
            float e = 4.-.08*px;
            float v = 
                    (px<face_x && p2.y<-e) ? abs(length(p2)-face_r)-e : 
                    (p2.y<-e) ? length(vec2(px,p2.y)-vec2(face_x,face_y))-e :
                    length(vec2(px,p2.y)-vec2(face_x,-face_y*.1))-1.8*e; 
            v = clamp(v, 0., 1.);
            c = mix(vec3(0), c, v);
        }
    }
    else if (m==2.) {
        c = (id.x==0 && id.y==0) ? mandelbrot(p.xy - vec2(.14,.15)) : vec3(1,0,0);
       
    } else if (m==10.) {
        float d = .3*sin(2.2+time);
         c = vec3(.5+.5*smin(mod(floor(p0.x),2.),mod(floor(p0.z+d-time*.18),2.),1.));
        
    } else {
        c = m == 6. ? vec3(1.,1.,0)  :
            m == 3. ? vec3(.2,.2,.4) :
            m == 4. ? vec3(.1,.1,.2) :
                      vec3(1.,1.,1.);
        
    }
    if (!(id.x==0 && id.y==0)) {
        // black & white
        float a = (c.r+c.g+c.b)*.33;
        c = vec3(a,a,a);
    }
  
    //return vec3(1);
    return c;
}

vec3 Render(in vec3 p, in vec3 rd, in float t, in float m) {
    vec3  col = getTexture(p, m),
          nor = N(p);
    float sh = 1.,
          ao = calcAO(p, nor ),
          amb = clamp(.5+.5*nor.y, .0, 1.),
          dif = clamp(dot( nor, sunLight ), 0., 1.),
          bac = clamp(dot( nor, normalize(vec3(-sunLight.x,0.,-sunLight.z))), 0., 1.)*clamp( 1.0-p.y,0.0,1.0);

    if( dif>.02 ) { sh = softshadow( p, sunLight, .02, 10., 7.); dif *= (.1+.8*sh); }
    
    vec3 brdf =
        ao*.2*(amb*vec3(.10,.11,.13) + bac*.15) +
        1.2*dif*vec3(1.,.9,.7);
    
    float
        pp = clamp(dot(reflect(rd,nor), sunLight),0.,1.),
        spe = sh*pow(pp,16.),
        fre = ao*pow( clamp(1.+dot(nor,rd),0.,1.), 2.);
    
    col = col*(brdf + spe) + .2*fre*(.5*col+.5)*exp(-.01*t*t);
    return sqrt(col);
}

mat3 lookat(in vec3 ro, in vec3 up){
    vec3 fw=normalize(ro),
         rt=normalize(cross(fw,up));
    return mat3(rt, cross(rt,fw),fw);
}

vec3 RD(in vec3 ro, in vec3 cp) {
    return lookat(cp-ro, V01.xyx)*normalize(vec3((2.*fragCoord-resolution.xy)/resolution.y, 12.0));
} 

void main() {
    //glFragColor = vec4(1.0);
    
// - Precalcul global variables ------------------------------
    time2 = 3.14+12.*time;
    sunLight = normalize(vec3(-10.25,30.33,-7.7));
    deltaMan = vec3(0,.05*sin(1.72+time2),0);
    armn = normalize(arm2 - arm1);
    boby2 = normalize(vec2(1,.15));
    handmat = mat2(cos(handa), -sin(handa), sin(handa), cos(handa));
//------------------------------------------------------------
    
    vec2 
        obj, 
        mouse = (mouse.xy/resolution.xy)*6.28,
        q = gl_FragCoord.xy/resolution.xy;

    vec3 
        ro = 45.*vec3(-cos(mouse.x), max(.8,mouse.x-2.+sin(mouse.x)*cos(mouse.y)), -.5-sin(mouse.y)),
        rd, cp = V01.xxx;
    
    vec3 ctot = vec3(0);
    
#ifdef ANTIALIASING 
    for (int i=0; i<4; i++) { // Anti aliasing
        fragCoord = gl_FragCoord.xy + .5*vec2(i/2, i%2);
#else
        fragCoord = gl_FragCoord.xy;
#endif
    // Camera origin (o) and direction (d)
        rd = RD(ro, cp);

        // Ray marching
        float m=0.;
        float t=0.,d=1.;
        
        for(int i=0;i<NB_ITER;i++){
            if(abs(d)<PRECISION || t>MAX_DIST)continue;
            obj = DE(ro+rd*t);
            t+=d=obj.x *.85;
            if (abs(d)<PRECISION) {
                m=obj.y;
            }
        }
 
        // Render colors
        if(t<MAX_DIST){// if we hit a surface color it
            ctot += Render(ro + rd*t, rd,t, m);
        }
#ifdef ANTIALIASING         
    }
    ctot *=.25;    
#endif 
    
    ctot *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .11); // vigneting
    glFragColor = vec4(ctot,1.0);

}
