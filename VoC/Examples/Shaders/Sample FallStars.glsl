#version 420

// original https://neort.io/art/c1td54s3p9f8fetn1gkg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.0);
float pi2 = pi * 2.0;

vec3 hsv2rgb(float h, float s, float v){
    vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return v * mix(vec3(1.0), rgb, s);
}

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 random2dPolar(float n){
    float x = fract(sin(n*546.25)*222.223)*pi2;
    float y = (fract(sin(n*222.25)*622.223) - 0.5)*5.0;

    return vec2(cos(x), sin(x))*y;
}

vec2 random2d(float n){
    float x = (fract(sin(n*246.25)*422.223) - 0.5)*2.0;
    float y = (fract(sin(n*522.25)*722.223) - 0.5)*2.0;

    return vec2(x, y);
}

float random1d(float n){
    float x = fract(sin(n*246.25)*422.223);

    return x;
}

float starSDF(vec2 uv, float s){
    float a = atan(uv.y, uv.x) / pi2;
    float seg = a * 5.0;
    a = ((floor(seg)+0.5)/5.0 + mix(s, -s, step(0.5, fract(seg)))) * pi2;
    return abs(dot(vec2(cos(a), sin(a)), uv));
}

float explode(vec2 pos, float t, float coef){
    float c = 0.0;

    for(float i = 0.0; i <= 10.0; i+=1.0){
        vec2 dir = random2dPolar(i+floor(t)+coef*100.0);
        vec2 p = pos - dir*t;
        p *= rotate(dir.x+time*4.0);
        float b = mix(0.000, 0.001, smoothstep(1.0, 0.0, t));
        float d = 0.0005/pow(starSDF(p, 0.1), 4.0);
        c += b*d;
    }

    return c;
}

float fallStars(vec2 pos, float seed){
    float c = 0.0;

    for(float i = 0.0; i <= 10.0; i+=1.0){
        float x = random1d(i + random1d(i+222.20 + seed)) * 2.0 - 1.0;
        float y = random1d(i+100.0 + seed) * 2.0 - 1.0;
        vec2 a = random2dPolar(i + 10000.0);
        float aCoef = random1d(i + 2222.0)*0.5;
        float s = random1d(i+222.0) * 0.1;
        vec2 p = pos + vec2(x,y) + vec2(fract(time*aCoef+seed)*4.0 - 2.0);
        p *= rotate(a.x + time * a.y);
        float d = 0.000005/pow(starSDF(p, 0.1), 4.0);
        c += s*d;
    }
    return c;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    for(float i = 0.0; i <= 20.0; i+=1.0){
        float seed = random1d(i+222.0);
        color += fallStars(uv, seed)*hsv2rgb(seed, 1.0, 1.0);
    }

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec2 texUv = vec2(gl_FragCoord.xy/resolution);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0)+texture2D(backbuffer, texUv)*0.5;
}
