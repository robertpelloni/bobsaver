#version 420

// original https://www.shadertoy.com/view/MlSfDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform int frames;

out vec4 glFragColor;

// CHANGE TO CHANGE THE SPEED OF THE WAVE MOVEMENTS
#define ANIM_SPEED_MULTIPLIER 10.0
float interpsin(float x, float rand, float c1, float c2, float c3, float c4) {
    float cons = x * c1 * 3.14159 + rand;
    float s = sin(-cons);
    float cos1 = 0.25 * cos(cons * c2) * (abs(s*0.7) + 0.3);
      float cos2 = 0.1 * cos(cons * c3 + 1.5) * (abs(s*0.7) + 0.3);
    float l = 0.2 * log(abs(-cons) + 1.);
    float ss = pow(smoothstep(-1.25, 0., x) - smoothstep(0., 1.25, x), 3.);
    return (s + cos1 * (1.-ss) + cos2 + l) * (ss) * abs(c4) * 0.3;
}
vec4 mod289(vec4 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x)
{
  return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec2 fade(vec2 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
float cnoise(vec2 P)
{
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;

  vec4 i = permute(permute(ix) + iy);

  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
  vec4 gy = abs(gx) - 0.5 ;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);

  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
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

mat4 makeRotation( float x, float y, float z )
{
    float a = sin(x); float b = cos(x); 
    float c = sin(y); float d = cos(y); 
    float e = sin(z); float f = cos(z); 

    float ac = a*c;
    float bc = b*c;

    return mat4( d*f,      d*e,       -c, 0.0,
                 ac*f-b*e, ac*e+b*f, a*d, 0.0,
                 bc*f+a*e, bc*e-a*f, b*d, 0.0,
                 0.0,      0.0,      0.0, 1.0 );
}

void main(void)
{
    vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;

    mat4 rot = makeRotation( 0.3, 0.0, 0.0 );
     
    vec4 uvp = (vec4(uv, 0., 1.) - vec4(0.0, 0.1, 0., 1.)) * rot;
    uv = uvp.xy / (uvp.z + 1.) * 1.45;
    
    float col = 1.0;
    
    for (int i = 0; i < 101; i++) {
    
        float y = 0.3 * pow((1. - abs((float(i) - 50.)/50.)), 1.1) * 
            interpsin(
                uv.x, 
                -(time * ANIM_SPEED_MULTIPLIER + 100.5 * (fract(cnoise(vec2(float(i),float(time)/30.))))), 
                5. + abs(cnoise(vec2(float(i),float(i)/50.))) * 18. * (0.5 + 0.5*abs(sin(float(frames)/(500. * (0.8 + mod(float(i),4.2)))))), 
                2. + abs(cnoise(vec2(float(i),float(i)/20.))) * 4. * (0.5 + 0.5*abs(sin(float(frames)/(5000. * (0.8 + mod(float(i),4.2)))))), 
                4. + abs(cnoise(vec2(float(i),float(i)/50.))) * 1. * (0.5 + 0.5*abs(sin(float(frames)/(5000. * (0.8 + mod(float(i),4.2)))))), 
                1.
            ) + 1.5 - 0.025 * float(i);
        if (i == 0) {
            col *= smoothstep(uv.y - 0.01, uv.y, y) - smoothstep(uv.y, uv.y + 0.01, y);
        } else {
            col += smoothstep(uv.y - 0.01, uv.y, y);
            col *= 1. - smoothstep(uv.y, uv.y+0.01, y);
            col += smoothstep(uv.x - 0.01, uv.x, -1.) - smoothstep(uv.x, uv.x + 0.01, -1.);
            col += smoothstep(uv.x - 0.01, uv.x, 1.) - smoothstep(uv.x, uv.x + 0.01, 1.);
            col *= smoothstep(-1.01, -1.0, uv.x) - smoothstep(1.0, 1.01, uv.x);
            col *= step(-1.005, uv.y) - step(1.505, uv.y);
            col += (smoothstep(uv.x - 0.01, uv.x, -1. * (uvp.z - 1.) * 1.38) - smoothstep(uv.x, uv.x + 0.01, -1. * (uvp.z - 1.) * 1.38)) * (1. - step(-1.005, uv.y));
            col += (smoothstep(uv.x - 0.01, uv.x, 1. * (uvp.z - 1.) * 1.38) - smoothstep(uv.x, uv.x + 0.01, 1. * (uvp.z - 1.) * 1.38)) * (1. -step(-1.005, uv.y));
        }
    }
    
    
    glFragColor = vec4(vec3(col), 1.);
}
