#version 420

// original https://www.shadertoy.com/view/XsdSDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ball radius
#define R 0.07

float map(vec3 p, bool tangent_distance) {
    // This makes everything below repeat infinitely.
    p = mod(p, 0.2) - vec3(0.1);

    // Distance to center of ball, squared.
    float l2 = dot(p, p);
            
    // Fall back on a regular distance map.
    return (length(p)*3.0  - R + length(p + vec3(0, -0.04,0)) - R) /4.0;
}

// Cast a ray starting at "from" and keep going until we hit something or
// run out of iterations.
float ray(vec3 from, vec3 direction) {
    // How far we travelled (so far)
    float travel_distance = 0.0;
    float last_travel_distance = 0.0;
    bool hit = false;
    for (int i = 0; i < 80; i++) {
        // calculate the current position along the ray
        vec3 position = from + direction * travel_distance;
        float distance_to_closest_object = map(position, !hit);

        if (distance_to_closest_object < 0.0001) {
            if (distance_to_closest_object < 0.0) {
                // We are inside of an object. Go back to the
                // previous position and stop using tangent distances
                // so that we can find the surface.
                hit = true;
                  travel_distance = last_travel_distance;
                   continue;
            }
            return travel_distance;
        }
        last_travel_distance = travel_distance;
        
        // We can safely advance this far since we know that the closest
        // object is this far away. (But possibly in a completely different
        // direction.)
        travel_distance += distance_to_closest_object;
    }
    // We hit something, but then we ran out of iterations while
    // finding the surface.
    if (hit) return travel_distance;
    // We walked 50 steps without hitting anything.
    return 0.0;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.xx;

    vec3 camera_position = vec3(0, 0, -1);

    // Animate
    camera_position.z += time/2.0;
    camera_position.x += time/7.0;
    
    // Note that ray_direction needs to be normalized.
    // The "1" here controls the field of view.
    float zoom = 1.0;
    
    // Uncomment this for a very funky zoom effect.
    // float zoom = sin(time / 5.0) + 0.4;
    vec3 ray_direction = normalize(vec3(uv, zoom));

    // Direction of the sun.
    vec3 sun_direction = normalize(vec3(0.2, 1, -1));
        
    // Cast a ray, see if we hit anything.
    float travel_distance = ray(camera_position, ray_direction);
    
    // If we didn't hit anything, go with black.
    if (travel_distance == 0.0) {
        glFragColor = vec4(0);
        return;
    }

    // Point in space where our ray intersects something.
    vec3 hit_position = camera_position + ray_direction * travel_distance;

    // Distance from surface.
    float surface_dist = map(hit_position, false);
    
    // How far we step towards the sun.
    float sun_ray_step_length = 0.005;
    
    // Take a small step in the direction of the light source and measure how
    // far we are from the surface. The further away we got, the brighter this
    // spot should be.
    float surface_dist_nearer_sun = map(hit_position + sun_direction * sun_ray_step_length, false);
    
    // Calculate how much sunlight is falling on this spot (hit_position).
    float sunlight = max(0.0, (surface_dist_nearer_sun - surface_dist) / sun_ray_step_length);

    // Reduce the sunlight with distance to make it fade out far away.
    sunlight /= (1.0 + travel_distance * travel_distance * 0.2);
    
    // Alternate blue and orange balls using magic.
    float n = dot(vec3(1.0), floor(hit_position * 5.0));
    if (mod(n, 2.0) == 0.0) {    
        // Blue palette.
        glFragColor = vec4(sunlight * 1.5, sunlight * 1.5, sunlight * 1.5, 1.0);
    } else {
        // Fire palette.
        glFragColor = vec4(sunlight * 1.5, pow(sunlight, 2.5), pow(sunlight, 12.), 1.0);
    }    
}

