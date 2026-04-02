#version 420

// original https://www.shadertoy.com/view/WdKfD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TAU = 6.2831853071;
const float N = 10.;

float cnoise(vec2 P);

float distBand(float R1, float R2, float r) {
    return (R2-R1)*0.5 - abs(r - (R1+R2)*0.5);
}

float crest(float a, float r) {
    return 5. * distBand(a*0.5, a, r);
}

vec2 rotate(float a, vec2 uv) {
    float c = cos(a);
    float s = sin(a);
    return vec2(
        c * uv.x - s * uv.y,
        s * uv.x + c * uv.y
    );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    uv *= 0.5;
    uv = rotate(time*0.7, uv);
    uv += 0.005*cnoise(uv*200.);
    //uv = rotate(time*0.25, uv);
    float mask = 0.;
    // Main spirals
    float a = fract(0.5 - atan(uv.y, uv.x) / TAU);
    float r = 1.5*length(uv)-0.23;
    for (float i = 0.; i < N; ++i) {
        mask += max(crest(fract(a + i/N), r), 0.);
    }

    // Output to screen
    vec3 col = mix(vec3(1, 45, 64)*0.3, vec3(166, 228, 255)*3., mask) / 255.;
    glFragColor = vec4(col,1.0);
}

//    Classic Perlin 2D Noise 
//    by Stefan Gustavson
// Thanks to https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}

float cnoise(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}
