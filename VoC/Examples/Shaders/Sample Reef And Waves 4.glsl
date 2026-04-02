#version 420

// original https://www.shadertoy.com/view/dljXWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S. Guillitte 2021
 

mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));    
}

//reef/waves combined field
vec3 field(in vec3 p) {
    
    float s=2.,e,f,g,h,o,d;
    vec3 q=p,r=p;
    vec3 n = vec3(0);
    mat2 m = rot(1.);
    vec2 l = vec2(2.);
    for(e=f=p.y;s<4e2;s*=1.7)
            p.xz*=m,
            n.yz*=m,
            q=p*s+n*1.5,
            r=p*s+n,
            r.x+=time*2.,
            e+=abs(dot(sin(r.xz*.1)/s,.8*l)),
            f+=.22+.5*(dot(sin(q.xz*.5)/s,l)),
            n-=cos(q);
    g=exp(-e);h=exp(-f);
    o=1.-(f>.001 ? (e<.001 ? g:0.):h);
    d=min(min(e,2.*e*f),.8*f);
    
    return vec3(d,g*o,h*o);
}

vec3 raycast( in vec3 ro, vec3 rd )
{
    float t = 3., dt = .3,d,e,f;
    vec3 col= vec3(0.);
    for( int i=0; i<100; i++ )
    {        
        vec3 v = field(ro+t*rd); 
        d=v.x; e=v.y; f=v.z; 
        t+=dt*d;
        dt *= 1.01;       
        col = .97*col + .15*(f*vec3(5,5,4)+e*vec3(3,5,6));        
    }    
    return col*exp(-t*.15);
}

void main(void)
{
    float t = time;
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x/resolution.y;
    
    // camera

    vec3 ro = vec3(2.);   
    ro.yz*=rot(-1.6);   
    ro.y +=3.;
    ro.xz*=rot(0.1*t);
    
    vec3 ta = vec3( 0.0 , 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );
    ro.x -= t*.4;
    
    // raymarch 
    
    vec3 col = raycast(ro,rd);
        
    // shade
    
    col =  .5 *(log(1.+col));
    col = clamp(col,0.,1.);
    glFragColor = vec4( col, 1.0 );
}
