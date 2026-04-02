#version 420

// original https://www.shadertoy.com/view/4sB3DW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//------------------ ------------------------------------------
// Triplex operations

// http://www.bugman123.com/Hypercomplex/index.html#Mandelbulb2

vec3 tsqr(vec3 p) 
{
    if(p.x==0. && p.y==0.)return vec3(-p.z*p.z,0.,0.);
    float a=1.-p.z*p.z/dot(p.xy,p.xy);
    return vec3((p.x*p.x-p.y*p.y)*a ,2.*p.x*p.y*a,2.*p.z*length(p.xy));
}

vec3 tinv(vec3 p) 
{
    return vec3(p.x,-p.yz)/dot(p,p);
}

vec3 tconj(vec3 p) 
{
    return vec3(p.x,-p.yz);
}

vec3 tmul(vec3 a, vec3 b) 
{
    float r1 = length(a.xy);
    float r2 =length(b.xy);
    if(r1==0. || r2==0.)return vec3(-a.z*b.z,0.,0.);
    float k=1.-a.z*b.z/(r1*r2);
    return vec3((a.x*b.x-a.y*b.y)*k ,(a.x*b.y+b.x*a.y)*k,a.z*r2+b.z*r1);
}

vec3 tdiv(vec3 a, vec3 b) 
{
    float r1 = length(a.xy);
    float r2 =length(b.xy);
    if(r1==0. || r2==0.)return vec3(a.z*b.z,0.,0.)/dot(b,b);
    float k=1.+a.z*b.z/(r1*r2);
    return vec3((a.x*b.x+a.y*b.y)*k ,(-a.x*b.y+b.x*a.y)*k,a.z*r2-b.z*r1)/dot(b,b);
}

vec3 tpow(vec3 a, float power) 
{
    float r = length(a)+1e-10;
    float phi = atan(a.y,a.x)  ;// azimuth
    float theta = asin(a.z/r);//asin(-a.z/r);
    r=pow(r,power);
    phi = power*phi;
    theta = power*theta;
    return vec3(
        r*cos(theta)*cos(phi),
        r*cos(theta)*sin(phi),
        r*sin(theta)
    );

}

vec3 tcube(vec3 p){
        float x = p.x; float x2 = x*x; 
        float y = p.y; float y2 = y*y; 
        float z = p.z; float z2 = z*z; 

        float r = x2 + y2;
        float a = 1.-3.*z2/r;
        
return vec3(
        x*(x2-3.*y2)*a,
        y*(3.*x2-y2)*a,
        (3.*r-z2)*z
);
}

vec3 tpow8(vec3 p){
        float x = p.x; float x2 = x*x; float x4 = x2*x2;
        float y = p.y; float y2 = y*y; float y4 = y2*y2;
        float z = p.z; float z2 = z*z; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = 1./sqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;
        return vec3(
        64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2,
        -16.0*y2*k3*k4*k4 + k1*k1,
        -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2
);

}

vec3 talt(vec3 z){return vec3(z.xy,-z.z);}
//----------------------------------------------------------------------

mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));    
}

float zoom;
vec3 dz = vec3(0.);
vec3 c = vec3(-0.9,1.1,0.95);

vec3 f(vec3 z,vec3 c){

//return sin(tinv(z))+c;
//return tinv(sin(z))+c;
//return tinv(sin(z))+0.22;
//return tinv(z-z*z*z/6.)+c;
//return tinv(z-tpow(z,3.)/6.+tpow(z,5.)/120.)+c;
//return tinv(z-tcube(z)/6.)+c;
//return tinv(tsqr(z)+c)+ z-c;//with g=0.1
//return tinv(tsqr(z))+(c);
//return tsqr(tinv(z+c))+ z-c;
//return tinv(z)+(z)-0.5*talt(c);
//return tinv(tmul(z,c))+c;
//return tdiv(talt(z),tsqr(talt(z))+c);
//return tdiv(z,tsqr(z)+c);       
return tsqr(z)+c;

}

vec3 map( vec3 p, vec3 rd )
{
    float eps=1e-4;
    float bailout = 1e5;
    float invbail=1./bailout;
    c=p;
    vec3 z = p;
    vec3 z1 = p+eps*rd;
    vec3 c1 = z1;
    vec3 pz = vec3( 0.0 );
    float dz2 = 0.0;
    vec2  t = vec2( 1e10 );   
            
    float d;
    
    for( int i=0; i<10; i++ ) 
    {
            pz=z;
        
            // formula
            
            z=f(z,c);
            z1=f(z1,c1); 
    
            // stop under divergence or convergence    
            dz= (z-pz);
            dz2 = dot(dz, dz);
            d = dot(z,z);    
            if( dz2<invbail||dz2>bailout) break;                 

            // orbit trapping ( |dz|² and z_x*z_y  )
            t = min( t, vec2( d, abs(z.x*z.y) ));
    }

        z1-=z;  //delta z
        z1/=eps; //derivative along rd
        d=0.25*(sqrt(d/dot(z1,z1))*log(d));

    return vec3( d, t );
}

vec3 intersect( in vec3 ro, in vec3 rd )
{
    float maxd = 10.0;
    float eps = 0.0000001;
    float g = .3;
    float t = 0.1;
    vec3 z;
    vec3 pz;
    float dt = 0.5;

    float d = 0.0;
    float m = 1.0;
    for( int i=0; i<150; i++ )
    {
        if( dt<eps||t>maxd ) break;

        t += g*dt;

    vec3 res = map(z=ro+rd*t, rd );
        dt=abs(res.x);      
    d = res.y;
    m = res.z;
    }

    if( t>maxd ||dt>0.1) return sin(vec3(3.0,1.5,2.0)+1.2*rd+0.);
    vec3  ref = reflect( rd, normalize(dz) );
    return sin(vec3(3.0,1.5,2.0)+1.2*ref+m)*(1.-d);
    
}

vec3 calcPixel( in vec2 pi, in float time2 )
{
    vec2 q = pi / resolution.xy;
    vec2 p = -1.0 + 2.0 * q; 
    p.x *= resolution.x/resolution.y;
    vec2 m = vec2(0.5);
    m = mouse.xy/resolution.xy*3.14;

    // camera

    

    vec3 ro = zoom*tconj(vec3(-3.));
    ro.yz*=rot(m.y);
    ro.xz*=rot(m.x+ 0.1*time2);
    vec3 ta = vec3( 0.0 , 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );

    // raymarch
    return intersect(ro,rd);
    

}

void main(void)
{
    zoom=.7+.5*sin(.2*time);
    
    glFragColor = vec4( calcPixel( gl_FragCoord.xy, time ), 1.0 );

}
