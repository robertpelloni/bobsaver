#version 420

uniform float time;

out vec4 glFragColor;

uniform vec2 resolution;
// Modified by gigatron Starscroll v0.0.0.1.1.33285455 !!!

float field(in vec3 p,float s,  int idx) {
   float strength = 7. + .03 * log(1.e-6 + fract(sin(time) * 4373.11));
   float accum = s/4.;
   float prev = 0.;
   float tw = 0.;
   for (int i = 0; i < 26; ++i) {
      float mag = dot(p, p);
      p = abs(p) / mag + vec3(-.5, -.4, -1.5);
      float w = exp(-float(i) / 7.);
      accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
      tw += w;
      prev = mag;
   }
   return max(0., 1. * accum / tw - .7);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(2.9898,7.233))) * 8.5453);
}

vec3 nrand3( vec2 co )
{
   vec3 a = fract( sin( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
    
    
    
   vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
   vec3 c = a* b;
   return c;
}

void main()
    
{
    vec2 uv = 2. * gl_FragCoord.xy / resolution.xy - 1.;
   vec2 uvs = uv * resolution.xy / max(resolution.x, resolution.y);
   vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
   p += .1 * vec3(time/14., 0.,  0.);
  
   
   float freqs[4];
   freqs[0] = 0.05;
   freqs[1] = 0.3; 
   freqs[2] = 0.3;
   freqs[3] = 0.3; 
   
   float t = field(p,freqs[3], 26);
   float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
   
    //Second Layer
   vec3 p2 = vec3(uvs / (4.+1.), 1.5) + vec3(2., -1.3, -1.);
   p2 += 0.25 * vec3(time / 16., 1.0,  1.0);
   float t2 = field(p2,freqs[3], 18);
   vec4 c2 =  mix(.2, 0.2, v) * vec4(1.1 * t2 * t2 * t2 ,1.8  * t2 * t2 , t2* freqs[0], t2);
   
   // layer 3    
   vec3 p3 = p2;
   p3 += 0.25 * vec3(time / 12., 1.0,  1.0);
   float t3 = field(p3,freqs[3], 18);
   vec4 c3 =  mix(.2, 0.2, v) * vec4(1.1 * t3 * t3 * t3 ,1.8  * t3 * t3 , t3* freqs[0], t3);    
  
   //layer 4    
   vec3 p4 = p2;
   p4 += 0.25 * vec3(time / 08., 1.0,  1.0);
   float t4 = field(p4,freqs[3], 18);
   vec4 c4 =  mix(.2, 0.2, v) * vec4(1.1 * t4 * t4 * t4 ,1.8  * t4 * t4 , t4* freqs[0], t4); 
    
    
    
    
   
   //Let's add some stars
   //Thanks to http://glsl.heroku.com/e#6904.0
   vec2 seed = p.xy * 2.0;   
   seed = floor(seed * resolution.x);
   vec3 rnd = nrand3( seed );
   vec4 starcolor = vec4(pow(rnd.y,20.0));
  
   //Second Layer
   vec2 seed2 = p2.xy * 2.0;
   seed2 = floor(seed2 * resolution.x);
   vec3 rnd2 = nrand3( seed2 );
    
    vec2 seed3 = p3.xy * 2.0;
      seed3 = floor(seed3 * resolution.x);
    vec3 rnd3 = nrand3( seed3 );
    
    vec2 seed4 = p4.xy * 4.0;
      seed4 = floor(seed4 * resolution.x);
    vec3 rnd4 = nrand3( seed4 );
    
    
    
    
    
    starcolor += vec4(pow(rnd2.x*1.01,40.0));
    starcolor += vec4(pow(rnd3.x*1.01,40.0));
    starcolor += vec4(pow(rnd4.x*1.01,40.0));
   
   glFragColor = mix(freqs[3]-.5, 1.,1.0) * vec4(1.5*freqs[2] * t * t* t , 1.2*freqs[1] * t * t, freqs[3]*t, 1.0) +c2+starcolor;
}
