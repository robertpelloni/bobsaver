#version 420

// original https://neort.io/art/br0ekps3p9f48fkiuhhg

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define PI 3.141592654
#define PI2 6.283185307
#define HALF_PI 1.5707963267948966
#define saturate(x) (clamp(x, 0.0, 1.0))

// Util
// -----------------------------------------
vec2 rot(vec2 p,float r) {
    mat2 m = mat2(cos(r),sin(r),-sin(r),cos(r));
    return m * p;
}

vec3 hsv2rgb(float h, float s, float v){
    return vec3((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

float rand (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
}

// Shape
// -----------------------------------------
vec3 trans(vec3 p){
    return mod(p, 2.0) - 1.0;
}

float sdCross(vec3 p, float c) {
    p = abs(p);
    float dxy = max(p.x, p.y);
    float dyz = max(p.y, p.z);
    float dxz = max(p.x, p.z);
    return min(dxy, min(dyz, dxz)) - c;
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

#define ITERATIONS 3
float deMengerSponge1(vec3 p, float scale, float width) {
    float d = sdBox(trans(p), vec3(1.0));
    float s = 1.0;
    for (int i = 0; i < ITERATIONS; i++) {
        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= scale;
        vec3 r = 1.0 - scale * abs(a);
        float c = sdCross(r, width) / s;
        d = max(d, c);
    }
    return d;
}

//最終的な距離関数 
float dist(vec3 p) {
    // 前進
    p.z -= abs(mod(0.5 * time,2000.));

    // 奥に行くほど回転
    p.xy = rot(p.xy, 1.0*p.z-0.2*time);
    return deMengerSponge1(p,4.0,1.4-0.6*sin(p.z*PI2/5.0));
}

//法線の取得
vec3 gn(vec3 p) {
    const float h = 0.001;
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * dist(p + k.xyy * h) +
        k.yyx * dist(p + k.yyx * h) +
        k.yxy * dist(p + k.yxy * h) +
        k.xxx * dist(p + k.xxx * h));
}

// Color
// -----------------------------------------
//ライティング
vec3 light(vec3 p,vec3 view) {
    vec3 normal = gn(p);
    vec3 ld = normalize(vec3(cos(time),sin(time),sin(time)));//光の方向を仮定
    float NdotL = max(dot(ld, normal), 0.0);//ランバート反射の計算
    vec3 R = normalize(-ld + NdotL * normal * 2.0);//反射光の計算
    float spec = pow(max(dot(-view, R), 0.0), 11.0) * saturate(sign(NdotL));//フォン鏡面反射の計算
    vec3 posCol = mix(hsv2rgb(p.z,1.0,1.0), vec3(1.0, 0.0, 0.0), 0.9);
    vec3 col = posCol * (NdotL + spec);
    float dist2org = length(p) + rand(p.xz)*0.07;
    col += saturate(500.0 * sin(dist2org-time/PI2*10.0+3.0) - 499.0) * posCol;
    return saturate(col * vec3(1.0,1.0,1.0) + 0.05);
}

void main() {
    const float near = 1.0;
    const float far = 10.;

    vec2 st = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    vec3 color = vec3(0.0);
    color = vec3(st.x, st.y, abs(sin(time)));

    // camera
    vec3 cPos = vec3(0.0, 0.0, 2.0);
    vec3 cDir = vec3(0.0, 0.0, -1.0);
    vec3 cUp  = vec3(0.0, 1.0, 0.0);
    vec3 cSide = cross(cDir, cUp);
    float targetDepth = 0.5;

    vec3 ro = vec3(st.x*0.2, st.y*0.2, 0.0);//レイのスタート地点を設定
    vec3 rd = normalize(cSide * st.x + cUp * st.y + cDir * targetDepth);//レイの方向を計算

    float t = 0.001;
    
    for (int i = 0; i < 80; ++i) {
        float d = 0.0;
        d = dist(ro + rd * t);
        t += d;
        if (t > far){
            break;
        }
    }

    vec3 col = light(ro + rd * t, rd);//ライティングを計算
    
    vec3 lastPos = ro + rd * t;
    vec3 rd2 = reflect(rd, gn(lastPos));
    lastPos += rd2 * 0.05;
    
    // 反射して得られた分を加算
    float t2 = 0.001;
    for (int i = 0; i < 30; ++i) {
        float d = 0.0;
        d = dist(lastPos + rd2 * t2);
        t2 += d;
        if (t2 > far){
            t2 = 0.0;
            break;
        }
    }

    if(t2 > 0.0){
        col += 0.5 * light(lastPos + rd2 * t2, rd2);
    }

    //フォグ
    float ndepth = saturate((far - t) / (far - near));
    vec3 bcol = vec3(0.5, 0.5, 0.5);//フォグ色
    col = mix(bcol, col, pow(ndepth, 4.0));

    col = saturate(col);
    glFragColor = vec4(col*vec3(1.0,1.0,1.0),1.0);
}
