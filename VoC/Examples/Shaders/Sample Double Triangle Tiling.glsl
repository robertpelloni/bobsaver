#version 420

// original https://www.shadertoy.com/view/wlSyRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Mathematically correct with no number-crunching! 
// https://tilings.math.uni-bielefeld.de/substitution/double-triangle/

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

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    
    vec3 col = vec3(0);
    
    float iters = 6.;
    
    float d = 10e5;
    
    // mafs
    float s = 1.;

    
    

    
    uv += vec2(sin(time/2.6),cos(time/2.))*0.4;    
    uv *= .03;
    uv.y -= 0.1;
    uv.x -= 0.2;

    
    float id = 0.;
    vec2 p = uv;
    float sc = 1.;
    
    float palvar = 1.;
    
    for(float i = 0.; i < iters; i++){
        
        
        float median = s;
        float outer = median*2./sqrt(3.);

        vec2 pbtrans = - vec2(0.,sc*median/4.);
        vec2 pctrans = + vec2(0.,sc*median/4.);
        vec2 pdtrans = + vec2(0. - sc*outer*.125,sc*median/8.);
        vec2 petrans = + vec2(0. - sc*outer*.25 , sc*median/(2.+2./3.));
        vec2 pftrans = + vec2(0. - sc*outer*.25, sc*median/(8.));
        vec2 pgtrans = + vec2(0. - sc*outer*0.375, sc*median/(2.+2./3.));

        float tria = sdEquilateralTriangle( p, s*sc*1.);
        float trib = sdEquilateralTriangle( p + pbtrans, s*sc/2.);
        float tric = sdEquilateralTriangle( p + pctrans, s*sc/2.);

        p.x = abs(p.x);

        float trid = sdEquilateralTriangle((p + pdtrans )* rot(1.*pi) , s*sc/4.);
        float trie = sdEquilateralTriangle((p + petrans )* rot(1.*pi) , s*sc/4.);

        float trif = sdEquilateralTriangle((p + pftrans ), s*sc/4.);
        float trig = sdEquilateralTriangle((p + pgtrans ) , s*sc/4.);

        d = min(d,abs(tria));

        d = min(d,abs(trib));
        d = min(d,abs(tric));
        d = min(d,abs(trid));
        d = min(d,abs(trie));
        d = min(d,abs(trif));
        d = min(d,abs(trig));

        if(tria < 0.){
            if( trib < 0.){
                p += pbtrans;
                palvar += 0.4;
            } else if(tric < 0.){
                p += pctrans;
                palvar += 1.4;
            } else if(trid < 0.){
                p += pdtrans;
                palvar += .4;
            } else if(trie < 0.){
                p += petrans;
                palvar += 1.4;
            } else if(trif < 0.){
                p += pftrans;
                palvar += .4;
            } else if(trig < 0.){
                p += pgtrans;
                palvar += 2.4;
            }
            if(trid < 0. || trie < 0.){
                p *= rot(pi);
            }
            if(trib < 0. || tric < 0. ){
                sc *= 0.5;
            } else {
                sc *= 0.25;
            }

        } else {
            break;
        }
            
            
        
    }
    
    
    #define pal(a,b,c,d,e) (a + b*sin(c*d + e))
    
    col = mix(col,pal(0.5,0.56,vec3(3.,0.7,0.2),3.4, palvar + time + uv.x*2. + uv.y*2.)/1.,smoothstep(dFdx(uv.x),0.,-d));
    
    //col = mix(col,pal(0.5,0.56,vec3(2.,0.7,0.2),1., palvar + time + uv.x*2. + uv.y*2.)/1.,smoothstep(dFdx(uv.x),0.,-d));
    
    
    d = abs(d);
    
    float w = 1.1;
    col = mix(col,vec3(0.01),smoothstep(dFdx(uv.x)*w,dFdx(uv.x)*(w-1.)*1.,d));
    
    
    col = pow(col,vec3(0.454545));
    glFragColor = vec4(col,1.0);
}
