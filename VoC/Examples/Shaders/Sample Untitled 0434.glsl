#version 420

// ooki masayoshi
// mooki@juno.ocn.ne.jp
precision mediump float;
uniform float time;
uniform vec2  mouse;
uniform vec2  resolution;

out vec4 glFragColor;

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

const float sphereSize = 1.0;

const vec3 lightDir = normalize(vec3(0.0, 1.0, 2.0));

vec3 sokukutu(vec3 p, float power){
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
          c,  -s, 0.0,
          s,   c, 0.0,
        0.0, 0.0, 1.0
    );
    vec3 q = p;
    if (p.y > 0.0) {
        q = m * p;
    }
    return q;
}

vec3 zenkutu(vec3 p, float power){
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
        1.0, 0.0, 0.0,
        0.0,   c,  -s,
        0.0,   s,   c
    );
    vec3 q = p;
    if (p.y > 0.0) {
        q = m * p;
    }
    return q;
}

vec3 twist(vec3 p, float power){
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return m * p;
}

vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

float distFuncCylinder(vec3 p,vec3 center, vec2 r){
    vec2 d = abs(vec2(length(p.xz - center.xz), p.y - center.y)) - r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - 0.1;
}

float smoothMin(float d1, float d2, float k){
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

float distFuncFloor(vec3 p){
    return dot(p, vec3(0.0, 1.0, 0.0)) + 1.0;
}

float distFuncTorus(vec3 p,vec3 center,vec2 t){
    vec2 r = vec2(length(p.xy - center.xy) - t.x, p.z - center.z);
    return length(r) - t.y;
}

float distFuncBox(vec3 p,vec3 center,vec3 b){
    return length(max(abs(p - center) - b, 0.0)) - 0.2;
}

float distFuncShere(vec3 p,vec3 center,float r){
    return length(p - center) - r;
}

vec3 trans(vec3 p) {
    vec3 q = p;
    float okuyuki = 0.0;
    float yokohaba = 0.0;
    if (time < 32.0) {
        okuyuki = 0.0;
    } else if (time < 40.0) {
        okuyuki = 1.0;
    } else if (time < 48.0) {
        okuyuki = 2.0;
    } else if (time < 56.0) {
        okuyuki = 3.0;
    } else {
        okuyuki = 15.0;
    }
    if (time < 64.0) {
        yokohaba = 0.0;
    } else if (time < 72.0) {
        yokohaba = 1.0;
    } else if (time < 80.0) {
        yokohaba = 2.0;
    } else if (time < 88.0) {
        yokohaba = 3.0;
    } else {
        yokohaba = 10.0;
    }
    if ((p.z > -1.0 - 3.0*okuyuki)&&(abs(p.x) < 4.0 + 4.0*yokohaba)) {
        q = vec3(mod(p.x, 4.0) - 2.0,p.y,mod(p.z, 4.0) - 2.0);
    }
    return q;
}

float distanceFunc(vec3 p){
    float skip = 0.1*clamp(sin(PI*4.0*time),0.0,1.0);
    vec3 r;
    vec3 q;
    if (mod(time,32.0) < 8.0) {
        r = twist(trans(p), 0.4*sin(PI*2.0*time));
        q = r;
    } else if (mod(time,32.0) < 16.0) {
        r = zenkutu(trans(p), 0.2*sin(PI*2.0*time));
        q = r;
    } else if (mod(time,32.0) < 24.0) {
        r = sokukutu(trans(p), 0.3*sin(PI*2.0*time));
        q = r;
    } else if (mod(time,32.0) < 32.0) {
        r = trans(p);
        q = rotate(r, PI*2.0*sin(clamp(PI*sin(PI*0.5*time),0.0,PI/2.0)), vec3(0.0, 1.0, 0.0));
    }
    float d1 = distFuncTorus(q,vec3(0.0,0.0 + skip,0.0),vec2(0.8, 0.13));
    float d2 = distFuncBox(q,vec3(0.0,0.0 + skip,0.0),vec3(0.3, 0.6, 0.1));
    float d3 = distFuncShere(q, vec3(0.0, 1.2 + skip,0.0),0.4);
    float d4 = distFuncCylinder(q, vec3(0.3, -1.0 + skip,0.0), vec2(0.12, 0.8));
    float d5 = distFuncCylinder(q, vec3(-0.3, -1.0 + skip,0.0), vec2(0.12, 0.8));
    return smoothMin(smoothMin(smoothMin(smoothMin(d1, d2, 16.0), d3, 16.0), d4, 16.0), d5, 16.0);
}

vec3 getNormal(vec3 p){
    float d = 0.001;
    return normalize(vec3(
        distanceFunc(p + vec3(  d, 0.0, 0.0)) - distanceFunc(p + vec3( -d, 0.0, 0.0)),
        distanceFunc(p + vec3(0.0,   d, 0.0)) - distanceFunc(p + vec3(0.0,  -d, 0.0)),
        distanceFunc(p + vec3(0.0, 0.0,   d)) - distanceFunc(p + vec3(0.0, 0.0,  -d))
    ));
}

void main(void){
    // フラグメント座標
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec4 fragColor;
    
    // カメラ
    vec3 cPos = vec3(0.0,  0.5,  4.2);
    if (time > 64.0) {
        cPos = vec3(0.0,  0.5 + 4.0*abs(sin(PI*0.01*(time - 64.0))),  4.2);
    }
    vec3 cDir = normalize(-1.0*cPos);
    vec3 cUp  = normalize(vec3(0.0, -1.0*cDir.z, cDir.y));
    vec3 cSide = normalize(cross(cDir, cUp));
    float targetDepth = 1.0;
    
    // 光線
    vec3 ray = normalize(cSide * p.x + cUp * p.y + cDir * targetDepth);
    
    // レイマーチング
    float distance = 0.0;
    float distance2 = 0.0;
    float rLen = 0.0;
    vec3  rPos = cPos;
    for (int i = 0; i < 64; i++) {
        distance = distanceFunc(rPos);
        if ((abs(distance) > abs(distance2))&&(i > 0)&&(abs(distance2) < 0.01)) {
            distance = distance2;
        } else {
            distance2 = distance;
        }
        rLen += distance;
        rPos = cPos + ray * rLen;
    }
    
    // 衝突判定
    if (abs(distance) < 0.001) {
        vec3 normal = getNormal(rPos);
        float diff = clamp(dot(lightDir, normal), 0.0, 1.0);
        vec3 objCol = vec3(1.0,1.0,0.7);
        
        float cart = 0.0;
        if (diff > 0.8) {
            cart = 1.0;
        } else if (diff > 0.5) {
            cart = 0.8;
        } else {
            cart = 0.7;
        }
        
        if (abs(dot(ray, normal)) < 0.1) {
            cart = 0.0;
        }
        
        fragColor = vec4(objCol*cart, 1.0);
    } else if (abs(distance) < 0.01) {
        fragColor = vec4(vec3(0.0), 1.0);
    } else {
        fragColor = vec4(vec3(0.0), 0.0);
    }
    
    glFragColor = fragColor;
}
