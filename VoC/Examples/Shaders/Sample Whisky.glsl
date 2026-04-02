#version 420

// original https://neort.io/art/c01asdc3p9f30ks58h10

#define PI 3.14159265359
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
float gTime = 0.0;

const float REPEAT = 15.0;
const float fluid_speed     = 108.0;  // Drives speed, higher number will make it slower.
const float color_intensity = 0.4;
// 回転行列
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

// 円周率
const float pi = acos(-1.0);
const float pi2 = pi*2.;

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float quarticInOut(float t) {
  // tが0.5未満ならtの4乗
  // tが0.5以上なら-tの4乗 + 1.
  // 渡す t は t < 1.0 のようなので乗数が大きいほど真ん中に収束する
  return t < 0.5
    ? +8.0 * pow(t, 4.0)
    : -8.0 * pow(t - 1.0, 4.0) + 1.0;
}

float squareicInOut(float t) {
  // tが0.5未満ならtの4乗
  // tが0.5以上なら-tの4乗 + 1.
  // 渡す t は t < 1.0 のようなので乗数が大きいほど真ん中に収束する
    return 1.0 * pow(t, 4.0);
}

// 適当な数をかけた結果にfractで小数点以下の値を返している。
// https://nogson2.hatenablog.com/entry/2017/11/11/125251
vec2 random2(float x) {
  return fract(sin(x * vec2(12.9898, 51.431)) * vec2(143758.5453, 71932.1354));
}

// random2で帰ってきた小数点を2倍して引いている
// 引いているのは座標調整のマジックナンバーっぽい
vec2 srandom2(float x) {
  return 2.0 * random2(x) - 1.0;
}

// noise logic is stolen from.
// https://www.shadertoy.com/view/WdXGRj
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
        mix(mix( hash(n+113.0), hash(n+114.0),f.x),
        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);

    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;
    f += 0.06250*noise( p );
    return f;
}

float map(vec3 pos, float time, float repeatation) {
    vec3 q = pos - vec3(0.0,0.5,1.0)*time;
    float f = fbm(q);
    
    pos = pos * f * 1.2;
    
    vec3 pos_origin  = pos;
    pos.xy = pos_origin.xy;
    
    float rep = floor(time / REPEAT );
    vec2 offset1 = .1 * srandom2(1.91 + rep * 0.241);
    vec2 offset2 = .6 * srandom2(12.91 + rep * 0.341);
    vec2 offset3 = .8 * srandom2(21.91 + rep * 0.441);
    vec2 offset4 = 1.2 * srandom2(41.91 + rep * 0.541);

    vec2 test = 1. * srandom2(time + 99.46);
    pos.xy = pos.xy + ( smoothstep(0.0,.2,repeatation) - smoothstep(0.2,1.,repeatation))* offset1;
    float side1 = sdSphere(pos, .05);
    pos.xy = pos_origin.xy;
    pos.xy = pos.xy + ( smoothstep(0.0,.2,repeatation) - smoothstep(0.2,1.,repeatation))* offset2;
    float side2 = sdSphere(pos, .05);
    pos.xy = pos_origin.xy;
    pos.xy = pos.xy + ( smoothstep(0.0,.2,repeatation) - smoothstep(0.2,1.,repeatation))* offset3;
    float side3 = sdSphere(pos, .05);
    pos.xy = pos_origin.xy;
    pos.xy = pos.xy + ( smoothstep(0.0,.2,repeatation) - smoothstep(0.2,1.,repeatation))* offset4;
    float side4 = sdSphere(pos, .05);

    return min(min(min(side1,side2),side3), side4) * 1.;

}

void main( void ) {
    vec2 p = (gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y);
    vec3 ro = vec3(1.5, 1. , 0. + time * 3.);
    vec3 ray = normalize(vec3(p, 3.));
    float repeatation = mod(time, REPEAT) / REPEAT ;
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    ray.xy = ray.xy * rot(sin(time * .1) * .25);
    ray.yz = ray.yz * rot(sin(time * .1) * .4);

    
    float t = 5. ;
    vec3 col =  mix(vec3(0.2, 0.2, 0.6), vec3(1., 0.52, 0.), (uv.y + 0.2) * 1.0 );
    float ac = 0.0;

    for (int i = 0; i < 99; i++){
        vec3 pos = ro + ray * t;
        pos = mod(pos -2., 4.) -2.;
        gTime = sin(time) - float(i) * 0.0000001;

        
        vec3 pos_origin  = pos;
        pos.xy = pos_origin.xy;
        vec2 test = .2 * srandom2(time + 99.46);
        
        float rep = floor(time  / REPEAT );
        

        
        vec2 inoffset = vec2(pos.xy);
        vec2 coffset = .2 * srandom2(99.46 + rep * 0.145);
        vec2 roffset = .3 * srandom2(103.35 + rep * 0.432);
        vec2 toffset = .25 * srandom2(121.91 + rep * 0.241);
        vec2 outoffset = .1 * srandom2(85.38 + rep * 0.198);
        vec2 lastoffset = vec2(pos.xy);
        
        vec2 offset;
        
        offset = mix(inoffset, coffset, squareicInOut(smoothstep(0.0, 0.2, repeatation))) ;
        offset = mix(offset, roffset, squareicInOut(smoothstep(0.2, 0.4, repeatation)));
        offset = mix(offset, toffset, squareicInOut(smoothstep(0.4, 0.6, repeatation)));
        offset = mix(offset, outoffset, squareicInOut(smoothstep(0.6, 0.8, repeatation)));
        offset = mix(offset, lastoffset, squareicInOut(smoothstep(0.8, 1.0, repeatation)));
        
        float d = map(pos ,time, repeatation);

        // オブジェクト透過処理
        // 最短距離の絶対値を取り、進む距離が絶対に0にならないようにする。
        // 今回だとmaxで0.02以下にならないようにすることで、レイがオブジェクトを突き抜けてforループが終わるまで進み続ける。
        d = max(abs(d), 0.001);
        // 距離を適当な指数関数で減衰した値を密度としたボリューム累積
        ac += exp(-d*3.);

        t += d* 0.15;
    }
    
    for(int i=1;i<40;i++)
    {
        vec2 newp=p + time*0.005;
        newp.x+=0.9/float(i)*sin(float(i)*p.y+time/fluid_speed+0.3*float(i)) + sin(time)* 0.01; // + mouse.y/mouse_factor+mouse_offset;
        newp.y+=0.5/float(i)*sin(float(i)*p.x+time/fluid_speed+0.3*float(i+10) + sin(time)* 0.01); // - mouse.x/mouse_factor+mouse_offset;
        p=newp;
    }
    
    col += vec3(ac * 0.04);

    glFragColor = vec4(col ,1.0);
}
