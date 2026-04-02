#version 420

// original https://www.shadertoy.com/view/4XdXzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//logic taken from gaz: https://www.shadertoy.com/view/ftKBzt
//and made more verbose and tweaked

#define rot(a) mat2( cos(a + vec4(0,11,33,0) ) )

//Rodrigues-Euler axis angle rotation
#define ROT(p,axis,t) mix(axis*dot(p,axis),p,cos(t))+sin(t)*cross(p,axis)

//formula for creating colors;
#define H(h)  (  cos( h/2. + vec3(31,10,20) )*.6 )

//formula for mapping scale factor 
#define M(c)  log(1.+c*c)

#define R resolution

void main(void) {
  
    vec4 O = vec4(0);
    vec2 U = gl_FragCoord.xy;
    
    vec3 c=vec3(0), rd = normalize( vec3(U-.5*R.xy, R.y))*10.;
    
    float sc,dotp,totdist=0., t=time/3.;
    
    for (float i=0.; i<150.; i++) {
        
        vec4 p = vec4( rd*totdist, 0.);
      
        
        p.xyz += vec3(0,0,-18.);
        p.xyz = ROT(p.xyz, normalize( vec3(sin(t/7.),cos(t/11.),0)  ), (t+7.5)/4.);
        sc = 1.;  //scale factor
        
        
        for (float j=0.; j<6.; j++) {
        
            p = abs(p)*.56  - vec4( .025*cos(p.xy/5.), .01*sin(p.zw/3.));
            
            
            dotp = max(1./dot(p,p),.4);
            sc *= dotp ;
            
            p.zw = length(p.xz)<length(p.zw) ? p.xz : p.zw;  //reflection                   
  
            p = abs( p ) * dotp - 1.;       
               
            
        }
         
        float dist = abs( length(p)-.1)/sc ;  //funky distance estimate
        float stepsize = dist + 1e-4;         //distance plus a little extra
        totdist += stepsize;                  //move the distance along rd
        
       
        //accumulate color, fading with distance and iteration count
        c += mix( vec3(1), H(M(sc)),.6) *.014*  exp(-i*i*stepsize*stepsize/2.);
    }
    
    c *= c;
    c = 1. - exp(-c);
    O = ( vec4(c,0) );
               
    glFragColor = O;
}        
        