#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) { 
    const vec2  C = vec2(1.0/6.0, 1.0/3.0);
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx);

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );

    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

    // Permutations
    i = mod289(i); 
    vec4 p = permute( permute( permute( 
    i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
    + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    float req = 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
    dot(p2,x2), dot(p3,x3) ) );
    req = clamp(req, -1.0, 1.0);
    return req;
}

const int  oct  = 4;
float octaves(vec3 v, float p){
    float req = 0.0;
    for(int i = 0; i < oct; i++){
        float freq = pow(p, float(i));
        float amp  = pow(p, float(-i));
        req += snoise(v * freq) * amp;
    }
    req = clamp(req, -1.0, 1.0);
    return req;
}

float sigmoid1(float x, float a){
    float ex = exp(-2.0 * a * x);
    return (1.0 - ex) / (1.0 + ex);
}

vec3 grain1(vec3 v, float n){
    float l, w, r, m;
    l = length(v.xy);
    l = pow(l, 2.0);
    l += octaves(v  * n *  vec3(0.014, 0.014, 0.0042), 2.3) * 1.6;
    w =cos(2.0 * PI * l * 8.0);
    w = sigmoid1(w + 0.85, 3.0);
    r = snoise(v * vec3(160.0, 160.0, 6.5)) + 0.5;
    float p = 0.6;
    m = w * p + r * (1.0 - p);
    m = (m + 1.0) / 2.0;
    // 色付け
    vec3 col1 =  vec3(243, 204, 163);
    vec3 col2 = vec3(229, 164, 108);
    vec3 col = (col1 * m + col2 * (1.0 - m)) / 255.0;
    col += octaves(v * vec3(1.0, 1.0, 0.2), 2.3) * 0.05;
    col = clamp(col, 0.0, 1.0);
    return col;
}

vec3 grain2(vec2 v){
    vec3 pos = vec3(
        0.6,
        ((v.y * 2.0) - 1.0),
        (v.x + 10.0) * 2.0
    );
    return grain1(pos, 6.0);
}

vec3 tile(vec2 uv, vec2 div){
    vec2 req_uv = fract(uv * div);
    float index = 
        floor(uv.x * div.x) + 
        floor(uv.y * div.y) * ceil(div.x);
    return vec3(req_uv, index);
}

float tileSize(vec2 div){
    if (ceil(div.x) * ceil(div.y) < 1.0) return 1.0;
    return ceil(div.x) * ceil(div.y);
}

float checkered(vec2 v, vec2 div){
    v *= div;
    float req = 1.0;
    req *= 2.0 * (floor((v.x + 1.0) / 2.0) - floor(v.x / 2.0)) - 1.0;
    req *= 2.0 * (floor((v.y + 1.0) / 2.0) - floor(v.y / 2.0)) - 1.0;
    req = (req + 1.0) / 2.0;
    return req;
}

vec2 rotate(vec2 v, vec2 c, float r){
    v -= c;
    v = vec2(
        cos(r) * v.x - sin(r) * v.y,
        sin(r) * v.x + cos(r) * v.y
    );
    v += c;
    return v;
}

float frame(vec2 v, vec2 w) {
    return (
        0.0 <= v.x - w.x && v.x + w.x <= 1.0 &&
        0.0 <= v.y - w.y && v.y + w.y <= 1.0
    )?1.0:0.74;
}

vec2 rotate(vec2 uv, float theta){
    return uv * mat2(
        cos(theta), sin(theta),
        -sin(theta), cos(theta)
    );
}

vec2 koi(){
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float t = 0.1 * time * 2.0 * PI;
    uv -= vec2(0.5, 2.1 - cos(t) * 1.1);
    uv *= vec2(1.0, resolution.y / resolution.x);
    uv = rotate(uv, sin(t) * 0.3);
    uv.y = (0.5 - cos(t) * 0.3) / uv.y; uv.x *= uv.y;
    uv.y += (0.35 + cos(t) * 0.1) * (resolution.x / resolution.y);
    uv = rotate(uv, t);
    return uv * (1.0 + 3.0 * smoothstep(-0.2, 0.2, cos(0.5 * t)));
}

void main( void ) {
    vec2 p = koi();
    if (length(p) > 5.0) {
        glFragColor = vec4(1.0);
        return;
    }
    vec2 div1 = vec2(4.0);
    vec2 div2 = vec2(1.0, 4.0);
    vec2 uv = p;
    vec3 buf1 = tile(uv, div1);
    float buf2 = 1.0 - checkered(uv, div1);
    uv = rotate(buf1.xy, vec2(0.5), 0.5 * PI * buf2);
    vec3 buf3 = tile(uv, div2);
    uv = buf3.xy;
    float index = buf1.z * tileSize(div2) + buf3.z;
    float size = tileSize(div1) * tileSize(div2) - 1.0;
    vec2 uv2 = uv * vec2(2.0, 0.6);
    float offset = index * size * 100.0;
    vec3 col = grain2(uv2 + vec2(offset, snoise(vec3(offset)) * 0.3));
    col += vec3(199.0, 173.0, 122.0) * (snoise(vec3(offset)) * 0.14 + 0.1) / 255.0;
    col *= frame(uv, div2 * 0.004);
    glFragColor = vec4( col, 1.0 );
}
