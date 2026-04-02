#version 420

// original https://www.shadertoy.com/view/XltfRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author @patriciogv - 2015
// http://patriciogonzalezvivo.com

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
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

#define NUM_OCTAVES 5

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec2 rotateUV(vec2 uv, float rotation, vec2 mid)
{
    return vec2(
      cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x,
      cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y
    );
}

void main(void)
{
    // Coords
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec3 color = vec3(0.0);
    st.x *= resolution.x/resolution.y;

    // Center Coords
    st.x -= resolution.x/resolution.y * .5;
    st.y -= .51;
    st *= 20.;
    
    // Time
    float time = time*2.;
    
    // Fisheye
    float dst = 1.-distance(st,vec2(0));
    float strength = (-abs(sin(time)*10.))*2.-15.;
    st = mix(st, st*2., dst/strength);
    
    st.xy *= 1. + sin(dst)/15.;
    
    // Rotation
    st = rotateUV(st, time/10., vec2(0));
    
    st += fbm(st + time)/2.;
    
    st *= sin(fbm(st));
    float base = fbm(vec2(0., .98345) + st);

    
        
    color = vec3(base);
    color = color / vec3(.1, .9, .5);
    
    float c = sin(dst)/5. + .1;
    color -= c;
    
    glFragColor = vec4(color,0);

    /*vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ 0.15*time );
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*time);

    float f = fbm(st+r);

    color = mix(vec3(0.101961,0.619608,0.666667),
                vec3(0.666667,0.666667,0.498039),
                clamp((f*f)*4.0,0.0,1.0));

    color = mix(color,
                vec3(0,0,0.164706),
                clamp(length(q),0.0,1.0));

    color = mix(color,
                vec3(0.666667,1,1),
                clamp(length(r.x),0.0,1.0));

    glFragColor = vec4((f*f*f+.6*f*f+.5*f)*color,1.);*/
}
