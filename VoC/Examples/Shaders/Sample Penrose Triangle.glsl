#version 420

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 iMouse= mouse;
float iTime= time;

#define PI                3.1415926535
#define ABSORBANCE        1.0
//#define LIGHT_DIR        normalize(vec3(cos(-time*.3+PI*.5), 1.0, sin(-time*.3+PI*.5)))
#define LIGHT_DIR        normalize(vec3(1., 2., 1.))
//#define CAM_POS         vec3(4.*cos(-time*.3), 4.0, 4.*sin(-time*.3))

#define CAM_PARAM        smoothstep( 0., 1., max(mod(iTime*.2, 1.)-.8, 0.)*5.)
#define CAM_POS         vec3(2./sqrt(2.)*1.5*cos(CAM_PARAM*2.*PI+PI*.25), 1.5, 2./sqrt(2.)*1.5*sin(CAM_PARAM*2.*PI+PI*.25))

#define AA        4.

//from http://www.iquilezles.org/www/articles/boxfunctions/boxfunctions.htm
vec2 boxIntersection( vec3 ro, vec3 rd, 
                      vec3 boxSize, out vec3 outNormal ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
    
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    
    if( tN > tF || tF < 0.0) return vec2(-1.0); // no intersection
    
    outNormal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    return vec2( tN, tF );
}

// simple shapes combination
vec2 intersectBeam(vec3 ro, vec3 rd, out vec3 n)
{
    float d = 1000.;
    
    vec3 n1, n2, n3;
    
    float dist = 0.7;
    float dist2 = 0.1;
        
    vec3 pos = .5*dist*vec3(-.5, 0.5, -1.5);
    
    vec2 res1 = boxIntersection(ro-vec3(dist-dist2, 0., 2.*dist-2.*dist2) -pos, rd, vec3(dist, dist2, dist2), n1);
    if(res1.x>0.)
    {
        vec3 oo = vec3(-dist2, -dist2, dist2)+pos;
        vec3 nn = normalize(vec3(1., 0., -1.));
        
        float dd = dot(oo-ro, nn)/dot(rd,nn);
        
        
        if(dot(nn, ro+rd*res1.x-oo)<0.)
        {
            d = res1.x;
            n=n1;
        }
        else if(dd>res1.x && dd<res1.y)
        {
            d = dd;
            n = nn;
        }
    }
    
    vec2 res2 = boxIntersection(ro+vec3(0., dist-dist2, 0.)-pos, rd, vec3(dist2, dist, dist2), n2);
    if(d>res2.x && res2.x>0.)
    {
        d = res2.x;
        n=n2;
    }
    
    vec2 res3 = boxIntersection(ro-vec3(0., 0., dist-dist2)-pos, rd, vec3(dist2, dist2, dist), n3);
    if(d>res3.x && res3.x>0.)
    {
        d = res3.x;
        n=n3;
    }
    
    return vec2(d, max(0., dot(n, LIGHT_DIR)));
}

vec3 render(in vec3 ro, in vec3 rd)
{
    vec3 col = vec3(0.5);
    col = .1+.99*vec3(pow(max(0., dot(rd, LIGHT_DIR)), 2.));
    
    vec3 n;
    
    vec2 i = intersectBeam(ro, rd, n);
    
    if(i.x>0. && i.x<10.)
    {
        col = (.2+.99*max(0., dot(n, LIGHT_DIR))) * (.2+.998*abs(n));
    }
        
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main()
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/ resolution.y;
        
    // mouse camera control
    float phi = (iMouse.x-0.5)/resolution.x * PI * 2.0;
    float psi = -((iMouse.y-0.5)/resolution.y-0.5) * PI;
    
    if(iMouse.x<1.0 && iMouse.y < 1.0)
    {
        phi = time * PI * 2.0*0.1;
        psi = cos(time*PI*2.0*0.1)*PI*0.25;
    }
    
    // ray computation
    vec3 ro = 2.6*vec3(cos(phi)*cos(psi), sin(psi), sin(phi)*cos(psi));
    if(iMouse.x < 0.5) // x instead z
        ro = CAM_POS;
    
    vec3 ta = vec3(0.);
    mat3 m = setCamera(ro, ta, 0.0);
    vec3 rd = m*normalize(vec3(p, 2.));
    
    ro = 2.*ro + m[0]*p.x + m[1]*p.y;
    rd = m[2];
    
    // scene rendering (using oversampling)
    vec3 col;
    
    
    //for(float ii=-AA/2.+.5; ii<AA/2.; ii+=1.)
    //for(float jj=-AA/2.+.5; jj<AA/2.; jj+=1.)
    for(float ii=0.; ii<AA; ii+=1.)
    for(float jj=0.; jj<AA; jj+=1.)
    {
        col += render( ro, rd+(m[0]*ii+m[1]*jj)/AA/resolution.y/2.);
    }
    col /= AA*AA;
    
    // gamma correction
 //   col = sqrt(col);

    glFragColor = vec4(col, 1.0);
}
