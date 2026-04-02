#version 420

// original https://www.shadertoy.com/view/tscGRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 colors[5] = vec3[5](
    vec3(0.969, 0.706, 0.831),
    vec3(0.933, 0.522, 0.714),
    vec3(0.886, 0.373, 0.616),
    vec3(0.839, 0.251, 0.529),
    vec3(0.765, 0.122, 0.424)
);

float seed = 3265.0;

float N31(vec3 v) {
    return fract(sin(v.x * 345.74 + v.y * 798.54 + v.z* 175.87) * seed);
}

float N21(vec2 v) {
    return fract(sin(v.x * 345.74 + v.y * 798.54 ) * seed);
}

vec2 N22(vec3 v) {
    float x = N31(v);
    float y = N31(v * x);
    return vec2(x, y);
}

vec3 N33(vec3 v) {
    float x = N31(v);
    float y = N31(v * x);
    float z = N31(v * y);
    return vec3(x, y, z);
}

float Noise2(vec2 v) {
    vec2 lv = fract(v);
    lv = lv * lv * (3.0 - 2.0 * lv);
    vec2 id = floor(v);
    float c = 
        mix(
            mix(N21(id + vec2(0,0)), N21(id + vec2(1,0)), lv.x),
            mix(N21(id + vec2(0,1)), N21(id + vec2(1,1)), lv.x), 
        lv.y);
    return c;
}

float SmoothNoise2(vec2 v){
    float n = 0.0;
    float o = 1.0;
    float av = 0.0;    
    for (float i = 1.0; i < 4.0; i += 1.0) {
        n += Noise2(v * o) / pow(2.0, i);
        o *= 2.0;
        av += 1.0 / pow(2.0, i);
    }
    return n / av;
}

float Noise3(vec3 v) {
    vec3 lv = fract(v);
    lv = lv * lv * (3.0 - 2.0 * lv);
    vec3 id = floor(v);

    float c = mix(
        mix(
            mix(N31(id + vec3(0,0,0)), N31(id + vec3(1,0,0)), lv.x),
            mix(N31(id + vec3(0,1,0)), N31(id + vec3(1,1,0)), lv.x), lv.y),
        mix(
            mix(N31(id + vec3(0,0,1)), N31(id + vec3(1,0,1)), lv.x),
            mix(N31(id + vec3(0,1,1)), N31(id + vec3(1,1,1)), lv.x), lv.y), lv.z);

    return c;
}

float SmoothNoise3(vec3 v){
    float n = 0.0;
    float o = 1.0;
    float av = 0.0;    
    for (float i = 1.0; i < 64.0; i += 1.0) {
        n += Noise3(v * o) / pow(2.0, i);
        o *= 2.0;
        av += 1.0 / pow(2.0, i);
    }
    return n / av;
}

float smax(float a, float b, float k){
    float h = clamp((b-a) / k + 0.5, 0.0, 1.0);
    return mix(a,b,h) + h * (1.0 - h) * k * 0.5;
}

float HeartDist(vec2 uv, vec2 o, float r, float bias){
    vec2 s = vec2(0.7, 1.0) / r;
    uv = o + uv * s;
       float b = r * bias;
    uv.y -= smax(sqrt(abs(uv.x))*0.5,b,0.1);
    //uv.y -= sqrt(abs(uv.x))*0.5;
    uv.y += b;
    float d = length(uv);
    return smoothstep(r + b, r - b, d);
}

vec4 DrawHeart(vec2 uv, float r, float bias){
    vec3 c = vec3(0.0);
    float d = HeartDist(uv, vec2(0,0.1), r, bias);
    float alpha = d;
    c += mix(colors[4], colors[2], pow(d,1.0));
    
    return vec4(c, step(0.1,alpha));
}

void DrawHearts(in vec2 uv, inout vec3 color) {
    uv /= 128.0;
    vec4 c = vec4(0.0);
    float layers = 12.0;
    float layer_time = 16.0;
    float layer_spawn = layer_time / layers;
    float time = -time*2.0;
    for (float i = layers - 1.0; i >= 0.0; i--) {
        float lt = mod(time, layer_time) + i * layer_time;
        vec2 luv = fract(uv * lt*4.0) - 0.5;
        vec2 id = floor(uv * lt*4.0)-0.5;
        float tt = floor(time / (layer_time)) - i;
        float fade_time = 
            smoothstep(0.0,0.1, lt / (layers * layer_time))*
            smoothstep(1.0,0.5, lt / (layers * layer_time));
        if (N31(vec3(id, floor(tt))) > 0.9){
            vec4 sc = DrawHeart(luv, 0.2, 0.2);
            c = mix(c, sc, sc.a * fade_time);
        }
        
    }
    color = mix(color, c.rgb,c.a);
}

vec3 DrawHeartLight(vec2 uv, float r, float bias, float time, vec2 id){
    float i = time*(sin((N21(id) + time)*2.0)*0.5+0.5);
    float to_center = length(uv);
    float atten = 1.0 / (1.0 + to_center*to_center*to_center*500.0)*0.25;
    return vec3(1.0) * atten*i;
}

void DrawLights(in vec2 uv, inout vec3 color) {
    uv /= 128.0;
    vec3 c = vec3(0.0);
    float layers = 12.0;
    float layer_time = 16.0;
    float layer_spawn = layer_time / layers;
    float time = -time*2.0;
    for (float i = layers - 1.0; i >= 0.0; i--) {
        float lt = mod(time, layer_time) + i * layer_time;
        vec2 luv = fract(uv * lt*4.0) - 0.5;
        vec2 id = floor(uv * lt*4.0)-0.5;
        float tt = floor(time / (layer_time)) - i;
        float fade_time = 
            smoothstep(0.0,0.1, lt / (layers * layer_time))*
            smoothstep(1.0,0.5, lt / (layers * layer_time));
        if (N31(vec3(id, floor(tt))) > 0.9){
            vec3 sc = DrawHeartLight(luv, 0.2, 0.2,fade_time, id)*fade_time;
            c += sc;
        }
        
    }
    color += c;
}

void DrawClouds(vec2 uv, inout vec3 color) {
    float time = time*0.5;
    
    float c = SmoothNoise3(vec3(uv*8.0, time*0.5));
    
    vec3 cloud_color =pow(mix(colors[1],colors[4],c),vec3(2.0));
    color += cloud_color;
}

void main(void) {
    vec2 aspect = vec2(resolution.y/resolution.x, 1.0);
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.xy * 2.0 / aspect;
    
    vec3 c = vec3(0.0);
    
    float big_heart_mask = clamp(HeartDist(uv/16.0, vec2(0.0,0.05),0.20, 0.4), 0.0, 1.0);
    DrawClouds(uv,c);
    c = (c - vec3(big_heart_mask*0.5)) ;
    DrawLights(uv,c);
    DrawHearts(uv,c);
    
    glFragColor = vec4(c, 1.0);
}
