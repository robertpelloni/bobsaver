#version 420

// original https://www.shadertoy.com/view/WllXzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float tau = 6.283185307179586476925286766559;
const vec3 background_color = vec3(1.0);
const vec3 central_disc_color = vec3(1.0, 0.66, 0.33);
const vec3 external_disc_color = vec3(0.0);

float disc(vec2 uv, vec2 center, float radius)
{
    vec2 delta = (uv-center)/radius;
    float sqDistance = dot(delta, delta);
    return smoothstep(1.01, 0.99, (sqDistance));
}

void blob(
    inout vec3 glFragColor,
    in vec2 uv,
    in vec2 center,
    in float radius,
    in vec3 color,
    in int e_count,
    in float e_big_radius,
    in float e_small_radius,
    in vec3 e_color)
{
    glFragColor = mix(glFragColor, color, disc( uv, center, radius));
    for (int i = 0; i < e_count; ++i)
    {
        float angle = tau * float(i) / float(e_count);
        vec2 e_center = center + e_big_radius * vec2( cos(angle), sin(angle) );
        glFragColor = mix(glFragColor, e_color, disc( uv, e_center, e_small_radius ));
    }
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.yy;

    vec3 col = background_color;
    
    vec3 e_color = mix( background_color, external_disc_color, clamp(cos(time)+0.5, 0., 1.) );
    
    blob(col, uv, vec2(-0.4,0), 0.1, central_disc_color, 6, 0.31, 0.14, e_color);
    blob(col, uv, vec2( 0.4,0), 0.1, central_disc_color, 8, 0.16, 0.045, e_color);
    
    glFragColor = vec4(col,1.0);
}
