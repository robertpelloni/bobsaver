#version 420

// original https://www.shadertoy.com/view/4dcfRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_OCTAVES 6

vec3 rnd33( vec3 p ) {
    vec3 q = vec3( dot(p,vec3(127.1,311.7, 109.2)),
                   dot(p,vec3(269.5,183.3, 432.6)),
                   dot(p,vec3(419.2,371.9, 304.4)) );
    return fract(sin(q)*43758.5453);
}

float rnd13( vec3 p ) {
    return fract(43758.5453*sin(dot(p,vec3(127.1,311.7, 109.2))));
}

float worley3D(vec3 u) {
    float d = 1e4, a;
    float acc = 0., acc_w = 0.;
    vec3 k =  floor(u), f = u-k, p, q = k;
    const int r = 3;
    for(int i = -r; i < r; i++) {
        for(int j = -r; j < r; j++) {
            for(int l = -r; l < r; l++) {
                vec3 p_i = vec3(i, j, l),
                     p_f = rnd33(k+p_i);
                float d = length(p_i - f + p_f);
                float w = exp(-8. * d) * (1.-step(sqrt(float(r*r)),d));
                acc += w * rnd13(k+p_i);
                acc_w += w;
        } } }
    return acc / acc_w;
}

float fbm3D(vec3 u) {
    float v = 0.;
    for(int i = 0; i < NUM_OCTAVES; i++) {
        v += pow(.5, float(i+1)) * worley3D(u);
        u = 2. * u + 1e3;
    }
    return v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 p = uv * 3.;
    vec3 col = vec3(0.);
    float t = time/3.;
    float f;
    #if 0
        col += fbm3D( vec3(p, time/3.) );
    #elif 0
        col += fbm3D( vec3(p, t) + 
                   vec3( fbm3D(vec3(p, t)+1e3),
                            fbm3D(vec3(p, t)-1e3),
                         fbm3D(vec3(p, -t))
                       )
                   );
    #elif 1
        col = vec3( fbm3D(vec3(p, t)+1e3),
                    fbm3D(vec3(p, t)-1e3),
                    fbm3D(vec3(p, -t))
                   );
    #endif
            
    glFragColor = vec4(col,1.0);
}
