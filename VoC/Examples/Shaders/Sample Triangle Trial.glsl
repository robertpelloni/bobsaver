#version 420

// original https://www.shadertoy.com/view/3lfSzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415

float triangle(vec2 r, vec2 center, float a) {
    float ret = 1.;
    float d = 0.005;
    float x = r.x - center.x;
    float y = r.y - center.y;
    
    float v1 = (sqrt(3.)*x - y + sqrt(3.)*a/3.)/2.;
    float v2 = (-sqrt(3.)*x - y + sqrt(3.)*a/3.)/2.;
    float v3 = y + sqrt(3.)*a/6.;
    
    ret *= smoothstep(-d, d, v1);
    ret *= smoothstep(-d, d, v2);
    ret *= smoothstep(-d, d, v3);
    
    return ret;
}

float interval(vec2 r, float T) {
    float x = mod(r.x, T);
    float half_T = T/2.;
    float d = 0.005;
    float ret = 0.0;
    if (x < d) {
       ret = smoothstep(-d, d, x); 
    } else if (d <= x && x <= half_T-d) {
        ret = 1.0;
    } else if (half_T-d < x && x < half_T+d) {
        ret = 1.0 - smoothstep(-d, d, x-half_T);
    } else if (half_T+d <= x && x <= T-d) {
        ret = 0.0;
    } else if (T-d < x) {
         ret = smoothstep(-d, d, x-T);
    }
    return ret;
}

mat2 rotate(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

mat2 scale(float s) {
    return mat2(s, 0.0, 0.0, s);
}

void main(void)
{
    // position
    vec2 r = (gl_FragCoord.xy - 0.5*resolution.xy)/ resolution.y;

    // color
    float t = time;
    float theta = t;
    float s = sin(t);
    vec2 r1 = r;
    r1 *= scale(s);
    r1 *= rotate(theta);
    float val = triangle(r1, vec2(0., 0.), 0.7);
    vec2 r2 = r;
    r2 *= rotate(-theta/2.);
    val *= interval(r2, 0.1); 
    vec3 col = vec3(clamp(val, 0.1, 0.9));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
