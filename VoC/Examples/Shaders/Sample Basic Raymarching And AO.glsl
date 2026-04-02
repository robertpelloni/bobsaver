#version 420

// original https://www.shadertoy.com/view/td23RK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// movement variables
  vec3 movement = vec3(.0);
  
  const float clipNear = 0.;
  const float clipFar = 64.;
  
  const int maxIterations = 256;
  const float stopThreshold = 0.001;
  const float stepScale = .7;
  const float eps = 0.01;
  
  const vec3 clipColour = vec3(0.);
  const vec3 fogColour = vec3(0.);
  
  const vec3 light1_colour = vec3(.8, .8, .85);
  const vec3 light1_position = vec3(.3, .3, 1.);
  const float light1_attenuation = 0.01;
  const float scene_attenuation = 0.01;
  
  struct Surface {
    int object_id;
    float distance;
    vec3 position;
    vec3 colour;
    float ambient;
    float spec;
  };
  
  // This function describes the world in distances from any given 3 dimensional point in space
  float world(in vec3 position, inout int object_id) {
    float z = position.z * .1;
    float c = cos(z);
    float s = sin(z);
    position.xy *= mat2(c, -s, s, c);
    vec3 pos = floor(position * 2.);
    object_id = int(floor(pos.x + pos.y + pos.z));
    position = mod(position, .5) - .25;
    return length(position) - .12;
  }
  float world(in vec3 position) {
    int dummy = 0;
    return world(position, dummy);
  }
  
  vec3 getObjectColour(int object_id) {
    float modid = mod(float(object_id), 5.);
    if(modid == 0.) {
      return vec3(.3, 0.2, 0.5) * 2.;
    } else if(modid == 1.) {
      return vec3(.5, 0.5, 0.3) * 2.;
    } else if(modid == 2.) {
      return vec3(.5, 0.4, 0.5) * 2.;
    } else if(modid == 3.) {
      return vec3(.2, 0.5, 0.4) * 2.;
    } else if(modid == 4.) {
      return vec3(.2, 0.5, 0.2) * 2.;
    }
  }
  
  Surface getSurface(int object_id, float rayDepth, vec3 sp) {
    return Surface(
      object_id, 
      rayDepth, 
      sp, 
      getObjectColour(object_id), 
      .5, 
      100.);
  }
  
  // The raymarch loop
  Surface rayMarch(vec3 ro, vec3 rd, float start, float end) {
    float sceneDist = 1e4;
    float rayDepth = start;
    int object_id = 0;
    for(int i = 0; i < maxIterations; i++) {
      sceneDist = world(ro + rd * rayDepth, object_id);
      
      if(sceneDist < stopThreshold || rayDepth > end) {
        break;
      }
      
      rayDepth += sceneDist * stepScale;
    }
    
    return getSurface(object_id, rayDepth, ro + rd * rayDepth);
  }
  
  // Calculated the normal of any given point in space. Intended to be cast from the point of a surface
  vec3 calculate_normal(in vec3 position) {
    vec3 grad = vec3(
      world(vec3(position.x + eps, position.y, position.z)) - world(vec3(position.x - eps, position.y, position.z)),
      world(vec3(position.x, position.y + eps, position.z)) - world(vec3(position.x, position.y - eps, position.z)),
      world(vec3(position.x, position.y, position.z + eps)) - world(vec3(position.x, position.y, position.z - eps))
    );
    
    return normalize(grad);
  }
  
  // Original by IQ
  float calculateAO(vec3 p, vec3 n)
  {
     const float AO_SAMPLES = 8.0;
     float r = 0.0;
     float w = 1.0;
     for (float i=1.0; i<=AO_SAMPLES; i++)
     {
        float d0 = i * 0.15;
        r += w * (d0 - world(p + n * d0));
        w *= 0.5;
     }
     return 1.0-clamp(r,0.0,1.0);
  }
  
  vec3 lighting(Surface surface_object, vec3 cam) {
    
    // start with black
    vec3 sceneColour = vec3(0);
    
    // Surface normal
    vec3 normal = calculate_normal(surface_object.position);
    
    // Light position
    vec3 lp = light1_position + movement;
    // Light direction
    vec3 ld = lp - surface_object.position;
    
    // light attenuation
    // For brightly lit scenes or global illumination (like sunlit), this can be limited to just normalizing the ld
    float len = length( ld );
    ld = normalize(ld);
    float lightAtten = min( 1.0 / ( light1_attenuation*len ), 1.0 );
    // lightAtten = 1.;
    
    // Scene values, mainly for fog
    float sceneLength = length(cam - surface_object.position);
    float sceneAttenuation = min( 1. / ( scene_attenuation * sceneLength * sceneLength ), 1. );
    
    // The surface's light reflection normal
    vec3 reflection_normal = reflect(-ld, normal);
    
    // Ambient Occlusion
    float ao = calculateAO(surface_object.position, normal);
   // ao *= ao * ao;
    // ao = 1.;
    
    // Object surface properties
    float diffuse = max(0., dot(normal, ld));
    float specular = max(0., dot( reflection_normal, normalize(cam - surface_object.position) ));
    specular = pow(specular, surface_object.spec); // Ramping up the specular value to the specular power for a bit of shininess.
    
    // Bringing all of the lighting components together
    sceneColour += ( surface_object.colour * (diffuse + surface_object.ambient) + specular ) * light1_colour * lightAtten * ao;
    // adding fog
    sceneColour = mix( sceneColour, fogColour, 1. - sceneAttenuation );
    
    // return vec3(ao);
    return sceneColour;
  }
  
  vec3 path(float z) {
    return vec3(0,0,-5000.+z);
  }

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / min(resolution.y, resolution.x);
    
    float t = time * .2;
    
    // movement
    movement = path(time);
    
    // Camera and look-at
    vec3 cam = vec3(0,0,-1);
    vec3 lookAt = vec3(sin(t)*.25,0,0);
    
    // add movement
    lookAt += movement;
    cam += movement;
    
    // Unit vectors
    vec3 forward = normalize(lookAt - cam);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x));
    vec3 up = normalize(cross(forward, right));
    
    // FOV
    float FOV = .4;
    
    // Ray origin and ray direction
    vec3 ro = cam;
    vec3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
    
    float s = sin(t);
    float c = cos(t);
    rd.xy *= mat2(c, -s, s, c);
    
    // Ray marching
    Surface objectSurface = rayMarch(ro, rd, clipNear, clipFar);
    if(objectSurface.distance > clipFar) {
      glFragColor = vec4(clipColour, 1.);
      return;
    }
    
    vec3 sceneColour = lighting(objectSurface, cam);

    // Output to screen
    glFragColor = vec4(sceneColour, 1.);
}
