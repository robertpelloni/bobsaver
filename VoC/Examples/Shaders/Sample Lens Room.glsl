#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define PI 3.1415926535
#define TIME (time * PI / 3.0)

#define TIME_ROTATE

#define ROOM_SIZE vec3(8, 4, 8)

#define SPHERE_SIZE 2.0
#define SPHERE_CENTER vec3(0, 0, 0)

// Rayと球の距離
float sdf_sphere(vec3 p)
{
    // return length(p - SPHERE_CENTER) - SPHERE_SIZE;
    return max(
        length(p - vec3(1,0,0)) - SPHERE_SIZE,
        length(p - vec3(-1,0,0)) - SPHERE_SIZE
    );
}

float sdf_box_invert(vec3 p)
{
    vec3 center = vec3(0.0, 0.0, 0.0); // 箱の位置
    vec3 size = ROOM_SIZE; // 箱のサイズ
    return - max(distance(p.x, center.x) - size.x, max(distance(p.y, center.y) - size.y, distance(p.z, center.z) - size.z)) ;   
}

float xor(float a, float b)
{
    return abs(a-b);
}

// Ray位置から球の法線を計算
vec3 getNormalSphere(vec3 p)
{
    float d = 0.01;
    return normalize(vec3(
        sdf_sphere(p + vec3(d,0,0)) - sdf_sphere(p - vec3(d,0,0)),
        sdf_sphere(p + vec3(0,d,0)) - sdf_sphere(p - vec3(0,d,0)),
        sdf_sphere(p + vec3(0,0,d)) - sdf_sphere(p - vec3(0,0,d))
    ));
}

// r0 : Rayの開始位置
// rd : Rayの向き
// isHit : Rayがオブジェクトにぶつかったかどうか
void raymarch_sphere(vec3 r0, vec3 rd, out float isHit, out float t)
{
    isHit = 0.0;
    t = 0.0;
    for(int i = 0; i < 7; i++)
    {
        vec3 rp = r0 + t * rd;
        float d = sdf_sphere(rp);
        if (d < 0.1) 
        {
            isHit = 1.0;
            break;
        }
        t += d;
    }
}

// Rayが球の中から外に出るときのRaymarching
// r0 : Rayの開始位置
// rd : Rayの向き
// isHit : Rayがオブジェクトにぶつかったかどうか
void raymarch_sphere_in(vec3 r0, vec3 rd, out float isHit, out float t)
{
    isHit = 0.0;
    t = 0.0;
    for(int i = 0; i < 27; i++)
    {
        vec3 rp = r0 + t * rd;
        float d = sdf_sphere(rp);
        if (d > 0.1) // 球の外に出た
        {
            isHit = 1.0;
            break;
        }
        t += abs(d);
    }
}

// r0 : Rayの開始位置
// rd : Rayの向き
// isHit : Rayがオブジェクトにぶつかったかどうか
void raymarch_plane(vec3 r0, vec3 rd, out float isHit, out float t)
{
    isHit = 0.0;
    t = 0.0;
    for(int i = 0; i < 24; i++)
    {
        vec3 rp = r0 + t * rd;
        float d = sdf_box_invert(rp);
        if (d < 0.03)
        {
            isHit = 1.0;
            break;
        }
        t += d;
    }
}

// 地面での円の描画
// p : 地面のテクスチャ座標
// center : 円の位置
// c1 : 背景色
// c2 : 円の色
vec3 renderCircle(vec2 p, vec2 center, vec3 c1, vec3 c2)
{
    float size = 2.5;
    float rDist1 = length(p - center);
    rDist1 = smoothstep(0.5, 0.0, rDist1 -  size);
    return mix(c1, c2, rDist1);
}

#define GREEN vec3(93, 189, 59)/255.0

// 部屋のレンダリング
// r0 : Rayの開始位置
// rd : Rayの進行方向
vec3 renderRoom(vec3 r0, vec3 rd)
{
    float isHitPlane;
    float t;
    raymarch_plane(r0, rd, isHitPlane, t);
    vec3 planeColor;
    if (isHitPlane > 0.0)
    {
        r0 = r0 + t * rd; // 地面の表面までRayを進める

        vec3 color = vec3(0.15);
        color = mix(color, vec3(1,0,0), step(ROOM_SIZE.x*0.99, r0.x)); // +X
        color = mix(color, GREEN, 1.0-step(-ROOM_SIZE.x*0.99, r0.x)); // -X
        color = mix(color, vec3(0.2,0,1), step(ROOM_SIZE.y*0.99, r0.y)); // +Y
        color = mix(color, vec3(1,0,.5), step(ROOM_SIZE.z*0.99, r0.z)); // +Z
        color = mix(color, vec3(1,.5,0), 1.0-step(-ROOM_SIZE.z*0.99, r0.z)); // -Z
        float fade = smoothstep(12.0, 3.0, length(r0));
        
        r0 = step(fract(r0 * 0.75), vec3(0.5));
        float gridPlane = xor(xor(r0.x, r0.y),r0.z);
        planeColor = mix(vec3(0), vec3(gridPlane), isHitPlane) * fade * color;

    }
    
    return planeColor;
}

// 球のライティング
vec3 renderLighting(vec3 v, vec3 n)
{
    float a = 0.1; // 環境光反射 強度
    // float d = 0.0; // 拡散反射 強度
    // float s = 0.0; // 鏡面反射 強度
    // float gloss = 500.0; // 光沢度
    float rim = 0.55; // リムライティング強度
    float rim_exponent = 3.0;
    vec3 l = normalize(vec3(0, 1.0, 1.5)); // 光源への向きベクトル
    // vec3 r = reflect(-l, n); // 光の反射の計算

    return 
        + vec3(0.3, 0.3, 0.3) * a  
        // + vec3(1, 0, 0.2) * d * clamp(dot(l, n), 0.0, 1.0) 
        // + vec3(1, 0, 0.2) * s * pow(clamp(dot(v, r), 0.0, 1.0), gloss)
        // + vec3(0.0, 0.3, 0.5) * rim * pow(1.0 - abs(dot(v, n)), rim_exponent)
        + vec3(.8,.8,1.0) * rim * pow(1.0 - abs(dot(v, n)), rim_exponent)
        ;

}

void main()
{
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);

    // vec3 cPos = vec3(7.0 * sin(TIME),0,-4);
    // vec3 cPos = SPHERE_CENTER + 6.0 * vec3(cos(TIME) , 1.1 + sin(TIME), sin(TIME) );
    // vec3 cPos = vec3(cos(TIME) * 6.0, 4.0 + 1.0 * sin(TIME), 0.0);
    vec3 cPos = vec3(4.0 * cos(TIME), 0.0, 4.0 * sin(TIME));
    // vec3 cPos = mix(0.25, 1.5, 0.5 + 0.5 * cos(TIME)) * vec3(cos(TIME), (sin(TIME)), -4.0);
    // vec3 cPos = mix(0.5, 6.0, 0.5 + 0.5 * cos(TIME)) * vec3(cos(TIME), 0.3 * sin(TIME * 2.0), sin(TIME));
    // vec3 cPos = 4.0 * vec3(cos(TIME), sin(TIME * 0.5) * 0.5, sin(TIME));
    vec3 cDir = normalize(SPHERE_CENTER - cPos); 
    vec3 cUp = normalize(vec3(0,1,0)); 
    vec3 cSide = normalize(cross(cUp,cDir)); 
    vec3 rd = normalize(p.x * cSide + p.y * cUp + cDir); // ray direction
    vec3 v = rd;

    float t = 0.0;

    float isHitSphere;
    vec3 rf0; // reflected ray origin
    vec3 rfd; // reflected ray direction
    vec3 nf; // reflected ray normal
    float isRayReflect;

    vec3 r0 = cPos; // ray origin
    raymarch_sphere(r0, rd, isHitSphere, t);

    float cameraIsInSphere = step(t, 0.0);
    float reflectBlend = 0.5;

    // Rayが球にHitした場合は、Rayを屈折させる
    vec3 sphereLighting = vec3(0.0);    
    if (isHitSphere > 0.0)
    {
        r0 = r0 + t * rd; // Rayを進める

        vec3 n = getNormalSphere(r0); // 球表面の法線
        nf = n;
        
        // 球の表面の色付け
        sphereLighting = renderLighting(v, n);

        // Rayの反射
        {
            rf0 = r0; // 反射光の開始位置
            rfd = reflect(v, n); // 反射光の向き
            isRayReflect = 1.0;
        }

        // Rayの屈折
        {
            // Rayがレンズの中に入るときの屈折
            float eat_air = 1.0; // 空気の屈折率
            float eat_water = 1.333; // 水の屈折率
            float eta = eat_air / eat_water; // 屈折率(空気 -> 水)
            rd = refract(rd, n, eta); 

            // レンズの中にあるRayがレンズの外に出るときの屈折
            raymarch_sphere_in(r0, rd, isHitSphere, t);
            if (isHitSphere > 0.0)
            {
                r0 = r0 + t * rd; // Rayを進める
                n = getNormalSphere(r0); // 球表面の法線(外向き)
                rd = refract(rd, -n, 1.0/eta); 
            }
        }
    }

    // 直接光の描画
    vec3 firstColor = renderRoom(r0, rd);

    // // // 反射光の描画
    // vec3 reflectColor;
    // if (cameraIsInSphere < 1.0 && isRayReflect > 0.0)
    // {
    //     reflectColor = renderRoom(rf0, rfd);
    // }
    // glFragColor = vec4(sphereLighting + firstColor + reflectColor * 0.15, 1);
    glFragColor = vec4(sphereLighting + firstColor, 1);
    // glFragColor = vec4(sphereLighting + firstColor, 1);
}
