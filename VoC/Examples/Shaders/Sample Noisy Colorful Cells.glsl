#version 420

// original https://www.shadertoy.com/view/WljczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec2 effect(vec2 p) {
    float ang = time * 0.1;
    mat2x2 rot = mat2x2(cos(ang), -sin(ang), sin(ang), cos(ang));
    
    p *= rot;
    
    return p;
}

vec3 noise_map(vec2 p) {
    vec2 cell = floor(p);
    vec2 point = fract(p);
    
    float min_dist = 1.;
    
    for (int x= -1; x <= 1; x++) {
        for (int y= -1; y <= 1; y++) {
            vec2 new_cell = vec2(x, y);
            vec2 new_point = random2(new_cell + cell);
            
            new_point = sin(new_point * sin(time * .4) * 5. + time) * .5 + .5;
            
            float dist = length(new_cell + new_point - point);
            
            min_dist = min(min_dist, dist);
        }
    }
    
    vec3 color = vec3(min_dist);
    color *= color;
    
    return color;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float screen_ratio = resolution.x / resolution.y;
    //uv = fract(uv * 3.);
    uv -= sin(time * .3) * .1 + .5;
    uv.x *= screen_ratio;
    vec3 color;
    
    uv *= 20.;
    
    uv = effect(uv);
    
    float offset_noise_x = noise_map(uv).x;    
    float offset_noise_y = noise_map(uv + vec2(1., 1.)).x;
    float offset_noise_z = noise_map(uv + vec2(2., 2.)).x;
    
    uv += (vec2(offset_noise_x) - .5) * .1;
    color += vec3(offset_noise_x, offset_noise_y, offset_noise_z);
    
    glFragColor = vec4(color, 1.0);
}
