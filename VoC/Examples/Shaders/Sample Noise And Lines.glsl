#version 420

// original https://www.shadertoy.com/view/Xt3yzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float hash(vec2 uv){
    return fract(12345. * sin(dot(uv, vec2(12.34, 56.78))));
}

float noise(vec2 uv){
    vec2 f = fract(uv);
    f = f * f * (3. - 2. * f);
    vec2 p = floor(uv);
    float res = mix(mix(hash(p), hash(p + vec2(1., 0.)), f.x),
                    mix(hash(p + vec2(0., 1.)), hash(p + vec2(1., 1.)), f.x),
                    f.y);
    return res;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    
    float k = 2.;
    vec2 uvNoise = rot(k + 0.00001 * time) * uv * 10. + 0.2 * time;
    float res = 0.;
       float c = 0.5;
    
    for(int i = 0; i < 10; i++){
        res += c * noise(uvNoise);
        c /= 2.;
        uvNoise = rot(k + 0.00001 * time) * k * uvNoise + k + time;
    }
    //res -= 0.5;
    uv = rot(1.5 * noise(uv * 5. + 0.1 * time)) * uv;
    float line = smoothstep(0., 1., abs(sin(70. * uv.x) + res));
    line = smoothstep(0., 1., line);

    vec3 col = vec3(line);
    //vec3 col = vec3(res);

    glFragColor = vec4(col,1.0);
}
