#version 420

// original https://www.shadertoy.com/view/3lSyRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This is Socolar-C5 but with mirror simmetry added in the first rule

// Mostly mathematically correct with some number crunching (about 20%) 
// https://tilings.math.uni-bielefeld.de/substitution/socolar-c5/

// Substitution tilings are super fun stuff
// Although they may seem a bit intimidating, because they,
// I think starting one from scratch is a good way to get started,
// because code can get... uh... convoluted, like here.

#define rot(j) mat2(cos(j),-sin(j),sin(j),cos(j))
#define pi acos(-1.)
#define tau (2.*pi)

float sdEquilateralTriangle(  vec2 p, float r ){   
    r = r*1./3.;
    p.y -= r;
    p.y += r*1.5;
    float d = dot(vec2(abs(p.x),p.y) - -normalize(vec2(0.,1)*rot(tau/3.))*(r), -normalize(vec2(0.,1)*rot(tau/3.)));
    d = max(d,p.y - r*2.);
    d = max(d,-p.y - r);
    return d;
}

float sdRhombus( vec2 p, float height, float angleHoriz, float angleVert ){

    float hypothenuse = sin(pi/2.)*height*0.5/sin(angleHoriz/2.);
    float base = sin( angleVert/2.)*hypothenuse/sin(pi/2.);
    
    float triarea = height*0.5*base*0.5;
    float triheight = triarea*2./hypothenuse;
    
    float triAngle = asin(triheight*sin(pi/2.)/base);
    vec2 hdir = vec2(0.,1.)*rot(-triAngle);
    p = abs(p);    
    p -= normalize(hdir)*triheight/1.;
    
    return dot(p,vec2(0.,1.)*rot( -triAngle));
}
        

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    
    vec3 col = vec3(0);
    
    
    float id = 0.;
    float iters = 5.;
    
    float d = 10e5;
    
    float s = 1.;

    uv += vec2(sin(time/2.6  + cos(time/4.)),cos(time/2. + sin(time/4.)))*0.2;    
    uv *= 0.7;
    
    
    vec2 p = uv;
    float sc = 1.;
    
    float palvar = 1.;
    
    float lside = 2.;
    float lsplithoriz = 2.35 ; // 2.35 is totally crunched
    
    
    float avert = 2.*( asin( lsplithoriz*0.5*sin(pi/2.)/lside) );
    float ahoriz = (tau - 2.*avert)/2.;
    
    float ahorizb = avert/2.;
    float avertb = (tau - ahorizb*2.)/2.;
    
    float lsplitvert = 2.*sin(ahoriz/2.)*lside/sin(pi/2.);
    
    float ratiosidevert = lside/(lside + lsplitvert);
    
    float ratiohorizvert = lsplithoriz/(lsplithoriz + lsplitvert);
    
    float lsidesmall = lside * ratiosidevert;
    
    float lsplitvertsmall = lside - lsidesmall;
    
    float lsplithorizsmall = lsplitvertsmall*ratiohorizvert;
    float lsplitvertb = lsplitvertsmall*1./2.62; // last minute crunch from 2.6 to 2.62?
    
    
    for(float i = 0.; i < iters; i++){
        float Llside = lside * sc;
        
        float Llsplithoriz = lsplithoriz * sc;
    
        float Llsplitvert = lsplitvert * sc;
    
        float Lratiosidevert = ratiosidevert * sc;
    
        float Lratiohorizvert = ratiohorizvert * sc;
    
        float Llsidesmall = lsidesmall * sc;
    
        float Llsplitvertsmall = lsplitvertsmall * sc;
    
        float Llsplithorizsmall = lsplithorizsmall * sc;
    
        float Llsplitvertb = lsplitvertb * sc;
        
        if(id == 0.){
            float drh = sdRhombus(p, Llsplitvert, ahoriz, avert );
        
            vec2 pb = p + vec2(0,Llsplitvert*0.5 - Llsplitvertsmall/2.);

            float drhb = sdRhombus(pb, Llsplitvertsmall, ahoriz, avert );

            p.x = abs(p.x);
            vec2 pc = p + vec2(0. - Llsplithoriz*0.5, - Llsplitvertsmall*0.5);
            pc.y += Llsplitvertsmall*0.495; // some crunch here
            mat2 pcr = rot(avert*0.5*6.); 
            pc *= pcr;
            pc.y -= Llsplitvertsmall*0.503;
            float drhc = sdRhombus( pc, Llsplitvertsmall, ahoriz, avert );

            vec2 pd = p + vec2(0. - Llsplithoriz*0.5, - Llsplitvertsmall*0.5);
            pd.y += Llsplitvertsmall*0.5;
            mat2 pdr = rot(-avert/1.);
            pd *= pdr;
            pd.y -= Llsplitvertsmall*0.5;

            float drhd = sdRhombus( pd, Llsplitvertsmall, ahoriz, avert );

            vec2 pe = p + vec2(0. - Llsplithoriz*0.5, - Llsplitvertsmall*0.5);
            pe.y += Llsplitvertsmall*0.5;
            mat2 per = rot(-avert/1.);
            pe *= per;
            pe.y -= Llsplitvertsmall*1.;

            pe.x -= Llsplithorizsmall*0.862;

            float drhe = sdRhombus( pe, Llsplitvertsmall, ahoriz, avert );

            
            vec2 pba = p;
            pba.x -= Llsplitvertb/2.125;
            pba.y += Llsplitvertb/1.55;

            pba *= rot(ahoriz/1.5);
                        
            float drhba = sdRhombus( pba, Llsplitvertb, ahorizb, avertb );

            d = min(d, abs(drh));
            d = min(d, abs(drhb));
            d = min(d, abs(drhc));
            d = min(d, abs(drhd));
            d = min(d, abs(drhe));
            d = min(d, abs(drhba));
            

            if (drhb < 0.) {
                p = pb;
            } else if (drhc < 0.) {
                p = pc;
            } else if (drhd < 0.) {
                p = pd;
            } else if (drhe < 0.) {
                p = pe;
            } else if (drhba < 0.) {
                p = pba;
            } else {
                break;
            }

            if ( drhb < 0. || drhc < 0. || drhd < 0. || drhe < 0. ){
                id = 0.;
                palvar += 0.4;
            } else {
                palvar += 2.1;
                id = 1.;
            }
            sc *= lsplitvertsmall/lsplitvert;    
        } else if (id == 1.) {
            
            p *= rot(1.*pi);
            
            p.y = abs(p.y);
            //p*=0.5;
            vec2 pa = p*1.;
            float dra = sdRhombus( pa, Llsplitvertb, ahorizb, avertb );
            
            vec2 pb = p;
            float drb = sdRhombus( pb, Llsplitvertsmall, ahoriz, avert );
            
            
            vec2 pc = p;
            pc.y += 0.5*Llsplitvertsmall;
            pc *= rot(avert);
            pc.y -= 0.5*Llsplitvertsmall;
            float drc = sdRhombus( pc, Llsplitvertsmall, ahoriz, avert );

            vec2 pd = pc;
            pd.y -= 0.62*Llsplitvertsmall;
            
            pd.y -= 0.5*Llsplitvertsmall;
            pd *= rot(avert/2.);
            
            pd.y += 0.5*Llsplitvertsmall;
            
            float drd = sdRhombus( pd, Llsplitvertsmall, ahoriz, avert );

            vec2 pe = pc;
            
            pe.y -= 0.5*Llsplitvertsmall;
            
            pe *= rot(-ahorizb);
            //pe.x += Llsplithorizb*lsplithorizsmall/lsplithoriz/0.75;
            pe.x += 0.58*Llsplitvertsmall;
            
            float dre = sdRhombus( pe, Llsplitvertb, ahorizb, avertb );

            vec2 pf = p;
            
            pf.y -= 0.505*Llsplitvertsmall;
            pf *= rot(-ahorizb);
            
            pf.x += 0.58*Llsplitvertsmall;
            
            //pe.x += Llsplithorizb*lsplithorizsmall/lsplithoriz/0.75;
            //pe.x += 0.58*Llsplitvertsmall*lsplitvertsmall/lsplitvert;
            
            float drf = sdRhombus( pf, Llsplitvertb, ahorizb, avertb );

            
            
            //d = min(d, abs(dra));
            
            d = min(d, abs(drb));
            d = min(d, abs(drc));
            d = min(d, abs(drd));
            d = min(d, abs(dre));
            d = min(d, abs(drf));
            
            
            if (drb < 0.) {
                p = pb;
            } else if (drc < 0.) {
                p = pc;
            } else if (drd < 0.) {
                p = pd;
            } else if (dre < 0.) {
                p = pe;
            } else if (drf < 0.) {
                p = pf;
            } else  {
                break;
            }

            if ( drb < 0. || drc < 0. || drd < 0.){
                id = 0.;
                palvar += 1.1;
            } else if ( dre < 0. || drf < 0.) {
                id = 1.;
                palvar += 2.1;
            } else {
                break;
            }
            sc *= lsplitvertsmall/lsplitvert;
            
            
        }
            
    }
    
    
    #define pal(a,b,c,d,e) (a + b*sin(c*d + e))
    
    col = mix(col,pal(0.5,0.56,vec3(3.,0.7,0.2),3.4, palvar + time + uv.x/2. + uv.y/2.)/1.,smoothstep(dFdx(uv.x),0.,-d));
    
    //col = mix(col,pal(0.5,0.56,vec3(2.,0.7,0.2),1., palvar + time + uv.x*2. + uv.y*2.)/1.,smoothstep(dFdx(uv.x),0.,-d));
    
    
    d = abs(d);
    
    float w = 0.0002;
    col = mix(col,vec3(0.04),smoothstep(dFdx(uv.x) + w, w,d));
    
    
    col = pow(col,vec3(0.454545));
    glFragColor = vec4(col,1.0);
}
