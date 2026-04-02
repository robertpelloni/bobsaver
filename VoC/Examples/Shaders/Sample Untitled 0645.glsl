#version 420

// original https://www.shadertoy.com/view/fdSSWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Sphere {
    vec3 position;
    vec3 color;
    float radius;
    float dist;
};

struct Ray {
    vec3 origin;
    vec3 direction;
    float t;
};

const int MAX_SPHERES = 2;
const float EPSILON = 0.01;
const int MAX_STEPS = 10000;
const float RENDER_DISTANCE = 1000.0;
const vec3 light = vec3(-2.0, 5.0, -3.0);

Sphere SPHERES[MAX_SPHERES];

float SDF_Sphere(Sphere sphere, vec3 p) {
    return length(sphere.position - p) - sphere.radius;
}

float mapWorld(vec3 p) {
  float modifier = (cos(time)*0.5+1.5)*3.0;
  float displacement = sin(p.x * modifier) * sin(p.y * modifier) * sin(p.z * modifier) * 0.25;
    
  SPHERES[0].position = vec3(0.0, 0.0, 0.0);
  SPHERES[0].color = vec3(1.0, 0.0, 0.0);
  SPHERES[0].radius = 1.0;
  SPHERES[0].dist = SDF_Sphere(SPHERES[0], p);
  
  return SPHERES[0].dist + displacement;
}

vec3 calcNormal(vec3 p) {
  const vec3 epsilonStep = vec3(EPSILON, 0.0, 0.0);
  
  float gX = mapWorld(p+epsilonStep.xyy) - mapWorld(p - epsilonStep.xyy);
  float gY = mapWorld(p+epsilonStep.yxy) - mapWorld(p - epsilonStep.yxy);
  float gZ = mapWorld(p+epsilonStep.yyx) - mapWorld(p - epsilonStep.yyx);
  
  return normalize(vec3(gX,gY,gZ));
}

vec3 raymarch(inout Ray ray) {
      for (int i=0; i<MAX_STEPS; i++) {
          vec3 cp = ray.origin+(ray.direction*ray.t);
          float dist = mapWorld(cp);
          
          
          if (dist < EPSILON) {
              vec3 normal = calcNormal(cp);
              float diffuseMix = max(dot(normalize(light - cp), normal),0.0);
              float specularAngle = pow(max(dot(normalize(reflect(ray.direction, normal)), normalize(light - cp)),0.0), 10.0);
              return (vec3(1.0, 0.0, 0.0)*diffuseMix*(1.0 - specularAngle) + specularAngle) + (vec3(1.0, 1.0, 0.0) * 0.2);
          } else if (dist > RENDER_DISTANCE) {
              break;
          }
          ray.t += dist;
  }
  return vec3(0.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    
    Ray primaryRay;
    primaryRay.origin = vec3(0.0, 0.0, -4.0);
    primaryRay.direction = normalize(vec3(uv.x, uv.y, 1.0));
    primaryRay.t = 0.0;
    
    vec3 col = raymarch(primaryRay);
    glFragColor = vec4(col,1.0);
}
