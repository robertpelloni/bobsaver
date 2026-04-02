#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define tau 6.28

vec3 shape(vec2 st) {
    vec3 c;
    float t = time, f = 1.;
    for (int i = 0; i < 3; i++) 
        c[i] = (f / 3.) / abs(st.x * 8. + 
              sin(0. * length(st) + st.y * f * .2 + (t += 6.)) * cos((t += 0.0001) + st.y / 2. * tau * (f += .2 * float(i))));    
    return c;
}

vec3 shape2(vec2 st) {
    vec3 c;
    float t = time, f = 5.;
    for (int i = 0; i < 3; i++) 
        c[i] = (.05) / abs(sin((t += .1) + 2. * length(st)));
    return c;
}

void main( void ) {
    
    vec2 R  = resolution;
    vec2 uv = (2. * gl_FragCoord.xy- R);
    const float STEP = 8.;
    vec3 c = vec3(0.);
    for (float i = .2; i < 1.; i += 1. / STEP) {
        c += shape(uv * i * 5.);
    }
    c /= STEP;
        
    vec3 r = shape2(uv);
    
    glFragColor = vec4(r + c, 78.);

}
