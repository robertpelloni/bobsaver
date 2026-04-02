#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Voronoi / Voronoi FBM
*/
float hash21(vec2 uv) {
    return fract(78458.85 * sin(dot(uv, vec2(45.5, 98.8))));
}

vec2 hash22(vec2 uv) {
    float k = hash21(uv);
    return vec2(k, hash21(uv + k));
}

float voronoi(vec2 uv) {
    float minDist = 1000.;
        vec2 k = floor(uv);
        vec2 f = fract(uv) - .5;
        // a wider loop gets rid of edges
        for (float i = -2.; i < 2.; i++) {
            for (float j = -2.; j < 2.; j++) {
                    vec2 o = vec2(i, j);
                vec2 n = hash22(k + o);
                    vec2 p = o + n;
                    float d = length(f - p);
                    if (d < minDist) minDist = d;        
            }
        }
    return minDist;
}
 
float voronoiFbm(vec2 uv) {
    float v = voronoi(uv);
        v += voronoi(uv * 2.) * .5;
        v += voronoi(uv * 4.) * .25;
        v += voronoi(uv * 8.) * .125;
        return v / (1.6375);
}

void main() {
    vec2 uv = 5. * (2. * gl_FragCoord.xy - resolution) / resolution.y;
    glFragColor = vec4(vec3(voronoiFbm(uv + voronoiFbm(uv + time / 10.)), 0., 0.), 1.);
}
