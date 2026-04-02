#version 420

// original https://www.shadertoy.com/view/XlfcRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hex frequency
#define N 16.0

// Constants
#define pi 3.14159265358979323846
#define sin_60 0.8660254037844386
#define rot_90 mat2(0.0, -1.0, 1.0, 0.0)

// Hex directions
#define hv_1 vec2(1.0, 0.0)
#define hv_2 vec2(0.5, -sin_60)
#define hv_3 vec2(0.5,  sin_60)

// Mod directions 90 degrees to Hex directions
#define mv_1 vec2(0.0, 1.0)
#define mv_2 vec2(-sin_60, -0.5)
#define mv_3 vec2( sin_60, -0.5)

float d_hexagon(vec2 uv, float a){
    return length(uv - hv_1*clamp( dot(uv, hv_1), -a, a) 
                     - hv_2*clamp( dot(uv, hv_2), -a, a) 
                     - hv_3*clamp( dot(uv, hv_3), -a, a) );
}

void main(void) {
    
    vec2 uv = 2.0*(gl_FragCoord.xy / resolution.xy) - 1.0;
    uv.x *= resolution.x/resolution.y;    
    
    // Global scaling and rotation transformation
    float p_time = clamp(1.0 - 2.3*sin(time/3.0), 0.0, 4.0);
    float scale_f = abs( N / (p_time + dot(uv,uv)) );
    uv *= scale_f; // scale_f = 5.0; // Try scale_f = 5.0;
    float ct = cos(0.2*p_time); float st = sin(0.2*p_time);
    uv *= mat2(ct, -st, st, ct);
      
    // Modding for repeated hexagons
    uv = + mv_1 * mod(dot(uv, mv_1), 2.0)
         + mv_2 * mod(dot(uv, mv_2), 2.0) 
         + mv_3 * mod(dot(uv, mv_3), 2.0);
    
    //uv*= rot_90; // uncomment to get stars
    float size = 0.5 + 0.0025*sin(15.0*time);
    float dist = d_hexagon(uv, size);

    // Final out
    glFragColor = 2.0*vec4(dist, 0.5, 0,1) * sin(3.0*dist);
    glFragColor *= clamp(N/scale_f,0.0,1.0);  // Supress aliased regions
}
