#version 420

// original https://www.shadertoy.com/view/tdlSRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//attempt to simulate a semi-realistic gas giant
//mostly based on Planet Funk by fizzer
//https://www.shadertoy.com/view/XssGWN

#define time time*0.8

float gamma = 2.2;
float scale = 1.5;
float exposure = 7.0;

float noise3D(vec3 p)
{
    return fract(sin(dot(p ,vec3(12.9898,78.233,128.852))) * 43758.5453)*2.0-1.0;
}

float simplex3D(vec3 p)
{
    
    float f3 = 1.0/3.0;
    float s = (p.x+p.y+p.z)*f3;
    int i = int(floor(p.x+s));
    int j = int(floor(p.y+s));
    int k = int(floor(p.z+s));
    
    float g3 = 1.0/6.0;
    float t = float((i+j+k))*g3;
    float x0 = float(i)-t;
    float y0 = float(j)-t;
    float z0 = float(k)-t;
    x0 = p.x-x0;
    y0 = p.y-y0;
    z0 = p.z-z0;
    
    int i1,j1,k1;
    int i2,j2,k2;
    
    if(x0>=y0)
    {
        if(y0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; } // X Y Z order
        else if(x0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; } // X Z Y order
        else { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; }  // Z X Z order
    }
    else 
    { 
        if(y0<z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; } // Z Y X order
        else if(x0<z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; } // Y Z X order
        else { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; } // Y X Z order
    }
    
    float x1 = x0 - float(i1) + g3; 
    float y1 = y0 - float(j1) + g3;
    float z1 = z0 - float(k1) + g3;
    float x2 = x0 - float(i2) + 2.0*g3; 
    float y2 = y0 - float(j2) + 2.0*g3;
    float z2 = z0 - float(k2) + 2.0*g3;
    float x3 = x0 - 1.0 + 3.0*g3; 
    float y3 = y0 - 1.0 + 3.0*g3;
    float z3 = z0 - 1.0 + 3.0*g3;    
                 
    vec3 ijk0 = vec3(i,j,k);
    vec3 ijk1 = vec3(i+i1,j+j1,k+k1);    
    vec3 ijk2 = vec3(i+i2,j+j2,k+k2);
    vec3 ijk3 = vec3(i+1,j+1,k+1);    
            
    vec3 gr0 = normalize(vec3(noise3D(ijk0),noise3D(ijk0*2.01),noise3D(ijk0*2.02)));
    vec3 gr1 = normalize(vec3(noise3D(ijk1),noise3D(ijk1*2.01),noise3D(ijk1*2.02)));
    vec3 gr2 = normalize(vec3(noise3D(ijk2),noise3D(ijk2*2.01),noise3D(ijk2*2.02)));
    vec3 gr3 = normalize(vec3(noise3D(ijk3),noise3D(ijk3*2.01),noise3D(ijk3*2.02)));
    
    float n0 = 0.0;
    float n1 = 0.0;
    float n2 = 0.0;
    float n3 = 0.0;

    float t0 = 0.5 - x0*x0 - y0*y0 - z0*z0;
    if(t0>=0.0)
    {
        t0*=t0;
        n0 = t0 * t0 * dot(gr0, vec3(x0, y0, z0));
    }
    float t1 = 0.5 - x1*x1 - y1*y1 - z1*z1;
    if(t1>=0.0)
    {
        t1*=t1;
        n1 = t1 * t1 * dot(gr1, vec3(x1, y1, z1));
    }
    float t2 = 0.5 - x2*x2 - y2*y2 - z2*z2;
    if(t2>=0.0)
    {
        t2 *= t2;
        n2 = t2 * t2 * dot(gr2, vec3(x2, y2, z2));
    }
    float t3 = 0.5 - x3*x3 - y3*y3 - z3*z3;
    if(t3>=0.0)
    {
        t3 *= t3;
        n3 = t3 * t3 * dot(gr3, vec3(x3, y3, z3));
    }
    return 96.0*(n0+n1+n2+n3);
    
}
//changed this for my liking
float fbm(vec3 p, vec3 n)
{
    float f;
    p = p*7.3;
    f  = 0.60000*pow((simplex3D( p )),3.0)*0.7+0.8;
    f += 0.35000*pow(abs(simplex3D( p + pow(vec3(f*n.x,f*n.y,f*n.z),vec3(3.0))*1.0)),0.8 )*1.0; p = p*2.02;
    f += 0.12500*pow(simplex3D( p + pow(vec3(f*n.x,f*n.y,f*n.z),vec3(2.0))*1.0),1.0 )*1.0; p = p*2.03;
    f += 0.1250*(simplex3D( p + pow(vec3(f*n.x,f*n.y,f*n.z),vec3(2.0))*1.0) ); p = p*4.04;
    f += 0.03125*(simplex3D( p + pow(vec3(f*n.x,f*n.y,f*n.z),vec3(2.0))*1.0) );
    return f;
}

#define ONE vec2(1.0, 0.0)
#define EPS vec2(1e-3, 0.0)

const float pi = 3.1415926;

float N(vec2 p)
{
   p = mod(p, 4.0);
   return fract(sin(p.x * 41784.0) + sin(p.y * 32424.0));
}

float smN2(vec2 p)
{
    vec2 fp = floor(p);
    vec2 pf = smoothstep(0.0, 1.0, fract(p));
    return mix( mix(N(fp), N(fp + ONE), pf.x), 
               mix(N(fp + ONE.yx), N(fp + ONE.xx), pf.x), pf.y);
}

float fbm2(vec2 p)
{
    float f = 0.0, x;
    for(int i = 1; i <= 9; ++i)
    {
        x = exp2(float(i));
        f += smN2(p * x) / x;
    }
    return f;
}

// Scalar field for the surface undulations.

float spots(vec2 p)//unused
{
    p *= 2.5;
    return smN2(p + EPS.xy * 2.0);
}

float field(vec2 p)
{
    p *= 1.5;
    return mix(smN2(p * 3.0), smN2(p * 4.0), 0.5 + 0.5 * cos(time * 0.02 + p.x*3.8 - 2.531)+ sin(time * 0.01 + p.y*4.2 + 1.536));
}

float field2(vec2 p)
{
    p *= 6.5;
    return mix(smN2(p * 2.0), smN2(p * 5.0), 0.5 + 0.5 * sin(time * 0.6 + p.x*2.0 + 83.123)+ cos(time * 0.5 + p.y*4.0 - 2.323));
}

float field3(vec2 p)
{
    p *= 0.6;
    return mix(smN2(p * 1.0), smN2(p * 2.0), 0.5 + 0.5 * cos(time * 0.5 + p.x*2.0 + 4.323));
}

// Vector field extracted from the scalar field.
vec2 flow(vec2 p)
{
    vec2 flowout = vec2(0.0,0.0);
    float f0 = field(p);
    float f1 = field(p + EPS.xy);
    float f2 = field(p + EPS.yx);
    flowout += (vec2(f1 - f0, f2 - f0)).yx * vec2(-1, 1) * 0.2;
    float f20 = field2(p);
    float f21 = field2(p + EPS.xy);
    float f22 = field2(p + EPS.yx);
    flowout += (vec2(f21 - f20, f22 - f20)).yx * vec2(-1, 1) * 0.05;
    float f30 = field3(p);
    float f31 = field3(p + EPS.xy);
    float f32 = field3(p + EPS.yx);
    flowout -= (vec2(f31 - f30, f32 - f30)).yx * vec2(-1, 1) * 0.1;
    return flowout;
}

void main(void) //WARNING - variables void ( out vec4 O, vec2 U ) need changing to glFragColor and gl_FragCoord
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    //scale *= (1.0-(mouse*resolution.xy.y / resolution.y))+0.5;
    //exposure *= ((mouse*resolution.xy.x / resolution.x))*0.5+0.01;
    
    vec2 R = resolution.xy, 
         M = mouse*resolution.xy.xy/R;
         U = (( U + U - R ) / R.y)*scale;     
        
    float l = length(U);
    
    vec3 N = vec3( U.x, U.y, sqrt(1.-l*l) );

    vec2 uv = vec2(1.0-atan(N.z, N.x) / (2.0*pi),1.0-(atan(length(N.xz), N.y)) / pi);
    //uv.x -= ((mouse*resolution.xy.x / resolution.x));   
    uv.x -= time*0.03+pow(cos(N.y*22.0)*0.03+0.97,2.5)*cos(N.y*1.0)*0.1;
    
    const int count = 5;
    float csum = 0.0;
    float wsum = 0.0;
    
    for(int i = 0; i < count; ++i)
    {
        float w = 1.0;
        uv += flow(uv);
        
        csum += fbm(vec3(uv,time*0.002)*5.0, N) * 0.15 * (0.5 + 0.5 * cos(float(i) / float(count) * 3.1415926 * 4.0 + time * 4.0)) * w;
        csum += fbm(vec3(uv,time*0.002)*12.0, N) * 0.15 * (0.5 + 0.5 * cos(float(i) / float(count) * 3.1415926 * 4.0 + time * 4.0)) * w;
        csum += fbm(vec3(uv,time*0.002)*27.0, N) * 0.15 * (0.5 + 0.5 * cos(float(i) / float(count) * 3.1415926 * 4.0 + time * 4.0)) * w;

        wsum += w;    

    }

    
     O = vec4(1.0);
    
    //all artistic values below
    vec3 skyext = vec3(0.6, 0.5, 0.45)*0.1;//sky extinction
    
    vec3 color = vec3(0.1,0.2,0.2);
    vec3 color1 = vec3(0.9,0.26,0.1)*0.7;
    vec3 color2 = vec3(0.4,0.4,0.32)*0.3;
    vec3 color3 = vec3(0.7,0.7,0.7);
    
    //mixing up the colors
    vec3 planet = mix(color1,color3,pow(sin(uv.y*89.0-time*0.05)*0.5+0.5,2.5));
    planet = mix(planet,color2,pow(sin(uv.y*25.0+0.3)*0.5+0.5,1.8));
    planet = mix(color3,planet,pow(cos(uv.y*47.0)*0.5+0.5,0.5));
    planet = mix(planet,planet*color,pow(cos(uv.y*9.0-1.3)*0.5+0.5,1.5));
    
    //more interesting mix between light and shadow
    O.rgb = mix(vec3(0.2,0.7,1.0)*0.0005,planet,(pow(csum/wsum,2.9)*pow(N.z,1.5)*(-N.x*0.5+0.5)/skyext));

    O.rgb *= exposure;
    O *= smoothstep(0.,3./R.y,1.-l);//AA
    O.rgb = pow(O.rgb,vec3(1.0/gamma));
    //O.rgb = planet;
    //O.rgb = vec3(uv.yy,0.0);

    glFragColor = O;
}
