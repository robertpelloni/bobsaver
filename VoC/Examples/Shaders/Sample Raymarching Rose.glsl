#version 420

// original https://neort.io/art/cb70u9k3p9f2v73uqlf0

uniform vec2  resolution;     // resolution (width, height)
uniform vec2  mouse;          // mouse      (0.0 ~ 1.0)
uniform float time;           // time       (1second == 1.0)
uniform sampler2D backbuffer; // previous scene

out vec4 glFragColor;

const float PI = 3.1415926;

const int REFLECT_ITER = 3;
const int MENGER_ITER = 3;
const int RAY_ITER = 60;
const float FAR = 100.0;
const float EPS = 0.0001;

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

mat2 rot(float a){
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}
vec3 opTwist( in vec3 p )
{
    const float k = 10.0; // or some other amount
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return q;
}

float blob2(float d1, float d2, float k){
    return -log(exp(-k*d1)+exp(-k*d2))/k;
}
float smin( float a, float b, float k )
{ // by iq
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdPlane(vec3 p, float h){
    return p.y - h;
}

float sdBox(vec3 p, vec3 s){
    vec3 q = abs(p) - s;
    return max(max(q.x, q.y), q.z);
}
float sdRoundBox(vec3 p, vec3 size, float r){
    vec3 d = abs(p) - size;
    return length(max(d, 0.0)) - r;
}
float sdTorus(vec3 p, vec2 t){
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdOctahedron( in vec3 p, in float s) {
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}

float sdBarX(vec3 p, vec2 s){
    vec2 q = abs(p.yz) - s;
    return max(q.x, q.y);
}
float sdBarZ(vec3 p, vec2 s){
    vec2 q = abs(p.xy) - s;
    return max(q.x, q.y);
}

float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float sdPoleX(vec3 p, float r){
    return length(p.yz) - r;
}
float sdPoleY(vec3 p, float r){
    return length(p.xz) - r;
}
float sdPoleY2(vec3 p, float r, float w){
    return max(length(p.xz) - r, p.y - w);
}

float sdInfinityDoor(vec3 p, float s, float interbal){
    p.z = mod(p.z, interbal) - interbal / 2.0;
    
    float d = sdPoleX(p - vec3(0.0, s, 0.0), s);
    d = min(d, sdBarX(p - vec3(0.0, -s, 0.0), vec2(s * 2.0,s)));
    return d;
}

float sdInfinityPole(vec3 p, float s, float interbal){
    p.z = mod(p.z, interbal) - interbal / 2.0;
    
    float d = sdPoleY(p - vec3(0.0, s, 0.0), s);
    return d;
}

float sdTiledFloor(vec3 p, float interbal){
    float d;
    p.xz = mod(p.xz, interbal) - interbal / 2.0;
    d = sdPlane(p, 0.0);
    d = max(d, -sdBarX(p - vec3(0.0, 0.0, 0.0), vec2(0.01, 0.01)));
    d = max(d, -sdBarZ(p - vec3(0.0, 0.0, 0.0), vec2(0.01, 0.01)));
    return d;
}

// https://www.shadertoy.com/view/Mlf3Wj
vec2 foldRotate(in vec2 p, in float s) {
    float a = PI / s - atan(p.x, p.y);
    float n = PI*2.0 / s;
    a = floor(a / n) * n;
    p *= rot(a);
    return p;
}

float dTree(vec3 p) {
    //float scale = 0.8 * clamp(1.0 * sin(0.2 * time)/2.0 + 0.5, 0.0, 1.0) + 0.1;
    float scale = 0.8;
    float width = mix(0.25 * scale, 0.01, clamp(p.y, 0.0, 1.0));
    vec3 size = vec3(width, 1.0, width);
    
    p.xz *= rot(0.05);
    p.yz *= rot(0.5);
    p.xy *= rot(time*0.078);
    
    float d = sdRoundBox(p, size, size.x * 0.15);
    
    for (int i = 0; i < 10; i++) {
        vec3 q = p;
        //q.yz *= rot(0.4);
        
        q.x = abs(q.x);
        q.y -= 0.5 * size.y;
        q.yz *= rot(0.3 + sin(time * 0.123) * 0.1 - clamp(float(i) - 2.0, 0.0, 10.0) * 0.1);
        q.xy *= rot(-1.2);
        
        d = min(d, sdRoundBox(p, size, size.x * 0.15));
        //d = min(d, sdPoleY2(p, width, width));
        
        p = q;
        size *= scale;
    }
    return d;
}

float dTree2(vec3 p) {
    float scale = 0.85;
    float width = mix(0.25 * scale, 0.02, clamp(p.y, 0.0, 1.0));
    vec3 size = vec3(width, 1.0, width);
    
    p.xz *= rot(0.05);
    p.yz *= rot(0.5);
    p.xy *= rot((time+210.0)*0.078);
    
    float d = sdRoundBox(p, size, size.x * 0.15);
    
    for (int i = 0; i < 8; i++) {
        vec3 q = p;
        q.x = abs(q.x);
        q.y -= 0.5 * size.y;
        q.yz *= rot(0.25 + sin(time * 0.123) * 0.1 );
        q.xy *= rot(-1.2);
        
        d = min(d, sdRoundBox(p, size, size.x * 0.15));
        
        p = q;
        size *= scale;
    }
    return d;
}

float dSnowCrystal(vec3 p) {
    vec3 _p = p;
    
    _p -= vec3(0.0, -0.5, time + 3.0);
    _p.yz *= rot(-PI*0.5);

    _p.yz *= rot(-0.2);
    //_p = opTwist(_p);
    // 時間でうごくやつ
    //_p.xy = foldRotate(_p.xy, clamp(6.0 * sin(0.2 * time)/2.0 + 9.0, 6.0, 12.0));
    _p.xy = foldRotate(_p.xy, 6.0);
    return dTree(_p);
}

float noise(float _a){
    float _noise = sin(-time*3.45+_a);
    return _noise;
}

vec2 pmod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + PI/r;
    float n = PI*2.0 / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}
float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float dBar(vec2 p, float width) {
    vec2 d = abs(p) - width;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) + 0.01 * width;
}

float _ScaleAmount = 0.6;
float _PolerAmount = 6.0;
float _AnimAmount = 6.0;
float _AngleAmount = 0.05;
float _LengthAmount = 0.46;
float _WidthAmount = 0.4;
float _WidthDecay = 0.852;
float _BranchAmount = 0.67;
float _BranchPos = 1.6;

float Branch(vec3 p) {
    //float scale = 0.8 * clamp(1.0 * sin(0.2 * _Time)/2.0 + 0.5, 0.0, 1.0) + 0.1;
    float scale = _BranchAmount; // 
    float width = _WidthAmount * scale;
    vec3 size = vec3(width, _LengthAmount, width / 10.0 * _ScaleAmount);
    
    vec3 _p = p;
    _p.xz = _p.xz * rot(0.2);
    _p.yz = _p.yz * rot(0.4);
    _p.xy = _p.xy *  rot(sin(time * 0.078 * _AnimAmount) * 0.2);

    //float d = sdBox(_p, size);
    float d = sdRoundBox(_p, size, size.x * 0.15);

    for (int i = 0; i < 8; i++) {
        vec3 q = _p;
        
        q.x = abs(q.x);
        q.y -= size.y * _BranchPos;
        q.yz = q.yz * rot(0.4 + sin(time * 0.123) * 0.1 - clamp(float(i) - 2.0, 0.0, 10.0) * 0.2);
        q.xy = q.xy * rot(_AngleAmount);
        
        //d = min(d, sdBox(q, size));
        d = min(d, sdRoundBox(q, size, size.x * 0.15));
        
        _p = q;
        size *= scale;
        size.x *= _WidthDecay;
        //size *= vec3(_BranchAmount, 1.0, _BranchAmount);
    }
    return d;
}

float Branch2(vec3 p) {
    float scale = _BranchAmount;
    float width = _WidthAmount * scale;
    vec3 size = vec3(width, _LengthAmount, width / 10.0) * _ScaleAmount;
    
    vec3 _p = p;
    _p.xz = _p.xz * rot(0.2);
    _p.yz = _p.yz *  rot(0.5);
    _p.xy = _p.xy * rot(sin((time+210.0)*0.078 * _AnimAmount) * 0.2);

    //float d = sdBox(_p, size);
    float d = sdRoundBox(_p, size, size.x * 0.15);
    
    for (int i = 0; i < 8; i++) {
        vec3 q = _p;
        q.x = abs(q.x);
        q.y -= size.y * _BranchPos;
        q.yz = q.yz * rot(0.4 + sin((time+3.0) * 0.123) * 0.1 - clamp(float(i) - 1.0, 0.0, 10.0) * 0.125);
        q.xy = q.xy * rot(_AngleAmount);
        
        //d = min(d, sdBox(q, size));
        d = min(d, sdRoundBox(q, size, size.x * 0.15));
        
        _p = q;
        size *= scale;
        size.x *= _WidthDecay;
    }
    return d;
}

float dRose(vec3 p) {
    vec3 _p = p;
    _p -= vec3(0.0, -0.5, 0.0) * _ScaleAmount + vec3(0.0, 0.0, time+3.0);
    _p.xz = _p.xz * rot(-time * 0.012 * _AnimAmount);
    _p.yz = _p.yz * rot(-PI*0.5);
    _p.xy = pmod(vec2(_p.x,_p.y), _PolerAmount);
    return Branch(_p);
}

float dRose2(vec3 p) {
    vec3 _p = (p - vec3(0.0, 0.0, time+3.0)) * 0.8;
    _p -= vec3(0.0, -0.5, 0.0) * _ScaleAmount;

    _p.xz = _p.xz * rot(time * 0.016 * _AnimAmount);
    _p.yz = _p.yz * rot(-PI*0.5);
    _p.xy = pmod(vec2(_p.x,_p.y), _PolerAmount);
    return Branch2(_p);
}

float sdPointLight(vec3 p, vec3 lightPos){
    float d = FAR;
    vec3 _p = p;
        _p.xy *= rot(time*0.25);
        d = min(d, sdSphere(_p - lightPos, 0.02));
        _p.xz *= rot(120.0*PI/180.0);
        d = min(d, sdSphere(_p - lightPos, 0.02));
        _p.xz *= rot(120.0*PI/180.0);
        d = min(d, sdSphere(_p - lightPos, 0.02));
    return d;
}

float map(vec3 p){
    float d = FAR;
    
    // 左右壁
    //d = min(d, abs(p.x + 1.5) - 0.1);
    //d = min(d, abs(1.5 - p.x) - 0.1);
    // 天井
    d = min(d, 2.0 - p.y);
    // 天井凹み
    //d = max(d, -sdBarZ(p - vec3(0.0, 2.0, 0.0), vec2(1.0, 0.2)));
    //d = max(d, -sdInfinityDoor(p - vec3(0.0, 0.8, 0.0), 0.4, 1.5));
    //d = min(d, sdInfinityPole(p - vec3(-1.2, 0.0, 0.0 + 0.75), 0.1, 1.5));
    //d = min(d, sdInfinityPole(p - vec3(1.2, 0.0, 0.0 + 0.75), 0.1, 1.5));
    
    // タイル地面
    d = min(d, sdTiledFloor(p - vec3(0.0, -1.0, 0.0), 0.3));
    
    //d = min(d, dSnowCrystal(p));
    d = min(d, dRose(p));
    d = min(d, dRose2(p));
    float _halfSphere = max(sdSphere(p - vec3(0.0, -0.35, 0.0) * _ScaleAmount - vec3(0.0,0.0,time+3.0), 0.25 * _ScaleAmount), p.y - (-0.4 * _ScaleAmount)); 
    d = smin(d, _halfSphere, 0.1);

    // 水
    float _water = max(sdPlane(p - vec3(0.0, 1.4, 0.0), sin(-time*10.0+length(p - vec3(0.0, 0.0, time + 3.0))*50.0) * 0.005 - 1.5), sdSphere(p - vec3(0.0, 0.2, time + 3.0), 0.5));
    d = min(d, _water);
    // 水滴
    d = blob2(d, sdSphere(p - vec3(0.0, mod(-time*0.5, 4.0) - 2.0, time + 3.0), -length(mod(-time*0.5, 4.0) - 2.0) * 0.1 + 0.1), 15.0);
    return d;
}

vec3 calcN(vec3 p){
    vec2 e =vec2(EPS, 0.0);
    vec3 n = normalize(vec3(
        map(p+e.xyy)-map(p-e.xyy),
        map(p+e.yxy)-map(p-e.yxy),
        map(p+e.yyx)-map(p-e.yyx)
        ));
    return n;
}

float calcAO(vec3 p, vec3 n, float len, float power){
    vec3 aoPos = p;
    float occ = 0.0;
    for(int i = 0; i < 3; i++){
        aoPos = p + n * len / 3.0 * float(i+1);
        float d = map(aoPos);
        occ += (len - d) * power;
        power *= 0.5;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

float calcBloom(vec3 cam, vec3 ray, float endDepth){
    float bloom = 0.0;
    float depth = 0.0;
    for(int i = 0; i < RAY_ITER; i++){
        vec3 p = cam + ray * depth;
        
        // 浮遊光
        float d;
        d = sdPointLight(p - vec3(0.0, 0.6, 3.0 + time), vec3(sin(time) * 0.23, sin(time*2.0) * 0.14, cos(time) * 0.34));
        
        p.z = mod(p.z, 4.0) - 2.0;
        d = min(d, sdSphere(p - vec3(0.0, 2.0, 0.0), 0.05));
        bloom += exp(-d*0.25);
        if(depth > endDepth) break;
        depth += d;
    }
    return bloom / float(RAY_ITER);
}

vec3 draw(vec3 camPos, vec3 rayDirection, out vec3 rayPos, out vec3 normal, out bool hit){
    vec3 col = vec3(0.0);
    float depth = 0.0;
    float dist;
    for(int i = 0; i < RAY_ITER; i++){
        rayPos = camPos + rayDirection * depth;
        dist = map(rayPos);
        if(depth > FAR || dist < EPS){
            normal = calcN(rayPos);
            break;
        }
        depth += dist;
    }

    col = vec3(1.0) / 2.0;
    //col = hsv(depth / 5.0, 1.0, 1.0);
    
    // リムライト
    float distAmount = smoothstep(FAR, EPS, depth);
    col += pow(1.0 - dot(normal, -rayDirection), 1.0) * vec3(0.5, 0.5, 1.0) * distAmount;//hsv(time * 0.2, 1.0, 0.2)
    //col += pow(1.0 - dot(normal, -rayDirection), 0.5) * vec3(0.2, 0.2, 1.0) * hsv(time * 0.2, 1.0, 0.2);
    
    col *= max(dot(normal, vec3(1.0, 1.0, 1.0) * 1.0), 0.5);
    col *= max(depth / FAR, 0.1);
    col *= calcAO(rayPos, normal, 0.5, 1.0);
    
    col += vec3(1.0, 0.5, 0.7) * calcBloom(camPos, rayDirection, depth) * 5.0;
    
    hit = dist < EPS;
    return col;
}

vec3 canvas(vec2 uv){
    vec3 col = vec3(0.0);
    vec3 normal = vec3(0.0);
    vec3 camPos = vec3(cos(time / 2.0) * 0.1, sin(time / 3.0) * 0.1 + 0.75, time + 1.0);
    vec3 rayDirection = normalize(vec3(uv.x, uv.y - 0.5 + sin(time / 5.0) * 0.2, 1.0));
    vec3 rayPos = camPos;
    float depth = 0.0;
    bool hit = false;
    float alpha = 1.0;
    vec3 reflectColor = vec3(1.2, 0.8, 1.0);
    for(int i = 0; i < REFLECT_ITER; i++){
        col += draw(camPos, rayDirection, rayPos, normal, hit) * reflectColor;
        rayDirection = normalize(reflect(rayDirection, normal));
        camPos = rayPos + normal * EPS;
        //alpha *= 0.8;
        if(!hit)break;
    }
    return col;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col;
    col = canvas(uv);
    glFragColor = vec4(col, 1.0);
}

