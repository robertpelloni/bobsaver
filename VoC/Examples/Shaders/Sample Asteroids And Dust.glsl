#version 420

// original https://www.shadertoy.com/view/cljXWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S. Guillitte 2021
 

mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));    
}

vec3 l = vec3(1.);

//Yonatan clouds/mountains combined field
vec2 field(in vec3 p) {
    
    float s=2.,e,f,o;
    
    for(e=p.y/2.-.8,f=-.5; s<4e2; s*=1.6)
            p.xz*=rot(1.),
            e+=abs(dot(sin(p*s)/s,l)),
            f+=abs(dot(sin(p*s*.5)/s,l));

    o = 1.+ (f>.001?e:-exp(-f*f));
    return vec2(max(o,0.),min(f,max(e,.5)));
}

vec3 raycast( in vec3 ro, vec3 rd )
{
    float t = 1., dt = .035;
    vec3 col= vec3(0.);
    for( int i=0; i<100; i++ )
    {                
        vec2 v = field(ro+t*rd);  
        float c=v.x, f=v.y;
        t+=dt*f;
        dt *= 1.035;
        col = .95*col+ .09*vec3(c*c*c, c*c, c);    
    }
    
    return col;
}

void main(void)
{
    float t = time;
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
    

    // camera

    vec3 ro = vec3(2.);
   
    ro.yz*=rot(-1.5); 
    ro.y +=3.;
    ro.xz*=rot(sin(0.1*t));
    
    vec3 ta = vec3( 0.0 , 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );
    ro.x -=t*.4;

    // raymarch 
    
    vec3 col = raycast(ro,rd);
    
    
    // shade
    
    col =  .5 *(log(1.+col));
    col = clamp(col,0.,1.);
    glFragColor = vec4( col, 1.0 );

}
