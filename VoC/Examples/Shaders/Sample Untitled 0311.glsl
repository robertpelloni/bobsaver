#version 420

/*~ iridule ~*/

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))

float map(vec3 p, float T) {
    float y = .3 + (.1 + .3 * sin(p.x + T) * cos(p.z * 2. - T)) * 
        sin(p.x * 10.) *
        sin(p.z * 10.);
    float a = dot(p + vec3(0., y, 0.), 
           vec3(0., 1., 0.)); // plane sdf
    return min(2. - a, a);
}

void main() {
    
    float T = time;
    float t = 0.;

    vec2 I = gl_FragCoord.xy;
    vec2 R = resolution;
    vec2 uv = (2. *I - R) / R.y;
    uv *= rot(T / 10.);
        
    vec3 ro = vec3(10. * sin(T / 5.), .9, T);
    vec3 rd = vec3(uv, 1.);
    
    for (int i = 0; i < 32; i++) {
        vec3 p = ro + rd * t;
        t += .3 * map(p, T);
    }
    vec3 p = ro + rd * t;    

    vec3 O = vec3(1. / t, 1. / (1. + t * t * .5), 1. - sin(p.x * 10.) * sin(p.z * 10.));
    O *= abs(uv.y); // psuedo darkness
    glFragColor = vec4(O, 1.);

}
