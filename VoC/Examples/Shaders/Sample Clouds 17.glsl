#version 420

// original https://www.shadertoy.com/view/4slcz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// author: Juan Francisco
// title: Clouds

#define NUM_OCTAVES 10

float random (in vec2 _st) { 
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233))) * 
        43758.5453123);
}

float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + 
            (c - a)* u.y * (1.0 - u.x) + 
            (d - b) * u.x * u.y;
}

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2( cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    //mat2 rot = mat2( 0, 3. * sin(0.5), 0, cos(0.50));
    
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    
    return v;
}

vec3 grayscale(in vec3 _rgb) {
    vec3 base = vec3(0.2989, 0.587, 0.114);
    float lum = base.r * _rgb.r + base.g * _rgb.g + base.b * _rgb.b;
    return vec3(lum);
}

void main(void) {
    
    vec2 st = gl_FragCoord.xy/ resolution.xy * 5. + time / 25.;
    vec3 color = vec3(0);

    vec2 q = vec2(0.);
    q.x = fbm( st + 0.00*time);
    q.y = fbm( st + vec2(1.0));
    
    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ 0.15*time );
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*time);

    float f = fbm( st + fbm(st + fbm(st)));

    color = mix(vec3(0.198,0.629,0.667),
                vec3(0.666667,0.666667,0.498039),
                clamp((f*f)*4.0,0.0,1.0));

    color = mix(color,
                vec3(0,0,0.164706),
                clamp(length(q),0.0,1.0));

    color = mix(color,
                vec3(0.666667,1,1),
                clamp(length(r.x),0.0,1.0));
    
    float x = .5 + fbm(st);
    float nt = noise(vec2(time * .013, time * .013));
    float v1 = pow(length(r), 2.5 + 1.5 * (1. - nt));
    float v2 = 1.;
    float alpha = mix(v2, v1, nt);
    
    vec3 colorv = 1. * color + f*f*f*color*color;
    vec3 tint = vec3(0.682,0.933,1.000);
    
    glFragColor = vec4(tint * grayscale(colorv),alpha);
}
