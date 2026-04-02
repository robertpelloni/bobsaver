#version 420

// original https://www.shadertoy.com/view/4dtyz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This is some of the messiest code I've ever written.

// If like me you're computer is a bit of a potato, uncomment the line below.
// #define POTATO_QUALITY

#define AO_STEPS 2.0
#define AO_INTENSITY 5.0
#define AO_AOI 0.1

#define DOOR_CLOSE_LEN 6.1

// Originally it was going to wait a bit
// before lighting up, but as it turns out
// it looks waaaay better if you basically do it
// as the doors are closing
#define SLOW_LIGHT_UP_PAUSE -6.1
#define SLOW_LIGHT_UP_LEN 10.1

#define SLOW_LU_START DOOR_CLOSE_LEN + SLOW_LIGHT_UP_PAUSE
#define SLOW_LU_END SLOW_LU_START + SLOW_LIGHT_UP_LEN

#define RAY_MARCH_C 64
#define POLICE_LIGHTS_FREQ 7.

#define HALF_PI 1.57079632679

float random(vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float opU(float d1, float d2) { return min(d1, d2); }

float opS(float d1, float d2) {
  // For whatever reason max(-d1, d2)
  // does some weird stuff for me, which
  // is probably a symptom that I'm doing something
  // a bit weird
  return max(0.1 - d1, d2);
}

float opI(float d1, float d2) { return max(d1, d2); }

vec3 opRep(vec3 p, vec3 c) { return mod(p, c) - 0.5 * c; }

float sphere(vec3 p, float r) { return length(p) - r; }

float plane(vec3 p, vec4 n) { return dot(p, n.xyz) + n.w; }

float box(vec3 p, vec3 b) { return length(max(abs(p) - b, 0.0)); }

float round_box(vec3 p, vec3 b, float r) {
  return length(max(abs(p) - b, 0.0)) - r;
}

vec3 rotateX(vec3 p, float radian) {
  mat3 m = mat3(1.0, 0.0, 0.0, 0.0, cos(radian), -sin(radian), 0.0, sin(radian),
                cos(radian));
  return m * p;
}

vec3 rotateY(vec3 p, float radian) {
  mat3 m = mat3(cos(radian), 0.0, sin(radian), 0.0, 1.0, 0.0, -sin(radian), 0.0,
                cos(radian));
  return m * p;
}

vec3 rotateZ(vec3 p, float radian) {
  mat3 m = mat3(cos(radian), -sin(radian), 0.0, sin(radian), cos(radian), 0.0,
                0.0, 0.0, 1.0);
  return m * p;
}

struct Camera {
  vec3 position;
  vec3 look_at;
  vec3 up;
  float focus;
};

vec3 get_ray_direction(Camera cam, vec2 uv) {
  // Get the direction the camera is facing, based on what
  // it's supposed to be looking at
  vec3 cam_direction = normalize(-(cam.position + cam.look_at));
  vec3 cam_side = cross(cam_direction, cam.up);

  // Get the normalized ray direction
  return normalize(
      vec3(cam_side * uv.x + cam.up * uv.y + cam_direction * cam.focus));
}

void cabinet(const in vec3 p, inout float dist) {

  dist = opU(dist, box(p + vec3(9.3, -1.9, 1.), vec3(1.1, 1.8, 1.75)));
  dist = opU(dist, sphere(p + vec3(8.2, -1.9, 1.4), 0.1));
  dist = opU(dist, sphere(p + vec3(8.2, -1.9, 0.8), 0.1));
  dist = opU(dist, box(p + vec3(8.17, -3.5, 1.), vec3(0.1, 0.05, 1.3)));
  dist = opU(dist, box(p + vec3(8.17, -3.1, 1.), vec3(0.1, 0.05, 1.3)));
}

void backwall(const in vec3 p, inout float dist) {

  float door_open_amount = pow(smoothstep(DOOR_CLOSE_LEN, 0., time), 1.5);
  float wall = plane(p + vec3(0., 0., -13.), vec4(0., 0.2, -1.0, 0.));
  wall = opS(plane(p + vec3(0., 0., -14.), vec4(0., 0.2, -1.0, 0.)), wall);
  wall =
      opS(box(p + vec3(0., 0., -13.), vec3(door_open_amount, 13., 23.)), wall);
  dist = opU(dist, wall);
}

void toys(const in vec3 p, inout float dist) {

  dist = opU(dist, sphere(p + vec3(8.3, -.4, -1.), 0.5));
    
  dist = opU(dist, sphere(p + vec3(5.3, -.2, -2.), 0.3));
    
  vec3 rpA = rotateY(p+vec3(-6, 0.1, -3), 0.6);  
  dist = opU(dist, box(rpA, vec3(.3,.3,.3)));
    
  vec3 rpB = rotateY(p+vec3(-6, -.55, -3), 0.1);  
  dist = opU(dist, box(rpB, vec3(.3,.3,.3)));
    
  vec3 rpC = rotateY(p+vec3(-5, -.1, -2), 0.1);  
  dist = opU(dist, box(rpC, vec3(.4,.4,.4)));
  
}

void environment(const in vec3 p, inout float dist) {

  // Create the floor
  dist = opU(dist, plane(p, vec4(0.01, 1.0, 0.1, 0.0)));

  // Walls
  dist = opU(dist, plane(p + vec3(11., 0., 0.), vec4(1., 0.15, 0.2, 0.0)));
  dist = opU(dist, plane(p + vec3(-12.3, 0., 0.), vec4(-1., 0.15, 0.2, 0.0)));
  dist = opU(dist, plane(p + vec3(0., 0., 9.), vec4(0., 0.2, 1.0, 0.)));

  // Ceiling
    
  dist = opU(dist, plane(p + vec3(0., -32, .0), vec4(0.01, -1.0, 0.1, 0.0)));
  dist = opS(plane(p + vec3(0., -36, .0), vec4(0.01, -1.0, 0.1, 0.0)), dist);

  // Cut out side hollow
  dist = opS(box(p + vec3(-11., -7, 2.9), vec3(3., 2.0, 2.3)), dist);

  // Cut out window on the left
  //dist = opS(box(p + vec3(11., -10, 2.9), vec3(3., 5.0, 2.3)), dist);
  dist = opS(box(p + vec3(11., -13.5, 2.075), vec3(3., 2.525, 0.975)), dist);
  dist = opS(box(p + vec3(11., -13.5, 4.25), vec3(3., 2.525, 0.975)), dist);
  dist = opS(box(p + vec3(11., -7.5, 2.075), vec3(3., 2.525, 0.975)), dist);
  dist = opS(box(p + vec3(11., -7.5, 4.25), vec3(3., 2.525, 0.975)), dist);

  dist = opS(plane(p + vec3(11.5, 0., 1.), vec4(1., 0.15, 0.2, 0.)), dist);

  // Add cabinet
  cabinet(p, dist);

  // Add toys
  toys(p, dist);

  // Only bother doing the backwall
  // if the door hasn't been closed
  if (time < DOOR_CLOSE_LEN) {
    backwall(p, dist);
  }
}

void bed_child(const in vec3 p, inout float dist) {

  // Bed base
  vec3 rp = rotateX(p, 0.23);
  rp -= vec3(0., 0.1, .0);
  dist = opU(dist, round_box(rp + vec3(0, -1.6, 5), vec3(3.1, 0.5, 9.), 0.4));

  // Pillow
  dist = opU(dist, round_box(rp + vec3(0, -3, 8), vec3(1.1, 0.9, 1.), 1.0));

  // Sheet
  dist = opU(dist, round_box(rotateX(rp, 0.05) + vec3(0, -2.7, 2),
                             vec3(2.5, 0.05, 6.), .01));

  // Head
  dist = opU(dist, sphere(rp + vec3(0., -3.3, 6.), 0.7));

  // Hands
  dist = opU(dist, sphere(rp + vec3(1.4, -3.1, 6.), 0.3));
  dist = opU(dist, sphere(rp + vec3(-1.4, -3.1, 6.), 0.3));
}

float scene_distance(const in vec3 p) {
  // Start out by saying everying
  // is infinitly away
  float dist = 1. / 0.;

  // Get the environment
  environment(p, dist);
  bed_child(p, dist);

  return dist;
}

vec3 ray_march(const in vec3 start_pos, const in vec3 ray_direction) {
  // Start off at the cameras position
  vec3 position = start_pos;
  // Ray march forward
  float t = 0.0;
  for (int i = 0; i < RAY_MARCH_C; ++i) {
    t += scene_distance(position);
    position = start_pos + t * ray_direction;
  }
  return position;
}

vec3 get_normal(const in vec3 p) {
  const float d = 0.0001;
  return normalize(vec3(scene_distance(p + vec3(d, 0.0, 0.0)) -
                            scene_distance(p - vec3(d, 0.0, 0.0)),
                        scene_distance(p + vec3(0.0, d, 0.0)) -
                            scene_distance(p - vec3(0.0, d, 0.0)),
                        scene_distance(p + vec3(0.0, 0.0, d)) -
                            scene_distance(p - vec3(0.0, 0.0, d))));
}

float get_shadow(vec3 light_pos, vec3 p, vec3 light_dir, float light_dist,
                 float shadow_intensity) {
  vec3 shadow = ray_march(light_pos, -light_dir);
  float shadow_distance = distance(light_pos, shadow);
  // return step(light_dist, shadow_distance);
  // return smoothstep(0.0, light_dist, shadow_distance);
  return pow(smoothstep(0.0, light_dist, shadow_distance), shadow_intensity);
}

vec3 direct_light(vec3 direction, vec3 colour, vec3 normal, float spec_roll,
                  float spec_intensity) {
  return colour * (dot(normalize(direction), normal) +
                   pow(dot(normalize(direction), normal), 1.0 / spec_roll) *
                       spec_intensity);
}

vec3 point_light(vec3 light_pos, vec3 colour, vec3 pos, vec3 normal,
                 float spec_roll, float spec_intensity,
                 float shadow_intensity) {

  // Just called direct light, but have the direction be
  // the vector between the objects position and the lights position
  vec3 direction = normalize(light_pos - pos);
  vec3 light =
      direct_light(direction, colour, normal, spec_roll, spec_intensity);
  light *= get_shadow(light_pos, pos, .5 * direction, distance(light_pos, pos),
                      shadow_intensity);
  return max(vec3(0.), light);
}

void do_lighting(vec3 p, vec3 normal, inout vec3 colour) {

  float slow_lightup = 1.;

  if (time < SLOW_LU_END) {
    slow_lightup = max(smoothstep(SLOW_LU_START, SLOW_LU_END, time), 0.1);
  }
  // Overhead light
  colour +=
      point_light(vec3(0., 30., 10), vec3(0.15, 0.2, 0.3) * slow_lightup * 0.8,
                  p, normal, 1.0, 0.0, 0.5);

  // Moon light
  colour += point_light(vec3(-100., 80., -50), vec3(0.25, 0.3, 0.35), p, normal,
                        100.0, 1.0, 100.0);

  // door closing
  if (time <= DOOR_CLOSE_LEN) {

    float moveaway = smoothstep(1., DOOR_CLOSE_LEN, time) * 11.;
    colour +=
        point_light(vec3(0., 6., 15. + moveaway), vec3(0.5, 0.4, 0.01) * .7, p,
                    normal, 100.0, 1., 100000.0);
  } else {
    // Police
    colour += point_light(
        vec3(-20., 2. + sin(time - SLOW_LU_END) * 4., sin(time * 0.3) * 30.),
        vec3(max(0., sin(time * POLICE_LIGHTS_FREQ)), 0,
             max(cos(POLICE_LIGHTS_FREQ * time + HALF_PI), 0.)),
        p, normal, 100.0, 0.0, 10000.0);
  }
}

float ao(vec3 p, vec3 normal) {
  float occlusion = 0.0;
  for (float i = 1.; i <= AO_STEPS; i++) {
    // Distance to to look
    float dist = (i / AO_STEPS) * AO_AOI;
    // Direction and distance from the original point
    vec3 bounced = p + normal * dist;
    // Add up how far the bouncd point is from another object
    // But each time we get further away make it's influence
    // less and less
    float bounced_dist = scene_distance(bounced);
    occlusion += (AO_INTENSITY / i) * (dist - bounced_dist);
  }
  return clamp(1.0 - occlusion, 0.0, 1.0);
}

float fresnel(vec3 ray_direction, vec3 normal) {
  return 1.0 + (dot(ray_direction, normal));
}

void main(void) {

  Camera camera = Camera(vec3(0.0, 1.0, 11.0), // Position
                         vec3(0., -5.5, 0.),   // Look at
                         vec3(0.0, 1.0, 0.0),  // Up
                         1.3                   // FL
                         );

  // Get the 2d position
  vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;

  // Get the ray we're going to be using
  vec3 ray_direction = get_ray_direction(camera, uv);

  // Get the position and normal
  vec3 p = ray_march(camera.position, ray_direction);
  vec3 normal = get_normal(p);

  // Default colour to black
  vec3 colour = vec3(0.0);

  do_lighting(p, normal, colour);

#ifndef POTATO_QUALITY
  colour *= ao(p, normal);
  colour += vec3(0.05, 0.0, 0.01) * fresnel(ray_direction, normal);
  colour += (random(uv + time) * 2. - 1.) * .04;
#endif

  glFragColor = vec4(colour, 1.0);
}
