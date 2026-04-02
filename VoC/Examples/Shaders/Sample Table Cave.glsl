#version 420

// original https://www.shadertoy.com/view/wljXRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 genRot(float val){
    return mat2(cos(val),-sin(val),sin(val),cos(val));
}
float map(vec3 p){
    float time = 1.;
    float h =3. + (sin(p.x + time) + sin(p.z + time)) * 0.4;
    h += 0.8 * (sin(time)*sin(p.x/4.)*cos(p.z/0.5));
    h -= sin(time * 0.3) * sin(p.x / 2.);
    h -= cos(time * 0.75) * cos(p.z / 2.);
    h -= sin(time * 0.5) * sin(p.x + p.z);
    h += 0.8 * (cos(time)*sin(p.z/4.)*cos(p.x));
    return abs(p.y) - floor(h * 2.) / 2.;
    

}

float trace (vec3 o, vec3 r){
    float t = 0.0;
    for(int i = 0; i < 96; ++i){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.25;
    }
    return t;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    float PI = 3.14159265;
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,1.0));
    vec3 o = vec3(6.0 * sin(time / 2.),0,-2.0 - time * 2.0);
    float t = trace(o,r);
    float fog = 1.0 / (1.0 + t * t * 0.0025);
    vec3 a = r.y > 0. ? vec3(0.6,0.3,0.3) : vec3(0.3,0.3,0.6);
    vec3 fc = mix(vec3(1.),a,fog);

    // Output to screen
    glFragColor = vec4(fc,1.0);
}
