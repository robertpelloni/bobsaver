#version 420

// original https://www.shadertoy.com/view/MsjczV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415928
void main(void)
{
    vec2 d = resolution.xy * vec2(0.5);
    
    float s = sin(mod(time, 2.0 * PI));
    float c = cos(mod(time, 2.0 * PI));
    vec2 p = mouse*resolution.xy.xy - d;
    
    if(mouse*resolution.xy.xy == vec2(0.0,0.0)) {
        p = vec2(0.0,0.0);
    }
    
    mat3 transform = mat3(  c, -s,0.0,
                            s,  c,0.0,
                          0.0,0.0,1.0);
    
    vec2 uv = (transform * vec3(gl_FragCoord.xy - d - p, 1.0)).xy + d;
    
    uv = uv / resolution.y;
    
    vec3 out_color = vec3(1.0,0.0,0.0);
    
    vec2 hapy_face_position = vec2(0.9,0.5);
    float hapy_face_radius = 0.35;
    vec2 hapy_face_left_eye_position = vec2(0.75,0.55);
    float hapy_face_eye_radius = 0.05;
    vec2 hapy_face_right_eye_position = vec2(1.05,0.55);
    
    vec2 hapy_face_mouth_position = vec2(0.90,0.40);
    float hapy_face_mouth_size = 0.15;
    
    out_color += vec3(1.0,1.0,0.0) * smoothstep(hapy_face_radius + 0.005, hapy_face_radius, length(hapy_face_position - uv));
       
    out_color -= vec3(2.0,1.0,0.0) * smoothstep(hapy_face_eye_radius + 0.005, hapy_face_eye_radius, length(hapy_face_left_eye_position - uv));
    
    out_color -= vec3(2.0,1.0,0.0) * smoothstep(hapy_face_eye_radius + 0.005, hapy_face_eye_radius, length(hapy_face_right_eye_position - uv));
    
    float mouth_x  = 0.45;
    float mouth_y  = 0.25;
    
    vec2 uv2 = uv - hapy_face_mouth_position;
    float mouth_test_a = (uv2.x*uv2.x)/(mouth_x*mouth_x) + (uv2.y*uv2.y)/(mouth_y*mouth_y);
    
    vec2 uv3 = uv - hapy_face_mouth_position + vec2(0.0,-0.02);
    float mouth_test_b = (uv3.x*uv3.x)/(mouth_x*mouth_x) + (uv3.y*uv3.y)/(mouth_y*mouth_y);
    
    out_color -= vec3(2.0,1.0,0.0) * smoothstep(hapy_face_mouth_size + 0.005, hapy_face_mouth_size, mouth_test_a);
    out_color += vec3(1.0,1.0,0.0) * smoothstep(hapy_face_mouth_size + 0.005, hapy_face_mouth_size, mouth_test_b);
    
    glFragColor = vec4(out_color, 1.0);
}
