#version 420

// original https://www.shadertoy.com/view/4sdBWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define nnnn vec4(0.0, 0.0, 0.0, 0.0)
#define nnnp vec4(0.0, 0.0, 0.0, 1.0)
#define nnpn vec4(0.0, 0.0, 1.0, 0.0)
#define nnpp vec4(0.0, 0.0, 1.0, 1.0)
#define npnn vec4(0.0, 1.0, 0.0, 0.0)
#define npnp vec4(0.0, 1.0, 0.0, 1.0)
#define nppn vec4(0.0, 1.0, 1.0, 0.0)
#define nppp vec4(0.0, 1.0, 1.0, 1.0)
#define pnnn vec4(1.0, 0.0, 0.0, 0.0)
#define pnnp vec4(1.0, 0.0, 0.0, 1.0)
#define pnpn vec4(1.0, 0.0, 1.0, 0.0)
#define pnpp vec4(1.0, 0.0, 1.0, 1.0)
#define ppnn vec4(1.0, 1.0, 0.0, 0.0)
#define ppnp vec4(1.0, 1.0, 0.0, 1.0)
#define pppn vec4(1.0, 1.0, 1.0, 0.0)
#define pppp vec4(1.0, 1.0, 1.0, 1.0)
float Dot(vec2 a, vec4 b) {
    return dot(a, b.xy);
}
float Dot(vec3 a, vec4 b) {
    return dot(a, b.xyz);
}
float rand(float f, float o, float r, vec4 ss) {
  return o + r * fract(sin(f * ss.x + ss.y) * ss.z + ss.z);
}
vec2 rand2(vec2 v, float o, float r, mat4 d, vec4 s) {
    return vec2(
        rand(Dot(v, d[0]), o, r, s),
        rand(Dot(v, d[1]), o, r, s)
    );
}
vec3 rand3(vec3 v, float o, float r, mat4 d, vec4 s) {
    return vec3(
        rand(Dot(v, d[0]), o, r, s),
        rand(Dot(v, d[1]), o, r, s),
        rand(Dot(v, d[2]), o, r, s)
    );
}
vec4 rand4(vec4 v, float o, float r, mat4 d, vec4 s) {
    return vec4(
        rand(dot(v, d[0]), o, r, s),
        rand(dot(v, d[1]), o, r, s),
        rand(dot(v, d[2]), o, r, s),
        rand(dot(v, d[3]), o, r, s)
    );
}
vec4 rand4Rot(vec4 v, mat4 ds, vec4 ss) {
    v = rand4(vec4(
        dot(v, ds[0]),
        dot(v, ds[1]),
        dot(v, ds[2]),
        dot(v, ds[3])
    ), 0.0, 2.0 * 3.14159265358, ds, ss);
  return mat4(
            1.0,       0.0,       0.0,       0.0,
            0.0,  cos(v.x), -sin(v.x),       0.0,
            0.0,  sin(v.x),  cos(v.x),       0.0,
            0.0,       0.0,       0.0,       1.0
  ) * mat4(
            1.0,       0.0,       0.0,       0.0,
            0.0,       1.0,       0.0,       0.0,
            0.0,       0.0,  cos(v.y), -sin(v.y),
            0.0,       0.0,  sin(v.y),  cos(v.y)
  ) * mat4(
       cos(v.z),       0.0,       0.0,  sin(v.z),
            0.0,       1.0,       0.0,       0.0,
            0.0,       0.0,       1.0,       0.0,
      -sin(v.z),       0.0,       0.0,  cos(v.z)
  ) * mat4(
       cos(v.w), -sin(v.w),       0.0,       0.0,
       sin(v.w),  cos(v.w),       0.0,       0.0,
            0.0,       0.0,       1.0,       0.0,
            0.0,       0.0,       0.0,       1.0
  ) * vec4(1.0, 0.0, 0.0, 0.0);
}
mat4 rand44(mat4 m, float o, float r, mat4 d, mat4 s) {
    return mat4(
        vec4(
            rand(dot(m[0], d[0].xyzw), o, r, s[0]),
            rand(dot(m[0], d[1].xyzw), o, r, s[1]),
            rand(dot(m[0], d[2].xyzw), o, r, s[2]),
            rand(dot(m[0], d[3].xyzw), o, r, s[3])
        ),
        vec4(
            rand(dot(m[1], d[0].yzwx), o, r, s[0]),
            rand(dot(m[1], d[1].yzwx), o, r, s[1]),
            rand(dot(m[1], d[2].yzwx), o, r, s[2]),
            rand(dot(m[1], d[3].yzwx), o, r, s[3])
        ),
        vec4(
            rand(dot(m[1], d[0].zwxy), o, r, s[0]),
            rand(dot(m[1], d[1].zwxy), o, r, s[1]),
            rand(dot(m[1], d[2].zwxy), o, r, s[2]),
            rand(dot(m[1], d[3].zwxy), o, r, s[3])
        ),
        vec4(
            rand(dot(m[1], d[0].wxyz), o, r, s[0]),
            rand(dot(m[1], d[1].wxyz), o, r, s[1]),
            rand(dot(m[1], d[2].wxyz), o, r, s[2]),
            rand(dot(m[1], d[3].wxyz), o, r, s[3])
        )
    );
}
float mix1(float x, float y, float a) {
  return (1.0 - a) * x + a * y;
}
vec2 mix1(vec2 x, vec2 y, float a) {
  return (1.0 - a) * x + a * y;
}
vec3 mix1(vec3 x, vec3 y, float a) {
  return (1.0 - a) * x + a * y;
}
vec4 mix1(vec4 x, vec4 y, float a) {
  return (1.0 - a) * x + a * y;
}
float curve5(float a) {
  return a * a * a * (a * (6.0 * a - 15.0) + 10.0);
}
vec2 curve5(vec2 a) {
  return a * a * a * (a * (6.0 * a - 15.0) + 10.0);
}
vec4 curve5(vec4 a) {
  return a * a * a * (a * (6.0 * a - 15.0) + 10.0);
}
float mix5(float x, float y, float a) {
  return mix1(x, y, curve5(a));
}
vec2 mix5(vec2 x, vec2 y, float a) {
  return mix1(x, y, curve5(a));
}
vec3 mix5(vec3 x, vec3 y, float a) {
  return mix1(x, y, curve5(a));
}
vec4 mix5(vec4 x, vec4 y, float a) {
  return mix1(x, y, curve5(a));
}
float perlinGradient(vec4 pos, mat4 ds, vec4 ss) {
    vec4 f = fract(pos);
    vec4 b = floor(pos);
    vec4 z0 = mix5(vec4(
        dot(rand4Rot(b, ds, ss), f),
        dot(rand4Rot(b + npnn, ds, ss), f - npnn),
        dot(rand4Rot(b + pnnn, ds, ss), f - pnnn),
        dot(rand4Rot(b + ppnn, ds, ss), f - ppnn)
    ), vec4(
        dot(rand4Rot(b + nnnp, ds, ss), f - nnnp),
        dot(rand4Rot(b + npnp, ds, ss), f - npnp),
        dot(rand4Rot(b + pnnp, ds, ss), f - pnnp),
        dot(rand4Rot(b + ppnp, ds, ss), f - ppnp)
    ), f.w);
    vec4 z1 = mix5(vec4(
        dot(rand4Rot(b + nnpn, ds, ss), f - nnpn),
        dot(rand4Rot(b + nppn, ds, ss), f - nppn),
        dot(rand4Rot(b + pnpn, ds, ss), f - pnpn),
        dot(rand4Rot(b + pppn, ds, ss), f - pppn)
    ), vec4(
        dot(rand4Rot(b + nnpp, ds, ss), f - nnpp),
        dot(rand4Rot(b + nppp, ds, ss), f - nppp),
        dot(rand4Rot(b + pnpp, ds, ss), f - pnpp),
        dot(rand4Rot(b + 1.0, ds, ss), f - 1.0)
    ), f.w);
    vec4 z = mix5(z0, z1, f.z);
    vec2 y = mix5(z.xz, z.yw, f.y);
    return mix5(y.x, y.y, f.x);
}
float fractalNoise(vec4 p, mat4 ds,  vec4 ss) {
    float value = 0.0;
    float res = 2.0;
    float scale = 1.0;
    float scaleStep = 2.0;
    vec4 f = ss;
    for(int i = 0; i < 3; i++) {
        f = rand4(f, 12345.6789012, 32109.8765432, ds, ss);
        value += 3.0 * perlinGradient(vec4(p.xyz / res, p.w), ds, f) / scale;
        scale = scale * scaleStep;
        res = res / scaleStep;
    }
    float range = 0.75 / 2.0;
    return value * range + range;
}
float Min(inout vec4 M, float m) {
    float t;
    for(int i = 0; i < 4; i++)
        if(m < M[i]) {
            t = m;
            m = M[i];
            M[i] = t;
        }
    return m;
}
float evoronoi( in vec2 x, vec4 c, /*float scale, */mat4 d, mat4 s ) {
    float fallout = 64.0;
    vec2 p = floor( x.xy );
    vec2 f = fract( x.xy );
    //mat4 s1 = rand44(s, 12345.6789012, 32109.8765432, d, s);
    //mat4 d1 = rand44(d, 12.3456789012, 32.1098765432, d, s);
    //mat4 d2 = rand44(d, 12.3456789012, 32.1098765432, d, s);
    //mat4 d3 = rand44(d2, 12.3456789012, 32.1098765432, d, s);

    //*
    float res = 1.0e20;
    //vec4 res = 1.0e20;
    const float range = 1.0;
    for( float j=-range; j<=range; j++ )
    for( float i=-range; i<=range; i++ )
    {
        vec2 b = vec2( i, j );
        /*
        vec3  r = b - f + vec3(
            mix(0.0, 1.0, fractalNoise(vec4((p + b) * scale, x.w), d, s[0])),
            mix(0.0, 1.0, fractalNoise(vec4((p + b) * scale, x.w), d2, s[1])),
            mix(0.0, 1.0, fractalNoise(vec4((p + b) * scale, x.w), d3, s[1]))
        );
        //*/
        vec2 r = b - f + rand2( p + b, 0.0, 1.0, d, s[0] );
        float dis = length( r );

        //res += exp( -fallout*dis );
        res = min(res, dis);
        //Min(res, dis);
        //s1 = rand44(s1, 12345.6789012, 32109.8765432, d, s);
        //d1 = rand44(d1, 12.3456789012, 32.1098765432, d, s);
        //d2 = rand44(d2, 12.3456789012, 32.1098765432, d, s);
    }
    //return -1.125*(1.0/fallout)*log( res );
    return res;
    //*/
    //return fractalNoise(vec3(p, x.z), 16.0, 1.0, 2.0, vec3(0.0), d, s[0]);
}
float evoronoi( in vec3 x, vec4 c, /*float scale, */mat4 d, mat4 s ) {
    float fallout = 64.0;
    vec3 p = floor( x.xyz );
    vec3 f = fract( x.xyz );
    //mat4 s1 = rand44(s, 12345.6789012, 32109.8765432, d, s);
    //mat4 d1 = rand44(d, 12.3456789012, 32.1098765432, d, s);
    //mat4 d2 = rand44(d, 12.3456789012, 32.1098765432, d, s);
    //mat4 d3 = rand44(d2, 12.3456789012, 32.1098765432, d, s);

    //*
    //float res = 0.0;
    //float res = 1.0e20;
    vec4 res = vec4(1.0e20);
    const float range = 1.0;
    for( float k=-range; k<=range; k++ )
    for( float j=-range; j<=range; j++ )
    for( float i=-range; i<=range; i++ )
    {
        vec3 b = vec3( i, j, k );
        /*
        vec3  r = b - f + vec3(
            mix(0.0, 1.0, fractalNoise(vec4((p + b) * scale, x.w), d, s[0])),
            mix(0.0, 1.0, fractalNoise(vec4((p + b) * scale, x.w), d2, s[1])),
            mix(0.0, 1.0, fractalNoise(vec4((p + b) * scale, x.w), d3, s[1]))
        );
        //*/
        vec3 r = b - f + rand3( p + b, 0.0, 1.0, d, s[0] );
        float dis = length( r );

        //res += exp( -fallout*dis );
        //res = min(res, dis);
        Min(res, dis);
        //s1 = rand44(s1, 12345.6789012, 32109.8765432, d, s);
        //d1 = rand44(d1, 12.3456789012, 32.1098765432, d, s);
        //d2 = rand44(d2, 12.3456789012, 32.1098765432, d, s);
    }
    //return -1.125*(1.0/fallout)*log( res );
    //return res;
    return dot(res, c);
    //*/
    //return fractalNoise(vec3(p, x.z), 16.0, 1.0, 2.0, vec3(0.0), d, s[0]);
}
float fractalCell(vec3 p, vec4 c, mat4 ds,  mat4 ss) {
    float value = 0.0;
    float a = 1.0;
    float aStep = 0.5;
    float pStep = 2.0;
    float tStep = 1.5;
    vec3 t = vec3(0.0, 0.0, p.z+time*0.5);
    mat4 f = ss;
    const int steps = 5;
    for(int i = 0; i < steps; i++) {
        f = rand44(f, 12345.6789012, 32109.8765432, ds, ss);
        value += evoronoi(p + t, c, ds, f) * a;
        a *= aStep;
        p *= pStep;
        t *= tStep;
    }
    float r = aStep;
    float sum = (1.0 - pow(r, float(steps))) / (1.0 - r);
    return mix(0.0, 1.0, value / sum);
}
vec3 firePalette(float i){

    float T = 1400. + 1300.*i; // Temperature range (in Kelvin).
    vec3 L = vec3(7.4, 5.6, 4.4); // Red, green, blue wavelengths (in hundreds of nanometers).
    L = pow(L,vec3(5.0)) * (exp(1.43876719683e5/(T*L))-1.0);
    return 1.0-exp(-5e8/L); // Exposure level. Set to "50." For "70," change the "5" to a "7," etc.
}
void main(void)
{
    mat4 dotseed = mat4(
        84.4239141, 72.1623789, 54.2539214, 94.8233014,
        45.8097063, 19.6603408, 41.9881591, 17.7513314,
        70.6492482, 72.8228071, 31.9941736, 29.7793959,
        68.9614210, 33.3000043, 38.8602285, 67.0907920
    );
    mat4 sineseed = mat4(
        8442.39141, 7216.23789, 5425.39214, 9482.33014,
        4580.97063, 1966.03408, 4198.81591, 1775.13314,
        7064.92482, 7282.28071, 3199.41736, 2977.93959,
        6896.14210, 3330.00043, 3886.02285, 6709.07920
    );
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    //uv += vec2(sin(time*0.5)*0.25, cos(time*0.5)*0.125);
    //float cs = cos(time*0.25), si = sin(time*0.25);
    //uv = uv*mat2(cs, -si, si, cs); 
    vec3 uvw = vec3(uv * 2.0, 3.1415926535898/8.0);
    vec4 uvwx = vec4(uv, 0.0, time);

    vec4 coeffs = vec4(1.0, 0.0, 0.0, 0.0);
    coeffs = vec4(0.0, 1.0, 0.0, 0.0);
    //coeffs = vec4(0.0, 0.0, 1.0, 0.0);
    //coeffs = vec4(0.0, 0.0, 0.0, 1.0);
    //coeffs = vec4(-1.0, 1.0, 0.0, 0.0);
    float c = pow(fractalCell(uvw, coeffs, dotseed, sineseed), 2.0);
    c = max(c + dot(rand3(uvw, 0.0, 1.0, dotseed, sineseed[0])*2.-1., vec3(0.015)), 0.);
    c *= sqrt(c)*1.5;
    
    vec3 col = firePalette(c);
    col = mix(
        col,
        col.zyx*0.15+c*0.85,
        min(pow(dot(uv, uv)*1.2, 0.75), 1.)
    );
    col = pow(col, vec3(1.5));
    
    glFragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.);
    //glFragColor = vec4(sqrt(vec3(clamp(c, 0., 1.))), 1.);
}
