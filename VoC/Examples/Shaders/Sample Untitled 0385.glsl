#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592

mat4 project(float fov, float near, float far) {
    float S = 1.0 / tan(fov / 2.0 * PI / 180.0);
    float z = -far / (far - near);
    float w = -far * near / (far - near);
                
    return mat4( 
          S, 0.0, 0.0, 0.0,
        0.0,   S, 0.0, 0.0,
        0.0, 0.0,   z,-1.0,
        0.0, 0.0,   w, 0.0
    );
}

mat4 rotate(float x, float y, float z) {
                
    return mat4( 
         cos(y),    0.0,-sin(y), 0.0,
            0.0,    1.0,    0.0, 0.0,
         sin(y),    0.0, cos(y), 0.0,
            0.0,    0.0,    0.0, 1.0
    ) * mat4( 
            1.0,    0.0,    0.0, 0.0,
            0.0, cos(x), sin(x), 0.0,
            0.0,-sin(x), cos(x), 0.0,
            0.0,    0.0,    0.0, 1.0
    ) * mat4( 
         cos(z), sin(z),    0.0, 0.0,
        -sin(z), cos(z),    0.0, 0.0,
            0.0,    0.0,    1.0, 0.0,
            0.0,    0.0,    0.0, 1.0
    );
}

mat4 translate(float x, float y, float z) {        
    return mat4( 
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
          x,   y,   z, 1.0
    );
}

vec3 cube(float i, float res) {
    float x = mod(i, res);    
    float y = mod(floor(i / res), res);
    float z = mod(floor(i / res / res), res);
    return (vec3(x, y, z) / (res - 1.0) - 0.5);
}

vec3 sphere(float i, float res) {
    res = res * res * res;
    
    vec3 point =  vec3(cos(i / 8.0 * PI), fract(i / 100.0) - 0.5, sin(i / 8.0 * PI));
    
    float w_scale = cos(point.y * PI) / 2.0;
    point.xz *= w_scale;
    
    return point;
}

void main( void ) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (uv - 0.5) * resolution.xy / resolution.xx;
        mat4 proj_mat = project(60.0, 0.01, 5.0);
    
    vec3 color = vec3(0.0);
    
    const int res = 5;
    for (int i = 0; i < res * res * res; i++) {    
        
        vec3 point = mix(
            cube(float(i), float(res)),
            sphere(float(i), float(res)),
            sin(time / 8.0 * PI) * 0.5 + 0.5
        );
        vec4 projected = vec4(point / 10.0, 1.0);
        
        projected *= rotate(
            1.0 * fract(time / 20.0) * 2.0 * PI, 
            1.0 * fract(time / 10.0) * 2.0 * PI, 
            1.0 * fract(time / 30.0) * 2.0 * PI
        );
        projected *= translate(0.0, 0.0, .50);
        
        projected *= proj_mat;
        projected.xyz /= projected.z;
        color += (abs(point) + 0.1) * smoothstep(0.000, 0.002, 0.003 - distance(projected.xy, p*0.5));
            
    }

    glFragColor = vec4( vec3(color*2.0) , 1.0 );

}
