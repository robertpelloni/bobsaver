#version 420

// original https://www.shadertoy.com/view/3tBBWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1

// Distance Function
float sphere(vec3 p, float s) {
    return length(p) - s;
}

vec4 orb;

float map1( vec3 p, float s )
{
    float scale = 2.0;

    orb = vec4(1000.0); 
    
    for( int i=0; i<10;i++ )
    {
        p = -1.0 + 2.0*fract(0.5*p+0.5);

        float r2 = dot(p,p);
        
        orb = min( orb, vec4(abs(p),r2) );
        
        float k = s/r2;
        p     *= k;
        scale *= k;
    }
    
    float ans1 = abs(p.x)/scale;
    float ans2 = abs(p.y)/scale;
    float ans3 = abs(p.z)/scale;
    float ans4 = 1.0/scale;
    float t = mod(time,3.0);
    float t1, t2, t3, t4;
    t1 = max(0.0,-2.0*pow((t-0.5),2.0)+0.60);
    t2 = max(0.0,-2.0*pow((t-1.5),2.0)+0.60);
    t3 = max(0.0,-2.0*pow((t-2.5),2.0)+0.60);
    return t1*ans1 + t2*ans2 + t3*ans3; 
}

float map2( vec3 p, float s ) 
{
    float scale = 2.0;

    orb = vec4(1000.0); 
    
    for( int i=0; i<10;i++ )
    {
        p = -1.0 + 2.0*fract(0.5*p+0.5);

        float r2 = dot(p,p);
        
        orb = min( orb, vec4(abs(p),r2) );
        
        float k = s/r2;
        p     *= k;
        scale *= k;
    }
    float ans4 = 1.0/scale;
    return 1.0*ans4;
}
vec3 CreateRay(vec2 p, vec3 cameraPos, vec3 cameraTarget, float fov) {
    vec3 forward = normalize(cameraTarget - cameraPos);
    vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, side));
    return normalize(forward * fov + side * p.x + up * p.y);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    //カメラの位置
    float pi = atan(1.0)*4.0;
    vec3 cameraPos;
    cameraPos = vec3(1.0, 1.0, 1.0);
    if (time > 16.0){
        float t = time - 16.0;
        t = t*t/24.0;
        cameraPos = vec3(1.0+sin(t*pi/4.0), 1.0, cos(t*pi/4.0));
    }
    if (time > 40.0){
        cameraPos = vec3(1.0, 1.0, 1.0);
    }
    if(time > 58.0){
        float t = time - 58.0;
        t = t*t/8.0;
        cameraPos = vec3(1.0,1.0,1.0+t);
    }

    
    // カメラの注視点
    vec3 cameraTarget = vec3(2.0, 2.0, 2.0);
    if(time > 16.0){
        float t = time - 16.0;
        t = t*t/24.0;
        cameraTarget = vec3(2.0 + sin(t*pi/4.0), 2.0, 1.0 + cos(t*pi/4.0));
    }
    if(time > 40.0){
        cameraTarget = vec3(2.0,2.0,2.0);
    }
    if(time > 58.0){
        float t = time - 58.0;
        t = t*t/8.0;
        cameraPos = vec3(2.0,2.0,2.0+t);
    }
    
    // シェーディングピクセルのカメラからシーンへのレイ
    vec3 ray = CreateRay(p, cameraPos, cameraTarget, 2.5);

    // レイマーチング
    float t = max(60.0/time,1.0);
    vec3 col = vec3(0.0);
    int it = int(time*3.0);
    for(int i=0; i<min(it,900); i++) {
        vec3 pos = cameraPos + ray * t;
        float d = map2(pos, 1.2);
        if (time > 50.0) d = map1(pos, 1.2);
        if (d < 0.001) {
            col = vec3(1.0 - float(i) / 70.);
            break; 
        }
        t += d;
    }
    //Timer
    if(time > 50.0){
        col -= vec3(0.4);
        if(mod(time,3.0) < 1.0) col += vec3(0.9,0.8,0.0);
        else if(mod(time,3.0) < 2.0) col += vec3(0.4,0.2,0.0);
        else if(mod(time,3.0) < 3.0) col += vec3(0.3,0.3,0.3);
    }
    if(time > 72.0){
        col = vec3(0.0,0.0,0.0);
    }
    glFragColor = vec4(col,1.0);
} 
