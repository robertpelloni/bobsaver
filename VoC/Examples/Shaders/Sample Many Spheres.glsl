#version 420

// original https://www.shadertoy.com/view/MdfGDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Alejandro Echeverria 2013
//const vec3 lightPosition = vec3(0.1, 0.5, 0.5);
const vec3 cameraPosition = vec3(0.5, 0.5, 1);

//ray-sphere intersection
float intersect(vec3 rayOrigin, vec3 rayDir, vec3 sphereCenter, float radius)
{
  float a = dot(rayDir, rayDir);
  float b = dot(rayOrigin - sphereCenter, rayDir);
  float c = dot(rayOrigin - sphereCenter, rayOrigin - sphereCenter) - radius*radius;
  
  float discr = b*b - a*c;
  if(discr < 0.0)
    return -1.0;
  
    discr = sqrt(discr);
    float t0 = (-b - discr) / a;
    float t1 = (-b + discr) / a;
  
    return min(t0, t1);
}

//Blinn phong shading
vec4 getColor(vec3 p, vec3 center, vec4 diffuseColor, vec3 lightPosition)
{
  vec3 n = p - center;
  n = normalize(n);
  vec3 l = lightPosition - p;
  l = normalize(l);  
  vec3 v = cameraPosition - p;
  v = normalize(v);
  vec3 h = v + l;
  h = normalize(h);
  return diffuseColor * max(0.0, dot(n,l)) + vec4(1.0,1.0,1.0,1.0) * max(0.0, pow(dot(n,h), 100.0));
}  

vec4 drawSphere(vec3 rayDir, vec3 pos, float r, vec4 color, vec3 light)
{
  float t = intersect(cameraPosition, rayDir, pos, r);
  if(t > -1.0)
    return getColor(cameraPosition + t*rayDir, pos, color, light);
  else
    return vec4(-1,-1,-1,-1);
}

void main(void)
{
  vec3 normalizedPosition = vec3(gl_FragCoord.xy / resolution.x, 0);
  vec2 normalizedMouse = mouse*resolution.xy.xy / resolution.x;
  vec3 rayDir = normalizedPosition - cameraPosition;
  rayDir = normalize(rayDir);

  vec4 outColor = vec4(0.0,0.0,0.0,1);      

  //Light
  vec3 lightPosition = vec3(10.0*normalizedMouse.x, 1.0, -10.0*normalizedMouse.y);    
    
  //Sphere1
  for(int z=10; z >= 0; z--)
  {
      for(int x = -5; x < 5; x++)
    {
          vec3 pos = vec3(x ,sin(time + float(z)/2.0),-z);
          vec4 color = vec4(1.0,0.0,0.0,1.0);
          float r = 0.25;
          vec4 sphereColor = drawSphere(rayDir, pos, r, color, lightPosition);
          if(sphereColor.x > -1.0)
            outColor = sphereColor;
    }
  } 
  glFragColor = outColor;
  
}
