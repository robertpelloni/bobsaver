#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 uv) {
    return fract(45656.65 * sin(dot(uv, vec2(45.45, 786.4))));
}

float map(vec2 uv) {
    vec2 i = floor(uv);
    uv = 2.* fract(uv) - 1.;
    float r = float(mod(i.x + i.y, 2.) == 0.);
    float d = max(abs(uv.x), abs(uv.y));
    return r == 0. ? d : 1. - d;
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 col = vec3(0.);
    
    //uv.y += time / 100.;
    uv *= 5.;
    float m = map(uv);
    
    vec2 o = vec2(.01, 0.);
    vec3 n = normalize(vec3(m - map(uv + o.xy),
                m - map(uv + o.yx), -o.x));
    
    vec3 l = normalize(vec3(cos(time * 1.2), 1. + sin(time * .5), -1.1));
    vec3 v = normalize(vec3(uv, 1.0));
    
    float diff = max(dot(n, l), 0.);
    float spec = pow(max(dot(n, normalize(l-v)), 0.), 8.);
    

    col += vec3(1., .5, 0.) * m * .5;
    col += vec3(1., .1, .0) * diff * .5;
    col += vec3(1., 1., 0.) * spec * .5;
    

    glFragColor = vec4(col, 1.);
}
