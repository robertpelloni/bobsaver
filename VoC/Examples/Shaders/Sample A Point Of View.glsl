#version 420

// original https://www.shadertoy.com/view/tdjyDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITEMS_HALF 3.0
#define PI 3.14159265359
#define TWO_PI 6.28318530718

vec3 rotate_3d(vec3 item, vec3 rotation) {
    vec2 x = vec2(cos(rotation.x), sin(rotation.x));
    vec2 y = vec2(cos(rotation.y), sin(rotation.y));
    vec2 z = vec2(cos(rotation.z), sin(rotation.z));

    return item *= mat3(
        1., 0., 0.,
        0., x.x, -x.y,
        0., x.y, x.x
    ) * mat3(
        y.x, 0., y.y,
        0., 1., 0.,
        -y.y, 0., y.x
    ) * mat3(
        z.x, -z.y, 0.,
        z.y, z.x, 0.,
        0., 0., 1.
    );
}

vec3 get_intersection_point(
    vec2 st,
    vec3 origin, 
    vec3 look_at, 
    float zoom
) {
    vec3 forward = normalize(look_at - origin);
    vec3 right = cross(forward, vec3(0., 1., 0.));
    vec3 up = cross(forward, right);

    vec3 center = origin + forward * zoom;

    return center + right * st.x + up * st.y;
}

float get_point_distance(vec3 point, vec3 origin, vec3 direction) {
    return length(cross(point - origin, direction)) / length(direction);
}

float animate(float from, float to, float current_step) {
    return sin(smoothstep(from, to, current_step) * PI * 0.5);
}

float get_point_color(
    vec3 point, 
    vec3 origin, 
    vec3 direction,
    float animation_step
) {
    float distance = get_point_distance(point, origin, direction);

    return 
        smoothstep(0.2, 0.05, distance) * (
            1.2 -
            animate(0., 0.5, animation_step) + 
            animate(0.6, 1.0, animation_step)
        ) +
        smoothstep(0.1, 0.07, distance);
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;

    float animation_step = fract(time * 0.2);

    vec3 rotation = vec3(
        0.0, 
        animate(0.3, 0.6, animation_step) * PI * 0.5,
        animate(0.6, 1.1, animation_step) * PI * 0.5
    );

    st -= vec2(0.5);
    st.x *= resolution.x / resolution.y;

    vec3 look_at = vec3(0.0);
    vec3 ray_origin = rotate_3d(
        vec3(0.0, 0.0, -0.1 + animate(0.0, 0.33, animation_step) * -4.0),
        rotation
    );
    vec3 intersection = get_intersection_point(
        st,
        ray_origin,
        look_at,
        1.0
    );
    vec3 ray_direction = intersection - ray_origin;

    float color = 0.0;

    color += length(st) * 0.5;

    for (float i = -MAX_ITEMS_HALF; i <= MAX_ITEMS_HALF; i += 1.0) {
        for (float j = -MAX_ITEMS_HALF; j <= MAX_ITEMS_HALF; j += 1.0) {
            for (float k = -MAX_ITEMS_HALF; k <= MAX_ITEMS_HALF; k += 1.0) {
                color += get_point_color(
                    vec3(i, j, k),
                    ray_origin, 
                    ray_direction,
                    animation_step
                );        
            }
        }
    }

    st += vec2(0.5);

    glFragColor = vec4(
        vec3(color * st.y, color * st.x, color),
        1.0
    );
}
