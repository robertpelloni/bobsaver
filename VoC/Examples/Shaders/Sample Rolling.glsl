#version 420

// original https://www.shadertoy.com/view/7ssSzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 120
#define MAX_DIST 120.
#define SURF_DIST .01

float GetDistance(vec3 point) {
    
    float texture = sin((time + point.x)*.5)*2.7+cos(point.z*2.5+sin(time)*5.)*.1+sin(point.x*5.+point.z*10.)*0.03;
    float planeDist = point.y + texture*.5;
    
    float planeDist2 = -point.y + 3. + texture*.5;;
    
    return min(planeDist,planeDist2);
}

vec3 GetNormal(vec3 point) {
  float distance = GetDistance(point);
  vec2 e = vec2(.01,0);
  
  vec3 normal = distance - vec3(
      GetDistance(point-e.xyy),
      GetDistance(point-e.yxy),
      GetDistance(point-e.yyx));
  
  return normalize(normal);
}

vec2 RayMarch(vec3 rayOrgin, vec3 rayDirection) {
    float distance=0.;
    
    int steps = MAX_STEPS; 
    int i = 0;
    
    for(i=0; i<steps; i++) {
        vec3 point = rayOrgin + rayDirection * distance;
        float surfaceDistance = GetDistance(point);
        distance += surfaceDistance;
        // Stop marching if we go too far or we are close enough of surface
        if(distance>MAX_DIST || surfaceDistance<SURF_DIST) break;
    }
    
    return vec2(distance,i);
}

float GetLight(vec3 point, vec3 normal, vec3 lightPos) {    
  
  vec3 direction = normalize(lightPos-point);
  
  float dif = clamp(dot(normal, direction), 0., 1.);
  
  float d = RayMarch(point+normal*.1, direction).x;
  if ( d < length(lightPos-point)) dif *= .5;
  
  return dif;
}

void main(void)
{
    // put 0,0 in the center
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
       
    // camera   
    vec3 rayOrgin = vec3(0, 1.5, 0);
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));

    vec2 d = RayMarch(rayOrgin, rayDirection);
    
    vec3 col = vec3(0.);
    
    vec3 lightPos = vec3(1, 1.5, 1);
    
    if (d.x < 120.) {
        vec3 p = rayOrgin + rayDirection * d.x;
        vec3 n = GetNormal(p);
        float light = GetLight(p, n, lightPos);
        // color
        float dist = d.x/50.;
        col = vec3(
            light-dist,
            light-dist/1.5+(d.y*0.004),
            light-dist/2.+(d.y*0.005)
        );
    }
    glFragColor = vec4(col,1.0);
}
