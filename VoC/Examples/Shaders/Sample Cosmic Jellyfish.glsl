#version 420

// original https://www.shadertoy.com/view/wt33Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEP 0.01

float noise2(vec2 p)
{
   return fract(sin(dot(p,vec2(12.9898,78.233))) * 43758.5453);
}

float interpolateNoise2d(vec2 p)
{
   vec2 intp = floor(p);
   vec2 fractp = fract(p);

   float v1 = noise2(intp + vec2(0.,0.));
   float v2 = noise2(intp + vec2(1.,0.)); 
   float v3 = noise2(intp + vec2(0.,1.));
   float v4 = noise2(intp + vec2(1.,1.));

   float i1 = mix(v1 , v2 , fractp.x);
   float i2 = mix(v3 , v4 , fractp.x);
   return mix(i1 , i2 , fractp.y);
}

float getValue(vec2 p, float frequency)
{
   float total = 0.0;
   total += interpolateNoise2d(p * frequency);
   total += interpolateNoise2d(p * frequency * 2.);
   return total/2.;
}

vec3 displace(in vec3 pos)
{
   float t = abs(sin(0.5*time)); 
   float f = (1.0-t)*4.0 + t*4.8;
   float offset = getValue(pos.xy, f);
   offset = offset * 1.5 - 0.5; 
   vec3 normal = normalize(pos);
   vec3 tmp = pos + offset * normal; 
   return tmp;
}

float density(in vec3 local)
{
   vec3 dir = normalize(local);
   vec3 r = displace(dir);
   float rr = dot(r,r);
   float pp = dot(local,local);
   if (rr >= pp) // inside puff
   {
      return 0.5;
   }

   // Return r - |x|^2/r^2 inside sphere; 0 otherwise
   float tmp = sqrt(rr) - pp/rr;  
   return tmp > 0.000001? tmp : 0.0;
}

vec4 puffcolor(in vec3 local)
{
   vec4 inner = vec4(0.8, 0.0, 0.0, 1.0);  
   vec4 outer = vec4(1.0, 1.0, 0.0, 1.0);  
   float tmp = max(0.0, min(1.0, 1.0 - abs(length(local))));  
   return inner*tmp + (1.0-tmp)*outer;
}

vec4 background()
{
   vec4 bcolor1 = vec4(0.5, 0.0, 0.5, 1.0);
   vec4 bcolor2 = vec4(0.1, 0.0, 0.1, 1.0);
   float t = gl_FragCoord.y/resolution.y;
   return (1.0-t)*bcolor1 + t*bcolor2;
}

void main(void)
{
   vec2 pos = (4.*gl_FragCoord.xy - 2.*resolution.xy)/resolution.y;
   vec3 vo = vec3(0.0, 0.0, 2.0);
   vec3 vd = normalize(vec3(pos.xy,0.0) - vo);
   vec3 center = vec3(0.,0.1*sin(time)-0.2, 0.);

   float transmitivity = 1.0;
   float kappa = 0.2;
   vec4 color = vec4(0.0, 0.0, 0.0, 1.0); 
   vec4 diffuse = vec4(1.,1.,1.,1.);
   for (float t = 1.0; t < 4.0; t += STEP)
   {
      vec3 pt = vo + t*vd;
      vec3 local = pt - center;
    
      // Get color and transmitivity
      float density = density(local);
      float transmitivityDelta = exp(-kappa*STEP*density);
      transmitivity *= transmitivityDelta;

      vec4 pcolor = puffcolor(local);
      color = color + ((1.0 - transmitivityDelta)/kappa)*transmitivity*pcolor; 
   } 

   glFragColor = color + transmitivity*background();
}

