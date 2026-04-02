#version 420

// original https://www.shadertoy.com/view/7t2BDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

//  0   8   2  10
// 12   4  14   6
//  3  11   1   9
// 15   7  13   5

// 0000 1000 0010 1010
// 1100 0100 1110 0110
// 0011 1011 0001 1001
// 1111 0111 1101 0101
float crosshatch(vec2 xyf) {
    ivec2 xy = ivec2(xyf) & 3;
    return float(
        1 +
        + ((xy.y >> 1) & 1)
        + ((xy.x & 2) ^ (xy.y & 2))
        + ((xy.y & 1) << 2)
        + ((((xy.x) & 1) ^ (xy.y & 1)) << 3)
    )/ 16.;
}

vec3 ease(vec3 t) {
    t = clamp(t, 0., 1.);
    return t * t * t * (t * (t * 6. - 15.) + 10.);
}

vec3 posterize(vec3 col, float thres) {
const float steps = 2.;
    return (floor(
        col * steps
    ) + step(
        vec3(thres), fract(col * steps)
    )) / steps;
}

float ease(float t) {
    t = clamp(t, 0., 1.);
    return t * t * t * (t * (t * 6. - 15.) + 10.);
}

float zigzag(float t) {
    return 1. - abs(1. - fract(t) * 2.);
}

float ripple(vec2 uv, vec2 lightDir, float scale, float time) {
    
    return ease(zigzag(
        length(uv) * scale - time
    )) * 0.5 * dot(
        lightDir,
        normalize(uv) *
        ease(length(uv) * scale * 0.25)
    );
}

vec2 angleVec(float theta) {
    return vec2(cos(theta), sin(theta));
}

// gives pure saturated color from input [0, 6) for phase
vec3 hue(float x) {
    x = mod(x, 6.);
    return clamp(vec3(
        abs(x - 3.) - 1.,
        -abs(x - 2.) + 2.,
        -abs(x - 4.) + 2.
    ), 0., 1.);
}

// does pseudo overexposure filter
vec3 deepfry(vec3 rgb, float x) {
    rgb *= x;
    return rgb + vec3(
      max(0., rgb.g - 1.) + max(0., rgb.b - 1.),
      max(0., rgb.b - 1.) + max(0., rgb.r - 1.),
      max(0., rgb.r - 1.) + max(0., rgb.g - 1.)
    );
}

void main(void)
{
    // Make sure this loops
    float time = fract(time /4.);
    // Normalized pixel coordinates
    vec2 uv = ( 2.* gl_FragCoord.xy - resolution.xy ) / length(resolution.xy);
    float lightAngle = 1.7 + 0.45 * sin(2. * uv.x * TAU);
    const float centerSep = 0.1;
    const float centerSpeed = -0.;
    float centerOfs = 2.5;
    vec2 center0 = centerSep*angleVec(centerOfs + TAU*(centerSpeed*time));
    vec2 center1 = centerSep*angleVec(centerOfs + TAU*(centerSpeed*time+1./3.));
    vec2 center2 = centerSep*angleVec(centerOfs + TAU*(centerSpeed*time-1./3.));
    
    const float sizeScale = 8.;
    const float timeScale = 7.;
    
    uv += ripple(
            uv, angleVec(lightAngle),
            sizeScale, 0. + time * timeScale
        ) * vec2(0.05, 0.2) * length(uv);
    
    //uv.x += 0.02 * sin(uv.y * 150.5 + time * 7. * TAU);
    //uv.y += 0.002 * sin(uv.x * 14.7 + time * 11. * TAU + 0.2);
   
    float colorSep = 0.3;
    vec2 cbcr = vec2(0.);
    cbcr +=
        ripple(
            uv - center0, angleVec(lightAngle + colorSep),
            sizeScale, time * timeScale
        ) * vec2(1., 0.);
    cbcr +=
        ripple(
            uv - center1, angleVec(lightAngle),
            sizeScale, time * timeScale
        ) * vec2(-0.5, sqrt(3.)/2.);
    cbcr +=
        ripple(
            uv - center2, angleVec(lightAngle - colorSep),
            sizeScale, time * timeScale
        ) * vec2(0.5, sqrt(3.)/2.);
    vec3 col = length(cbcr) * (hue(6. * (time - 1.3 * length(uv) + atan(cbcr.y, cbcr.x) / TAU)) - 0.5);
    // add b/w
    col +=
        ripple(
            uv, angleVec(lightAngle),
            sizeScale, 0. + time * timeScale
        ) * vec3(0.5);//*/
    col = posterize(
        col * 2.5 + 0.5,
        crosshatch(gl_FragCoord.xy)
    );
    // color balance
    col = vec3(0.5) + (col - 0.5) * vec3(0.3);
    // overexpose
    col = deepfry(col, 1.2);
    
    // Output to screen
    glFragColor = vec4(
        col, 1.0
    );
}
