#version 420

// original https://www.shadertoy.com/view/ltsBzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI                3.1415926535
#define ABSORBANCE        1.0
#define LIGHT_DIR        normalize(vec3(cos(-time*.3+PI*.5), 1.0, sin(-time*.3+PI*.5)))
#define CAM_POS         vec3(4.*cos(-time*.3), 4.0, 4.*sin(-time*.3))

vec2 boxIntersection( vec3 ro, vec3 rd, vec3 boxSize, mat4 txx, out vec3 outNormal )
{
    // convert from ray to box space
    vec3 rdd = (txx*vec4(rd,0.0)).xyz;
    vec3 roo = (txx*vec4(ro,1.0)).xyz;

    vec3 m = 1.0/rd;
    vec3 n = m*roo;
    vec3 k = abs(m)*boxSize;

    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );

    if( tN > tF || tF < 0.0) return vec2(-1.0); // no intersection

    outNormal = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    return vec2( tN, tF );
}

vec3 render(in vec3 ro, in vec3 rd)
{
    
    float t = (-0.-ro.y)/rd.y;
    
    //t = 100.0;
    
    
    if(t<0.)
        t = 10000.;
    
    vec3 col = mix(vec3(0.9), vec3(0.5,0.6,0.9), 1.-exp(-0.05*t));
    
    vec3 n;    
    
    vec3  color[6]     = vec3[](
        vec3(1., 0., 0.), 
        vec3(1., 1., 0.), 
        vec3(0., 1., 0.), 
        vec3(0., 1., 1.), 
        vec3(0., 0., 1.), 
        vec3(1., 0., 1.));
    
    vec3 size = vec3(1., 1./6., 1.);
    mat4 txx = mat4(1., 0., 0., 0., 0., 1., 0., 0., 0., 0., 1., 0., 0. , 0., 0., 1.);
    
    
    if(t < 100.)
    {
        vec3 roo = ro+rd*t;
        vec3 rdd = LIGHT_DIR;
        vec3 lightCol = vec3(1.);
        
        
        for(int k = 0; k<6; ++k)
        {
            int kk = rdd.y<0.?k:5-k;
            txx[3].y = -1.0/6.-2./6.*float(kk);
            vec2 tnf = boxIntersection(roo, rdd, size, txx, n);
            float depth = max(0., min(t,tnf.y)-max(0., tnf.x));
            lightCol = mix(lightCol, vec3(0.0), 1.-exp(-ABSORBANCE*depth*color[kk]));
        }
        
        col *= lightCol;
    }
    
    
    
    
    for(int k = 0; k<6; ++k)
    {
        int kk = rd.y<0.?k:5-k;
        txx[3].y = -1.0/6.-2./6.*float(kk);
        vec2 tnf = boxIntersection(ro, rd, size, txx, n);
        float depth = max(0., min(t,tnf.y)-max(0., tnf.x));
        //float depth = tnf.y - tnf.x;
        col = mix(col, color[kk], 1.-exp(-ABSORBANCE*depth));
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

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/ resolution.y;
        
    float phi = (mouse.x*resolution.x-0.5)/resolution.x * PI * 2.0;
    float psi = -((mouse.y*resolution.y-0.5)/resolution.y-0.5) * PI;
    
    if(mouse.x*resolution.x<1.0 && mouse.y*resolution.y < 1.0)
    {
        phi = time * PI * 2.0*0.1;
        psi = cos(time*PI*2.0*0.1)*PI*0.25;
    }
    
    vec3 ro = 5.0*vec3(cos(phi)*cos(psi), sin(psi), sin(phi)*cos(psi));
    ro = CAM_POS;
    vec3 ta = vec3(0., .5, .0);
    mat3 m = setCamera(ro, ta, 0.0);
    
    vec3 rd = m*normalize(vec3(p, 2.));
    
    // scene rendering
    vec3 col = render( ro, rd);
    
    // gamma correction
    col = sqrt(col);

    glFragColor = vec4(col, 1.0);
}
