#version 420

// original https://www.shadertoy.com/view/3sSyR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ZzArt - Generation: 112-E (1574121639091)

const float PI=3.141592653589793;
vec3 SmoothHSV(vec3 c) { vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1.,0.,1.); return c.z * mix( vec3(1), rgb*rgb*(3.-2.*rgb), c.y); }
vec4 lengthA(vec4 a)      { return vec4(length(a)); }
vec4 asinA(vec4 a)        { return asin(clamp(a,-1.,1.)); }
vec4 acosA(vec4 a)        { return acos(clamp(a,-1.,1.)); }
vec4 logA(vec4 a)         { return log(abs(a)); }
vec4 log2A(vec4 a)        { return log2(abs(a)); }
vec4 sqrtA(vec4 a)        { return sqrt(abs(a)); }
vec4 inversesqrtA(vec4 a) { return inversesqrt(abs(a)); }
vec4 pow2(vec4 a)         { return a*a; }
vec4 pow3(vec4 a)         { return a*a*a; }

void main(void)
{
vec2 p=gl_FragCoord.xy;
vec4 a=glFragColor;

a=p.xyxy/resolution.xyxy;
a.xywz *= vec2(2.279, 3.527).xyxy;
a.xywz += vec2(-4.296, -7.673).xyxy;
vec4 b = a;

// Generated Code - Line Count: 14
b.xywz *= (b).zxwz;
a.wzyx = cos(b+time).xyww;
a.yzxw -= exp2(a).yxwy;
b.xwzy = (a).wyzy;
b.xywz += (b).wwxz;
b.xwzy /= sign(b).yyyy;
a.xwzy /= fract(vec4(-1.035, -4.122, 0.418, -0.302)).zzyz;
a.wyxz /= (a).xzxx;
a.yxzw -= log2(b).wwxx;
a.yzwx -= normalize(b).xywy;
a.zwyx += (b).wwzz;

// Smooth HSV by iq
a.x = a.x * -0.150+0.618;
a.y *= 0.124;
a.xyz = SmoothHSV(a.xyz);

glFragColor=a;
}
