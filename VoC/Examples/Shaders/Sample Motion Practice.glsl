#version 420

// original https://neort.io/art/c0jaafc3p9f5tuggj5sg

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float expInOut(float t){
    return (t == 0.0 || t == 1.0)
            ? t
            : (t < 0.5) 
            ?  0.5 * pow(2.0, 20.0 * (t - 0.5)) 
            : -0.5 * pow(2.0, 20.0 * (0.5 - t)) + 1.0;
}

float expIn(float t){
    return t == 0.0 ? t : pow(2.0, 10.0 * (t - 1.0));
}

float expOut(float t){
    return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

float linearStep(float start, float end, float t){
    return clamp((t - start) / (end - start), 0.0, 1.0);
}

float sdCircle(vec2 p, float r){
    return length(p) - r;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    // 1. linearStepを使った等速変化
    vec2 p1 = uv;
    float ft1 = fract(time * 0.3);  // 0 ~ 1
    float t1 = linearStep(0.1, 0.4, ft1);  // tが0.1 ~ 0.4のときに0から1に動く
    float t2 = linearStep(0.6, 0.9, ft1);  // tが0.6 ~ 0.9のときに0から1に動く
    vec2 offset1 = vec2(mix(-0.7, 0.7, t1 - t2), 0.6);   // tが0.1 ~ 0.4のときは-0.7から0.7、0.6 ~ 0.9のときは0.7から-0.7に値が動く
    color += smoothstep(0.012, 0.0, sdCircle(p1 - offset1, 0.12));

    // 2. 初速が遅くて徐々に加速していく動き
    vec2 p2 = uv;
    float ft2 = fract(time * 0.3);  // 0 ~ 1
    float t3 = linearStep(0.1, 0.4, ft2);  // tが0.1 ~ 0.4のときに0から1に動く
    float t4 = linearStep(0.6, 0.9, ft2);  // tが0.6 ~ 0.9のときに0から1に動く
    vec2 offset2 = vec2(mix(-0.7, 0.7, expIn(t3) - expIn(t4)), 0.2);   // tが0.1 ~ 0.4のときは-0.7から0.7、0.6 ~ 0.9のときは0.7から-0.7に値が動く
    color += smoothstep(0.012, 0.0, sdCircle(p1 - offset2, 0.12));

    // 3. 初速が早くて徐々に減速していく動き
    vec2 p3 = uv;
    float ft3 = fract(time * 0.3);  // 0 ~ 1
    float t5 = linearStep(0.1, 0.4, ft3);  // tが0.1 ~ 0.4のときに0から1に動く
    float t6 = linearStep(0.6, 0.9, ft3);  // tが0.6 ~ 0.9のときに0から1に動く
    vec2 offset3 = vec2(mix(-0.7, 0.7, expOut(t5) - expOut(t6)), -0.2);   // tが0.1 ~ 0.4のときは-0.7から0.7、0.6 ~ 0.9のときは0.7から-0.7に値が動く
    color += smoothstep(0.012, 0.0, sdCircle(p3 - offset3, 0.12));

    // 4. 最初は加速して、減速しながら止まる動き 行って戻る
    vec2 p4 = uv;
    float ft4 = fract(time * 0.3);  // 0 ~ 1
    float t7 = linearStep(0.1, 0.4, ft4);  // tが0.1 ~ 0.4のときに0から1に動く
    float t8 = linearStep(0.6, 0.9, ft4);  // tが0.6 ~ 0.9のときに0から1に動く
    vec2 offset4 = vec2(mix(-0.7, 0.7, expInOut(t7) - expInOut(t8)), -0.6);  // tが0.1 ~ 0.4のときは-0.7から0.7、0.6 ~ 0.9のときは0.7から-0.7に値が動く
    color += smoothstep(0.012, 0.0, sdCircle(p4 - offset4, 0.12));

    return color;
}

void main(void){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
