#version 420

// original https://www.shadertoy.com/view/3ttyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct HitData{
    float rayLength;
    vec3 normal;
    vec3 color;
    float dTS;
};
    
vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}
 
    
vec2 sphereIntersect(vec3 r0,vec3 rd,vec3 s0,float sr)
{
    float t = dot(s0-r0,rd);
    vec3 p = r0 + rd*t;
    float y = length(s0-p);
    float x = sqrt(sr*sr-y*y);
    float t1 = t-x;
    
    if(y<sr){
     return vec2(t1,y);   
    }
    
    return vec2(-1.,y);
}

#define sphereCount 3
const vec4 spheres[sphereCount] = vec4[sphereCount](
    vec4(0.,0.,3.,1.),
    vec4(0.,0.,3.,1.),
    vec4(0.,-1001.,3.,1000.)
);

HitData getIntersection(vec3 r0,vec3 rd)
{
    HitData h;
    h.rayLength = 999999.0;
    h.color = vec3(0.5,0.7,0.3);
    
    for(int i = 0;i<sphereCount;i++){
        vec3 s0 = spheres[i].xyz;
        float sr = spheres[i].w;
        
        if(i==0){
         s0.y += abs(cos(time*4.23));
         s0.x += cos(time)*2.;
         s0.z += sin(time)*2.;
         //h.color = vec3(1.,0.07,0.3);
        }
        
        vec2 sphereData = sphereIntersect(r0,rd,s0,sr);
        float t = sphereData.x;
        if(i==0){
        h.dTS = sphereData.y;
        }
        
    
        if(t<h.rayLength && t >0.001){
            //if(i==0){
            //   h.color = vec3(1.,0.0,0.); 
            //}
            //if(i==1){
            //   h.color = vec3(0.0,0.0,1.); 
            //}
            
            h.color = hsl2rgb(vec3(float(i)/float(sphereCount),0.8,0.5));
            h.rayLength = t;
            
            vec3 p = r0 + rd*t;
            h.normal = normalize(p-s0);
        }
    }
    //vec3 s0 = vec3(0.,0.,2.);
    //float sr = 1.;
    
    
    
    //h.normal = vec3(0.);
    
    return h;
}
float rand01(float seed) { return fract(sin(seed)*43758.5453123); }
vec3 randomUnitSphere(vec3 rd,vec3 r0,float seed)
{
     return vec3(rand01(time * (rd.x + r0.x + 0.357)*seed ),
                rand01(time * (rd.y + r0.y + 16.35647)*seed ),
                rand01(time * (rd.z + r0.z + 425.357)*seed));
}

vec3 getFinalColor(vec3 r0, vec3 rd,float AAIndex){
    
    int bounces = 32;
    vec3 finalColor = vec3(0.6,0.7,0.8);
    float absorbMult = 1.;
    
    vec3 sun_dir = normalize(vec3(0.8,0.4,0.2));
    vec3 sky_dir = vec3(0.,1.,0.);
    
    
    for(int i = 0;i<bounces;i++){
        HitData h = getIntersection(r0 + rd*0.0001,rd);
        
        r0 += rd*h.rayLength;
        float roughness = 0.0;// + mouse*resolution.xy.x / resolution.x;
        rd = normalize(reflect(rd,h.normal + randomUnitSphere(rd,r0,AAIndex)*roughness));
        
        HitData sH = getIntersection(r0 + sun_dir*0.0001,sun_dir);
        float sun_sha = step(99999.0,sH.rayLength);
        float sun_dif = clamp(dot(h.normal,sun_dir),0.,1.);
        vec3 sun = vec3(1.,0.7,0.5)*0.5*sun_dif*sun_sha;
        float sky_dif = clamp(0.5 + 0.5*dot(h.normal,sky_dir),0.,1.);
        vec3 sky = vec3(0.,0.0,0.3)*sky_dif;
        
        if(h.rayLength>99999.0){
            //vec3 color = vec3(0.5,0.7,0.3);
            vec3 color = vec3(0.7,0.85,1.0);
            //finalColor = color*absorbMult;
            finalColor = mix(finalColor,color+sun+sky,absorbMult);
            break;
        }
        
        finalColor = mix(finalColor,h.color+sun+sky,absorbMult);
        
        absorbMult *= 0.8;
        
        
        
    }
    
     return finalColor;   
}

void main(void)
{
    vec2 R = resolution.xy;
    vec2 U = gl_FragCoord.xy;
    U*= 2./R;
    U -= 1.;
    U.x *= R.x/R.y;
    
    vec3 r0 = vec3(0.,-sin(time)*2. + 1.,-6.);
    vec3 focus = vec3(0.,sin(time)*1.2 -.2,0.);
    vec3 rd = normalize(focus + vec3(U,4.));
    vec3 c = vec3(0.);
    int m = int(step(0.001,mouse*resolution.xy.x / resolution.x)*15. +1.);
    m= 16;
    for(int i = 1;i<=m;i++){
        c += getFinalColor(r0,rd,float(i));
    }
    c /= float(m);
    //vec3 c = getFinalColor(r0,rd);
    c.rgb = pow(c.rgb,vec3(1.0/2.2));
    
    glFragColor = vec4(c,1.);
}
