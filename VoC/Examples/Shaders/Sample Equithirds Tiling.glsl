#version 420

// original https://www.shadertoy.com/view/WtSczR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This is a no-math, all number crunched, Equithirds tiling:
// https://tilings.math.uni-bielefeld.de/substitution/equithirds/

#define rot(j) mat2(cos(j),-sin(j),sin(j),cos(j))
#define pi acos(-1.)
#define tau (2.*pi)

float sdTriangleIsosceles( in vec2 p, in vec2 q )
{
    p.x = abs(p.x);
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                  vec2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    
    vec3 col = vec3(0);
    
    float iters = 9.;
    
    float d = 10e5;
    
    // mafs
    vec2 s = vec2(0.173,0.1);

    
    uv.y -= s.y*0.35;

    uv += vec2(sin(time),cos(time))*0.1;    
    uv *= 0.06;

    
    float id = 0.;
    vec2 p = uv;
    float sc = 1.;
    
    float id0cnt = 0.;
    float id1cnt = 0.;
    float palcnt = 0.;
    
    for(float i = 0.; i < iters; i++){
        
        if( id == 0. ){
        
            mat2 rb = rot(tau/3.*1.);
            mat2 rc = rot(tau/3.*2.); 
        
            float szsc = 1.*sc;
            
            float da = sdTriangleIsosceles( p   , s*szsc);
            float db = sdTriangleIsosceles( p*rb, s*szsc);
            float dc = sdTriangleIsosceles( p*rc, s*szsc);

            if( da < 0. ){
                palcnt++;
            } else if( db < 0. ){
                p *= rb;
                palcnt += 1.5;
            } else if( dc < 0. ){
                palcnt += 2.5;
                p *= rc;
            } 
            p.y -= 0.5*s.y*szsc;
            
            d = min(d,abs(da));
            d = min(d,abs(db));
            d = min(d,abs(dc));
            id = 1.;
            
            id0cnt ++;
        
        } else if (id == 1.) {
            float ramt = tau/5.*2.0835;
            mat2 ra = rot(-ramt);
            mat2 rb = rot(ramt);
            
            vec2 transa = vec2(-0.075,0.0144);
            vec2 transb = vec2(-transa.x,transa.y);
            
            float szsc = sc*0.579;
            
            vec2 pa = (p*ra + transa*sc );
            vec2 pb = (p*rb + transb*sc );
            
            
            float da = sdTriangleIsosceles( pa, s*szsc);
            float db = sdTriangleIsosceles( pb, s*szsc);
            
            
            if(da < 0.){
                p = p*ra + transa*sc*vec2(1.,-1.);
                sc = szsc;
                id = 1.;
                palcnt += 1.5;
            } else if(db < 0.){
                p = p*rb + transb*sc*vec2(1.,-1.);
                col += 0.03;
                sc = szsc;
                id = 1.;
                palcnt += 1.;
            } else {
                p.y -= s.y*szsc/3.5;
                
                sc *= 0.335;
                id = 0.;
                palcnt += .5;
            }
            
            
            id1cnt++;
            d = min(d,abs(da));
            d = min(d,abs(db));
        }
    }
    
    
    #define pal(a,b,c,d,e) (a + b*sin(c*d + e))
    
    col = mix(col,pal(0.5,0.5,vec3(2.,0.7,0.2),1., id1cnt*7. +  id0cnt*5. + palcnt*7. + 4. + time/2. + uv.x*1. )/1.,smoothstep(dFdx(uv.x),0.,-d));
    
    d = abs(d);
    
    float w = 0.00006;
    
    col = mix(col,vec3(0.01),smoothstep(dFdx(uv.x) + w,w,d));
    
    
    col = pow(col,vec3(0.454545));
    glFragColor = vec4(col,1.0);
}
