#version 420

//behavioural variables---
#define noiseMult 0.02        
#define moveToCentreMult 0.005
#define colourSpeed 0.5
//------------------------

uniform sampler2D backbuffer;
uniform float time;

out vec4 glFragColor;

#define time time * 9.8e-2
uniform vec2 mouse;
uniform vec2 resolution;
// Mitchell Netravali Reconstruction Filter {
// cubic B-spline: 
//#define MNB 1.0
//#define MNC 0.0

// recommended
#define MNB 0.333333333333
#define MNC 0.333333333333

// Catmull-Rom spline
//#define MNB 0.0
//#define MNC 0.5
// }

float MNweights(float x)
{
    float ax = abs(x);
    return (ax < 1.0) ?
        ((12.0 - 9.0 * MNB - 6.0 * MNC) * ax * ax * ax +
         (-18.0 + 12.0 * MNB + 6.0 * MNC) * ax * ax + (6.0 - 2.0 * MNB)) / 6.0
    : ((ax >= 1.0) && (ax < 2.0)) ?
        ((-MNB - 6.0 * MNC) * ax * ax * ax + (6.0 * MNB + 30.0 * MNC) * ax * ax + 
         (-12.0 * MNB - 48.0 * MNC) * ax + (8.0 * MNB + 24.0 * MNC)) / 6.0
    : 0.0;
}

vec4 texture2D_bicubic(sampler2D tex, vec2 uv)
{
    vec2 px = (1.0 / resolution);
    vec2 f = fract(uv / px);
    vec2 texel = (uv / px - f + 0.5) * px;
    vec4 weights = vec4(MNweights(1.0 + f.x),
                MNweights(f.x),
                MNweights(1.0 - f.x),
                MNweights(2.0 - f.x));
    vec4 t1 = 
        texture2D(tex, texel + vec2(-px.x, -px.y)) * weights.x +
        texture2D(tex, texel + vec2(0.0, -px.y)) * weights.y +
        texture2D(tex, texel + vec2(px.x, -px.y)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, -px.y)) * weights.w;
    vec4 t2 = 
        texture2D(tex, texel + vec2(-px.x, 0.0)) * weights.x +
        texture2D(tex, texel) /* + vec2(0.0) */ * weights.y +
        texture2D(tex, texel + vec2(px.x, 0.0)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, 0.0)) * weights.w;
    vec4 t3 = 
        texture2D(tex, texel + vec2(-px.x, px.y)) * weights.x +
        texture2D(tex, texel + vec2(0.0, px.y)) * weights.y +
        texture2D(tex, texel + vec2(px.x, px.y)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, px.y)) * weights.w;
    vec4 t4 = 
        texture2D(tex, texel + vec2(-px.x, 2.0 * px.y)) * weights.x +
        texture2D(tex, texel + vec2(0.0, 2.0 * px.y)) * weights.y +
        texture2D(tex, texel + vec2(px.x, 2.0 * px.y)) * weights.z +
        texture2D(tex, texel + vec2(2.0 * px.x, 2.0 * px.y)) * weights.w;
    
    return MNweights(1.0 + f.y) * t1 +
        MNweights(f.y) * t2 +
        MNweights(1.0 - f.y) * t3 +
        MNweights(2.0 - f.y) * t4;
}
vec4 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    vec3 ret = c.z * mix( vec3(1.0), rgb, c.y);
    
    return vec4(ret.x, ret.y, ret.z, 1);
}

// Classic Perlin noise -------------------------
vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}
 
vec2 fade(vec2 t) {
    return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float cnoise(vec2 P) {
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
//END OF CLASSIC PERLIN NOISE -------------------------

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 pix_pos = gl_FragCoord.xy;
    vec2 uv_pos = vec2(pix_pos.x/128.0, pix_pos.y/128.0);
    vec2 screenCentre = vec2(resolution.x/2.0, resolution.y/2.0);

    float noiseValX = cnoise( uv + vec2(1.0-sin(time)*2.0,1.0-sin(time)*2.0) *0.5 );    //playing around with the hardcoded multiplier
    float noiseValY = cnoise( uv_pos + vec2(time,time) *1.5 );                //values on these lines is fun
    float freq1 = sin((time*4.0)*colourSpeed);
    freq1 = (freq1+1.0)/2.0;
    
    float noiseValZ = cnoise(vec2(noiseValY, noiseValX));
    
    noiseValX = (noiseValX+noiseValZ)/2.0;
    noiseValY = (noiseValY+noiseValZ)/2.0;
    
    vec4 newCol = texture2D_bicubic(backbuffer, uv + vec2(noiseValX, noiseValY) * noiseMult + (uv-vec2(0.5,0.5))*(freq1*moveToCentreMult));
    
    vec4 _AvgVolumeCol = hsv2rgb( vec3(freq1, 1.0, 1.0) );
    
    //newCol = vec4(1,1,1,1);
    
    newCol = mix(newCol, _AvgVolumeCol, 1.0-min(pix_pos.y,1.0));
    newCol = mix(newCol, _AvgVolumeCol, 1.0-min(pix_pos.x,1.0));
    newCol = mix(newCol, _AvgVolumeCol, max(0.0,sign(pix_pos.y-(resolution.y-1.0))));
    newCol = mix(newCol, _AvgVolumeCol, max(0.0,sign(pix_pos.x-(resolution.x-1.0))));
    
    glFragColor =  (0.99+.01*sin(time*1.21+time*3.))*newCol;
    
    float g = 0.9;
    glFragColor *= g;        
    glFragColor += texture2D(backbuffer, gl_FragCoord.xy / resolution.xy)*((1.-g)/2.);
    const float lIterLim = 11.;
    for(int l = 0; l < int(lIterLim); l++){
        vec2 delta = 0.07*vec2(sin(time*.133+float(l)*2.*3.14159265/lIterLim), cos(time*.133+float(l)*2.*3.14159265/lIterLim));
        glFragColor += texture2D(backbuffer, delta+gl_FragCoord.xy / resolution.xy)*((1.-g)/2.)/lIterLim/1.5;
    }
}
//brownian pixels
