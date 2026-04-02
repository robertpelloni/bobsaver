#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphereSize = 1.3;
#define INTERVAL 4.0

float distance_func(vec3 p)
{
    p.z -= mod(time * 10.0, 1000.0);
    
    // 空間を立方体に分割
    vec3 pi = floor(p / INTERVAL);         
    p.x += sin(pi.z * 4.0 + time);
    p.y += sin(pi.z * 2.0 + time * 0.4);
    p = mod(p, INTERVAL) - INTERVAL / 2.0;    
        
    // 点pから球までの距離
    return length(p) - sphereSize;
}

vec3 getNormal(vec3 p){
    float d = 0.001;
    return normalize(vec3(
        distance_func(p + vec3(  d, 0.0, 0.0)) - distance_func(p + vec3( -d, 0.0, 0.0)),
        distance_func(p + vec3(0.0,   d, 0.0)) - distance_func(p + vec3(0.0,  -d, 0.0)),
        distance_func(p + vec3(0.0, 0.0,   d)) - distance_func(p + vec3(0.0, 0.0,  -d))
    ));
}

/*vec3 pat( vec3 p ) {
    vec2 div = floor(p.xy / 4.0);
    return vec3(mod(div.x +  div.y, 2.0));
}

*/
float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    const int res = 16;
    //const float invRes = 1.0 / float(res);
    
    p *= float(res);
    vec2 n = floor(p);
    vec2 f = fract(p);
    
    f = f * f * (3.0 - 2.0 * f);
    
    float n0 = rand(n);
    float n1 = rand(n + vec2(1.0, 0.0));
    float n2 = rand(n + vec2(0.0, 1.0));
    float n3 = rand(n + vec2(1.0, 1.0));
    
    float m0 = mix(n0, n1, f.x);
    float m1 = mix(n2, n3, f.x);
    
    return mix(m0, m1, f.y);
}

vec3 pat( vec3 p ) {
    vec2 position =p.xy;

    vec3 color = vec3(0.0);
    color += noise(position) * 0.5;
    color += noise(position * 2.0) * 0.25;
    color += noise(position * 4.0) * 0.125;
    color += noise(position * 8.0) * 0.064;
    color += noise(position * 16.0) * 0.032;
    color += noise(position * 32.0) * 0.016;
    color += noise(position * 64.0) * 0.008;

    return color;

}

void main( void ) {
    vec2 p = ( gl_FragCoord.xy - resolution.xy / 2.0 ) / min(resolution.x, resolution.y);
    
    // カメラ定義
    vec3 cPos = vec3(0.0, 0.0, 0.01); // camera position
    vec3 cDir = vec3(0.0, 0.0, -1.0); // camera direction    
    vec3 cUp = vec3(0.0, 1.0, 0.0); // camera up
    vec3 cSide = cross(cUp, cDir); // cUpとcDirに直交するベクトル
    float depth = 1.0;
    
    // レイマーチング
    vec3 ray = normalize(cSide * p.x + cUp * p.y + depth * cDir);    // レイ
    float dist; // レイとオブジェクト間の距離
    float rLen; // レイに足す長さ
    vec3 rPos; // レイの現在位置
    for(int i = 0; i < 22; i++){
        dist = distance_func(rPos); // レイ位置からオブジェクトまでの距離を求める
        rLen += dist; // 距離を足す
        rPos = cPos + ray * rLen; // レイ位置の更新
    }
    float marchResult = step(dist, 0.01); // レイマーチングの結果 : distがある程度小さい場合は1.0
    //vec3 bgColor = vec3(0.0, 0.1, 0.2); // 背景色
    //vec3 marchColor = mix(vec3(marchResult), bgColor, 0.0); // レイマーチング結果に背景色を混ぜる
    
     // リムライティング : 光と法線の内積をとる
    vec3 normal = getNormal(rPos);
    float rim = 1.0 - dot(normalize(cDir), normal);        
    rim = dot(vec3(0, 0, 1), normal);
    rim = smoothstep(.5, 0.0, rim);
    rim = .6 + rim * 0.4;
    
    // 逆2乗の法則 : 光は距離の2乗に反比例する
    float distMix= 100.0 / (1.0 + rLen * rLen); // rLenが0.0の時に増幅させないために1.0足す
    distMix = clamp(distMix, 0., 0.3); // 
    // distMix = pow(distMix, 0.5); // イイ感じに補正    
    
    vec3 c1 = vec3(0.0, 0.0, 0.5);
    vec3 c2 = vec3(1.0, 1.0, 1.0);
    //vec3 fogColor = bgColor; // 空気の色
    
    //vec3 finalRGB = marchColor * mix(c1, c2, distMix) * rim + fogColor; // 画面に出力するRGBカラー
    
    vec3 finalRGB = rPos+vec3(50.,50.,15.);
    finalRGB*=vec3(0.01,0.01,.05);
    finalRGB*=pat(rPos*.1);
    //finalRGB*=.1;
    //finalRGB *= 0.65; // イイ感じになるように少し暗くする
    glFragColor = vec4(finalRGB, 1.0);    
}
