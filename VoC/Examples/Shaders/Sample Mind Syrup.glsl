#version 420

// original https://www.shadertoy.com/view/4sVBzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 translate(vec2 v) {
    return mat3(
        1., 0., 0.,
        0., 1., 0,
        -v.x, -v.y, 1.
    );
}

mat3 rotate(float a) {
    return mat3(
        cos(a), sin(a), .0,
        -sin(a), cos(a), 0.,
        0., 0., 1.
    );    
}

float sinp(float a) { return 0.5 + 0.5 * sin(a); }

void main(void)
{
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    vec2 resolution = resolution.xy;
    float time = time;
 
    vec3 st = vec3(gl_FragCoord.xy / resolution, 1.0);
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    st.xy *= 2.0;
    st.xy -= 1.0;
    st.xy *= aspect;
    
    mouse *= 2.0;
    mouse -= 1.0;
    
    // some transforms
    st = translate(mouse) * st;
    st = rotate(
        time + sin(time + length(st) * 3. * mouse.x)
    ) * st;
    
    
    // iterating through each channel
    vec3 col;
        
    // track time
    float t = time;
    for (int i = 0; i < 3; i++) {
        
        // offset time for each channel based on mouse input
        t += (sin(time + (2. + 10. * mouse.x) * length(st) + atan(st.y, st.x) * 5.)
             * sin(time + (2. + 10. * mouse.y) * length(st) - atan(st.y, st.x) * 5.)
             );
        
        // collate channels
        float c = sin(5. * t - length(st.xy) * 100. * sinp(t));
        col[i] = c;
    }
    
    
    
    glFragColor = vec4(vec3(1., mouse.x, col.g) * col, 1.0);
    
}
