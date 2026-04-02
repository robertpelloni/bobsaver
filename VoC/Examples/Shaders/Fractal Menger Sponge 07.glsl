#version 420

// original https://www.shadertoy.com/view/4dsfzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float basic_box(vec3 pos, vec3 b){
    vec3 d = abs(pos) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float map_menger5(vec3 p){

    float main_width_b = 3.0;    // ok
    float inf = 50.0;            // ok

    float hole_x, hole_y, hole_z;              // ok
    float offset_x, offset_y, offset_z;         // ok

    float hole_width_b = main_width_b / 3.0; // correct
    
    float menger = basic_box(p, vec3(main_width_b)); // ok
    
    for (int iter=0; iter<4; iter++){                   // ok

        float hole_dist = hole_width_b * 2.0 * 3.0;  // correct
 
        vec3 c = vec3(hole_dist);
        vec3 q = mod(p + vec3(hole_width_b), c) - vec3(hole_width_b);

        hole_x = basic_box(q, vec3(inf, hole_width_b, hole_width_b));
        hole_y = basic_box(q, vec3(hole_width_b, inf, hole_width_b));
        hole_z = basic_box(q, vec3(hole_width_b, hole_width_b, inf));

        hole_width_b = hole_width_b / 3.0;        // reduce hole size for next iter
        menger = max(max(max(menger, -hole_x), -hole_y), -hole_z); // subtract

    }

    return menger;

}

float trace(vec3 origin, vec3 ray){
    
    float t = 0.0;
    for (int i=0; i<32; ++i){
        vec3 p = origin + ray * t;
        float d = map_menger5(p);
        t += d*0.5;
    }
    return t;
}

mat2 rotate(float theta){
    return mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
}

void main(void) {

    // normalize coords
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    // convert coords from 0,1 to -1,1
    uv = uv * 2.0 - 1.0;
    
    // fix aspect
    uv.x *= resolution.x/resolution.y;
    
    vec3 ray = normalize(vec3(uv.x, uv.y, 1.0));
    vec3 origin = vec3(0.0,0.0,-1.0);

    float theta;
    theta = time / 2.0;
    theta -= 5.0 *resolution.xy.x/resolution.x;
    ray.yz *= rotate(theta);
    ray.xy *= rotate(theta);
    origin.yz *= rotate(theta);
    origin.xy *= rotate(theta);
    
    float t = trace(origin, ray);
    
    float fog = 1.0 / (1.0 + t * t * 0.1);
    float intensity = 1.0/(t*t);
    vec3 fc = vec3(fog);
    
    glFragColor = vec4(fc,1.0);
}
