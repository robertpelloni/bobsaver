#version 420

// original https://www.shadertoy.com/view/Mt3XD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

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

float sdf_xz_plane(vec3 p, float y, float o)
{   

    float n = noise(p.xz) * 2.0;
    n += noise(p.xz * 4.) * 0.25;
    n += noise(p.xz * 8.) * 0.125;
    n += noise(p.xz * 16.) * 0.0625;
    return p.y - y - n;
}

vec2 trace(vec3 o, vec3 r){

    float d = 0.0;
    float t = 0.0;
    
    for(int i=0; i<32; i++){
        vec3 p = o + r * t;
        d = sdf_xz_plane(p, -1.25, 0.4);
        t += d * 0.5;

        if(d < 0.01 || t > 30.){
            break;
        }
    }

    return vec2(t, d);

}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
   
    uv = uv * 2.0 - 1.0;
    uv.x *= 1.5;
    
    vec3 r = normalize(vec3(uv, 1.0));

    vec3 o = vec3(0.0, 2.0, time);

    vec2 t = trace(o, r);

    float fog = 1.0 / t.x * 2.0;

    vec3 fc = vec3(fog);

    glFragColor = vec4(fc, 1.0);

}
