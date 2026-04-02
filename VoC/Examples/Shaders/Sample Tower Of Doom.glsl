#version 420

// original https://www.shadertoy.com/view/3d33WX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/tstGD2
///based on https://www.shadertoy.com/view/3l23Rh //

mat2 rot(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
const mat3 m3 = mat3(0.33338, 0.56034, -0.71817, -0.87887, 0.32651, -0.15323, 0.15162, 0.69596, 0.61339)*1.93;
float mag2(vec2 p){return dot(p,p);}
float linstep(in float mn, in float mx, in float x){ return clamp((x - mn)/(mx - mn), 0., 1.); }
float prm1 = 0.;
vec2 bsMo = vec2(0);

float hash(float n)
{
    return fract(sin(n) * 43758.5453);
}

///
/// Noise function
///
float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    
    f = f * f * (3.0 - 2.0 * f);
    
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    
    float res = mix(mix(mix(hash(n +   0.0), hash(n +   1.0), f.x),
                        mix(hash(n +  57.0), hash(n +  58.0), f.x), f.y),
                    mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                        mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
    return res;
}

///
/// Fractal Brownian motion.
///
/// Refer to:
/// EN: https://thebookofshaders.com/13/
/// JP: https://thebookofshaders.com/13/?lan=jp
///
float fbm(vec3 p)
{
    float f;    
   // p = p*m3;
  //  p = sin(p.xyz*0.75 + time*.08);
    f  = 0.5000 * noise(p); p =  p * 2.02;
    f += 0.2500 * noise(p); p =  p * 2.03;
    f += 0.1250 * noise(p); 
    f += 0.1250 * noise(p*30.);
    return f;
}
float map5( in vec3 p )
{    p.x = p.z+p.x;  
 p = sin(p.xyz*1.75 + time*.0);
    vec3 q = p - vec3(1.10,01.0,1.0)*time*0.4;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q ); q = q*2.02;
    f += 0.03125*noise( q );
    return  clamp(p.x* 1. - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

float sphere(vec3 ro,vec3 p,float s)
{
//return length(ro-p)-s;
      return  length(ro-p)  * -s + fbm(ro * 0.3);;
} 

vec2 disp(float t){ return vec2(sin(t*0.22)*1., cos(t*0.175)*1.)*2.; }
float scene(in vec3 p)
{ /*p.xy *= rot(sin(p.z+time)*(0.1 + prm1*0.05) + time*0.09);
   // p = sin(p.xyz*0.75 + time*.8);
       p -= abs(dot(cos(p), sin(p.yzx)));*/
   p = p*m3*0.01;
  p.xy -= disp(p.z).xy;
  // p +=p+0.0*p*.5*fbm(p * 0.01)*m3;// fbm(p * .3)*.0;

    return  map5(  p );//length(p) * -0.00591+ fbm(p * .3);
}
vec2 map(vec3 ro){
float res=0.0;
float color=0.;
res=  sphere(ro,vec3(0.0,1.0 ,0.0),20.5) ;
 

if(res==sphere(ro,vec3(0.0,1.52 ,3.0),2.5))color=2.;
 

return vec2(res,color);}

vec4 march(vec3 ro,vec3 rd)
{
float d=0.0; //
float material=0.;  
    // Transmittance
    float T = 1.0;
    // Substantially transparency parameter.
    float absorption = 100.0;
    vec4 color = vec4(0.0);
   for (int i = 0; i < 64; i++)
    {
        // Using distance function for density.
        // So the function not normal value.
        // Please check it out on the function comment.
        float d = scene(ro);
        
        // The density over 0.0 then start cloud ray marching.
        // Why? because the function will return negative value normally.
        // But if ray is into the cloud, the function will return positive value.
        if (d > 0.0)
        {
            // Let's start cloud ray marching!
           // d = abs(dot(cos(d*20.), sin(1.1-rd.z)));
          //ro = ro*rd*m3;
            d/=0.51;
            // why density sub by sampleCount?
            // This mean integral for each sampling points.
            float tmp = d / float(64);
            
            T *= 1.0 - (tmp * absorption);
            
            // Return if transmittance under 0.01. 
            // Because the ray is almost absorbed.
            if (T <= 0.01)
            {
                break;
            }
            
            
            // Add ambient + light scattering color
            float opaity = 8.0;
            float k = opaity * tmp * T;
            vec4 cloudColor = vec4(1.0);
        cloudColor = vec4(sin(vec3(5.,0.4,0.2) +  +sin(d*0.4)*0.5 + 1.8)*1.5 + 0.5,0.08);
  // cloudColor.xyz *= d*(vec3(0.005,.045,.075) + 1.5*vec3(0.33,0.07,0.03));
     
            vec4 col1 =((rd.y*.00083))*vec4(-1.51,10.,5.,0.10)+ cloudColor * k/2.;
           col1=vec4(1.5,-1.,1.,10.)*col1.xyzw;
            col1.xyz+=+col1.xyz*-m3*0.51;
            
            color += col1*15. ;
        }
        
      ro += rd * 20.;
    //    ro+= clamp(01.5 - d*d*.5, 0.9, -2.3);
       
    }
    
   
            return 0.31+ color*color*.75;

}

vec4 render(vec3 ro,vec3 rd){

return march(ro,rd);//+vec4(glowmarch(ro,rd).rgb,1.)+vec4(glowmarch1(ro,rd).rgb*glowmarch1(ro,rd).a,1);
//march(ro,rd)*

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 rd = normalize(vec3(gl_FragCoord.xy - resolution.xy*.5, resolution.y*.75)); 
vec2 mo = vec2(time * 0.1, cos(time * 0.25) * 3.0);
      // Camera
    float camDist = 25.0;
    
    // target
    vec3 ta = vec3(0.0, 1.0, 0.0);
    
    // Ray origin
    //vec3 ori = vec3(sin(time) * camDist, 0, cos(time) * camDist);
    vec3 ro = camDist * normalize(vec3(cos(2.75 - 3.0 * mo.x), 0.7 - 1.0 * (mo.y - 1.0), sin(2.75 - 3.0 * mo.x)));
     
    // Ray origin. oving along the Z-axis.
  ro = vec3(1,1500.,-1200.+time*250.);
 
    
  
    // Output to screen
   vec4  res=render(ro,rd)*render(ro,rd);
    
  
    // res+=vec4(0.5,-res.x*1.5,res.z*30,0.5);
    glFragColor = vec4 (res.rgb,1.0);
}
