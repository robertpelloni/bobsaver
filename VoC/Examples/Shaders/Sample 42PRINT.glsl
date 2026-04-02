#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wlyGRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HEXRGB(hex) vec3(float((hex & 0xff0000) >> 16) / 255.0, float((hex & 0x00ff00) >> 8) / 255.0, float(hex & 0x0000ff) / 255.0)

// Declare sprite data
const int[] sprHead =
    int[](
        0xF9, 0xFF, 0xFF, 0xBF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0x3F, 0xF0, 
        0xF, 0xFC, 0xFF, 0xF3, 
        0xFF, 0xFC, 0xD7, 0xF3, 
        0xFF, 0xFC, 0xFF, 0xFF, 
        0xFF, 0xF, 0x0, 0xF8, 
        0xFF, 0x7F, 0x0, 0xFC, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFD, 0xFF, 0xFF, 0xBF, 
        0x0, 0x0, 0x0, 0x0
    );

const int[] sprBody1 =
    int[]
    (
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x15, 0xAA, 0x4A, 0x55, 
        0xA5, 0xAA, 0x6A, 0x55, 
        0xA1, 0xA8, 0x2A, 0x55, 
        0x28, 0xA8, 0x2A, 0x55, 
        0x68, 0xA8, 0x2A, 0x7E, 
        0x7F, 0xA8, 0x2A, 0x6E, 
        0x6F, 0xA9, 0x2A, 0x40, 
        0x40, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55, 
        0x55, 0x55, 0x55, 0x55
    );

const int[] sprBody2 =
    int[]
    (
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xFF, 0xFF, 0xFF, 
        0xFF, 0xAB, 0xEA, 0xFF, 
        0xFF, 0x54, 0x15, 0xFF, 
        0x7F, 0x55, 0x55, 0xFC, 
        0x4F, 0x1, 0x40, 0xFD, 
        0x4F, 0xFC, 0xF, 0xF5, 
        0xF, 0xFC, 0x3F, 0xC0, 
        0x57, 0xFC, 0x3F, 0x50
    );

float sampleSpriteHead (vec2 uv)
{
    vec2 fracuv = fract(uv);
    int x = int(fracuv.x * 16.0);
    int y = int(fracuv.y * 16.0);
    
    // 16 idx data per row, 1 element & 4 index per 1 element...
    // => 4 element per row
    int indexperelement = 4;
    int elementperrow = 4;
    int bitsperindex = 2;
    int arrayidx = y * elementperrow + x / indexperelement;
    int idx = x % indexperelement;
    int bitoffset = (idx) * bitsperindex;
    int mask = 3 << bitoffset;
    int bits = (sprHead[arrayidx] & mask) >> bitoffset; // test

    float value = float(bits) / 3.0;
    return (value);
}

float sampleSpriteBody1 (vec2 uv)
{
    vec2 fracuv = fract(uv);
    int x = int(fracuv.x * 16.0);
    int y = int(fracuv.y * 20.0);
    
    // 16 idx data per row, 1 element & 4 index per 1 element...
    // => 4 element per row
    int indexperelement = 4;
    int elementperrow = 4;
    int bitsperindex = 2;
    int arrayidx = y * elementperrow + x / indexperelement;
    int idx = x % indexperelement;
    int bitoffset = (idx) * bitsperindex;
    int mask = 3 << bitoffset;
    int bits = (sprBody1[arrayidx] & mask) >> bitoffset; // test

    float value = float(bits) / 3.0;
    return (value);
}

float sampleSpriteBody2 (vec2 uv)
{
    vec2 fracuv = fract(uv);
    int x = int(fracuv.x * 16.0);
    int y = int(fracuv.y * 20.0);
    
    // 16 idx data per row, 1 element & 4 index per 1 element...
    // => 4 element per row
    int indexperelement = 4;
    int elementperrow = 4;
    int bitsperindex = 2;
    int arrayidx = y * elementperrow + x / indexperelement;
    int idx = x % indexperelement;
    int bitoffset = (idx) * bitsperindex;
    int mask = 3 << bitoffset;
    int bits = (sprBody2[arrayidx] & mask) >> bitoffset; // test

    float value = float(bits) / 3.0;
    return (value);
}

float getrectmix (vec2 uv, vec2 sz)
{
    float val = 0.0;
    vec2 rectsz = (vec2(0.5) - sz * 0.5);
    vec2 rect = step(rectsz, uv);
    val = rect.x * rect.y;
    
    rect = step(rectsz, vec2(1.0) - uv);
    val *= rect.x * rect.y;
    return val;
}

vec3 mixSpriteHead (vec3 orig, vec2 uv)
{
    vec3 colour = orig;
    float spr = sampleSpriteHead(uv * 1.0);
    
    vec2 sprUVDelta = step(abs(uv - vec2(0.5, -0.5)), vec2(0.5));
    float sprMix = sprUVDelta.x * sprUVDelta.y;
    
    colour = mix(colour, vec3(spr), sprMix);
    return colour;
}

vec3 mixSpriteBody1 (vec3 orig, vec2 uv)
{
    vec3 colour = orig;
    float spr = sampleSpriteBody1(uv * 1.0);
    
    vec2 sprUVDelta = step(abs(uv - vec2(0.5, -0.5)), vec2(0.5));
    float sprMix = sprUVDelta.x * sprUVDelta.y;
    
    float discardMask = 1.0 / 3.0; // discard if image idx == 1
    if (spr == discardMask)
        sprMix = 0.0;
    
    colour = mix(colour, vec3(spr), sprMix);
    return colour;
}

vec3 mixSpriteBody2 (vec3 orig, vec2 uv)
{
    vec3 colour = orig;
    float spr = sampleSpriteBody2(uv * 1.0);
    
    vec2 sprUVDelta = step(abs(uv - vec2(0.5, -0.5)), vec2(0.5));
    float sprMix = sprUVDelta.x * sprUVDelta.y;
    
    float discardMask = 1.0; // discard if image idx == 3
    if (spr == discardMask)
        sprMix = 0.0;
    
    colour = mix(colour, vec3(spr), sprMix);
    return colour;
}

// Noise functions from
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float rand(vec2 n)
{ 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 p)
{
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

// HSV -> RGB routine from
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float samplenaejang (vec3 uv, float time)
{
    // prevent floating point error
    // time = mod(time, 6.285);
    
    // apply wobble
    vec2 wobblyUV = vec2(uv.x, uv.y);
    wobblyUV.x += sin(uv.y * 10.0 + mod(time * 0.82, 6.28) + cos(uv.x * 2.5 + time * 0.5) * 0.15) * 0.065;
    wobblyUV.y += cos(uv.x * 14.2 + mod(time * 0.75, 6.28) + sin(uv.y * 1.5 + time * 0.6) * 0.2) * 0.065;
    
    // calculate 10PRINT
    vec2 uvMult = wobblyUV * 8.0;
       vec2 uvChunky = floor(uvMult) / 8.0;
    vec2 uvChunkyLocal = fract(uvMult);
    float chunkFlip = sign(floor(noise(uvChunky * 10.0) + 0.5) - 0.5);
    
    vec2 gridDelta = fract(vec2(uvChunkyLocal.x * chunkFlip, uvChunkyLocal.y)) - 0.5;
    float dist1 = min(distance(vec2(0.5), gridDelta), distance(vec2(0.5), -gridDelta));
    float dist2 = abs(0.5 - dist1);
    float thiccness = 0.8 + pow(sin(time), 3.0) * 0.4;
    float shape = dist2 * thiccness;//smoothstep(0.3, 0.75, dist2 * thiccness);
    
    return clamp((1.0 - shape) - uv.z, 0.0, 1.0);
}

vec3 getnaejangnormal (vec2 uv, float time)
{
    vec3 normal;
    vec2 smol = vec2(0.00001, 0.0);
    vec3 uv3D = vec3(uv, 0.0);
    
    // calculate normal via central whatever method
    normal.x = (samplenaejang(uv3D - smol.xyy, time) - samplenaejang(uv3D + smol.xyy, time));
    normal.y = (samplenaejang(uv3D - smol.yxy, time) - samplenaejang(uv3D + smol.yxy, time));
    normal.z = 2.0 * smol.x;
    return normalize(normal);
}

vec3 samplerectBG (vec2 absuv, vec2 rectUV, float time)
{
    vec2 uvsize = (resolution.xy / resolution.x);
    vec2 uvsizeHalf = uvsize * 0.5;
    vec3 colourRect;
    
    // Prepare rect properties
    const float rectScrollPower = 3.0;
    vec2 rectUVOffset = vec2(pow(sin(time * 0.5), rectScrollPower) * 1.0, pow(cos(time * 0.25), rectScrollPower) * 4.0);
    rectUV += rectUVOffset; // / (rectHalfSize * 2.0);

    // Foreground : 10PRINT
    float naejangSDF = samplenaejang(vec3(rectUV, 0.0), time);
    vec3 naejangNormal = getnaejangnormal(rectUV, time); // vec3(clamp(getnaejangnormal(rectUV, time), -1.0, 1.0), 0.5);
    float naejangCenterMix = pow(1.0 - pow(1.0 - naejangSDF, 1.0), 4.0);//smoothstep(0.0, 0.75, naejangSDF - 0.1);
    naejangNormal.xy = mix(naejangNormal.xy, vec2(0.0), naejangCenterMix);
    naejangNormal.z = 1.0;//mix(0.0, 1.0, naejangCenterMix);
    
    // Calculate light
    vec3 viewVector = vec3(0.0, 0.0, 1.0);
    float lightTime = mod(time * 2.0, 6.254);
    vec3 lightPos = vec3(uvsizeHalf + vec2(cos(lightTime), sin(lightTime)) * (uvsizeHalf * 0.75), 1.0);
    vec3 lightDelta = lightPos - vec3(absuv, 0.05 + naejangSDF * 0.35);
    vec3 lightDir = normalize(lightDelta);
    float lightDist = length(lightDelta);
    
    // 1] albedo
    vec3 plasmacolour1 = hsv2rgb(vec3(fract(time * 0.2), 0.5, 1.0));
    vec3 plasmacolour2 = hsv2rgb(vec3(fract(1.0 - time * 0.2), 1.0, 0.5));
    
    vec3 diffuse = mix(plasmacolour2, plasmacolour1, naejangCenterMix);
    //colourRect = diffuse;
    
    // 2] lambert
    float lightAmbient = 0.5;
    float lightDot = dot(naejangNormal, lightDir);
    float lightDistRange = smoothstep(0.3, 0.7, clamp(1.0 / (lightDist * lightDist * 4.0), 0.0, 1.0));
    float lightLit = clamp((lightDot * lightDistRange + lightAmbient), 0.0, 1.0);
    colourRect = diffuse * lightLit;
    
    // 3] Blinn-phong specular reflection
    vec3 phongH = normalize(lightDelta + viewVector);
    float phongDistRange = naejangCenterMix * smoothstep(0.5, 0.7, clamp(1.0 / (lightDist * lightDist * 4.0), 0.0, 1.0));
    float phongDot = dot(naejangNormal, phongH);
    float phongClamped = clamp(phongDot, 0.0, 1.0);
    float phong = pow(phongClamped, 800.0);
    
    colourRect += vec3(phong * phongDistRange);
    
    return colourRect;
}

vec3 samplescene (vec2 uv, float time)
{
    vec2 uvsize = (resolution.xy / resolution.x);
    vec2 uvsizeHalf = uvsize * 0.5;
    vec3 final = vec3(0.0);
    
    // Prepare rect properties
    vec2 rectHalfSize = vec2(0.4, 0.225);
    const float rectUVScale = 1.5;
    vec2 rectUV = (uv - (uvsizeHalf - rectHalfSize)) * rectUVScale;
    
    // Downscale the rectangle's resolution
    const float crunchfactor = 64.0;
    vec2 uvcrunchy = floor(rectUV * crunchfactor) / crunchfactor;
    vec2 uvcrunchylocal = fract(rectUV * crunchfactor);
    
    // Commodore colours
    vec3 colourBG = HEXRGB(0x887ecb);
    vec3 colourRect = HEXRGB(0x50459b);
    
    // Background C64 loading screen-like raster bars
    float rasterScale = 15.0;
    float rasterOff = time * 0.5;
    float rasterMix = floor(fract((uv.y + rasterOff) * rasterScale + (uv.x * sin(time * 3.0)) * 0.5) + 0.5);
    const vec3 colours[3] = vec3[3](HEXRGB(0x6abfc6), HEXRGB(0xa1683c), HEXRGB(0x9ae29b));
    
    colourBG = mix(colours[int(time) % 3], HEXRGB(0xadadad), rasterMix);
    
    // Foreground : 10PRINT
    const float uvdownscaleFactor = 64.0;
    vec2 uvdownscale = (rectUV * uvdownscaleFactor + 0.5);
    vec2 uvdownscaleLocal = fract(uvdownscale);
    uvdownscale = floor(uvdownscale) / uvdownscaleFactor;
    
    vec3 rectBG = samplerectBG(uv, uvdownscale, time);
    float rectBGLuma = clamp(dot(rectBG, rectBG), 0.0, 1.0);
    
    // apply LED light effect to foreground's 10PRINT BG(??)
    float ledDiscRadius = 0.25 * rectBGLuma + 0.20;
    const float ledDiscRadiusSmooth = 0.1;
    float ledDiscDelta = distance(vec2(0.5), uvdownscaleLocal);
    float ledDiscMix = smoothstep(ledDiscRadius + ledDiscRadiusSmooth, ledDiscRadius, ledDiscDelta);
    colourRect = mix(rectBG * 0.5, rectBG, ledDiscMix);
    colourRect = clamp(colourRect + pow(1.0 - ledDiscDelta, 2.0) * 0.2, 0.0, 1.0);

    // Foreground : Sprites
    vec2 sprUV;
    float sprAnimTime = time * 2.0;
    float sprRot = sin(sprAnimTime);
    float sprScale = 8.0;
    vec2 sprOff = vec2(sin(time * 0.5 + cos(time * 0.1) * 0.01) * 0.05, cos(time * 0.5) * 0.025 + sin(time * 0.1) * 0.01);
    
    // body
    float rot = radians(pow(sprRot, 4.0) * 12.0 * 0.1);
    sprUV = (vec2(uv.x, uv.y) - uvsizeHalf + sprOff) * sprScale;
    //sprUV.y -= 0.75;
    sprUV *= mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    sprUV += 0.5;
    sprUV.y *= -1.0;
    sprUV.y += -0.6;
    colourRect = mixSpriteBody2(colourRect, sprUV);
    
    // body
    rot = radians(pow(sprRot, 3.0) * 12.0 * 0.3);
    sprUV = (vec2(uv.x, uv.y) - uvsizeHalf + sprOff) * sprScale;
    //sprUV.y -= 0.75;
    sprUV *= mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    sprUV += 0.5;
    sprUV.y *= -1.0;
    sprUV.y += -0.65 + sin(sprAnimTime * 2.0) * 0.05;
    colourRect = mixSpriteBody1(colourRect, sprUV);
    
    // head
    rot = radians(sprRot * 12.0 * -0.5);
    sprUV = (vec2(uv.x, uv.y) - uvsizeHalf + sprOff) * sprScale;
    sprUV *= mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    sprUV += 0.5;
    sprUV.y *= -1.0;
    sprUV.y += sin(sprAnimTime * 2.0) * 0.1;
    colourRect = mixSpriteHead(colourRect, sprUV);
    
    // debug light
    //float lightCircleMix = smoothstep(0.01, -0.01, length(lightDelta.xy) - 0.01);
    //colourRect = mix(colourRect, vec3(0.0, 1.0, 1.0), lightCircleMix);
    
    // Draw commodore 64-esque screen
    // shadow
    vec2 centerDelta = uvsizeHalf - uv + vec2(0.025, -0.025);
    float rectMinDelta = max(abs(centerDelta.x) - rectHalfSize.x, abs(centerDelta.y) - rectHalfSize.y);
    float rectfactor = 1.0 - ceil(max(rectMinDelta, 0.0));
    vec3 rect = mix(colourBG, colourBG * vec3(0.5), rectfactor);
    
    // screen
    centerDelta = uvsizeHalf - uv;
    rectMinDelta = max(abs(centerDelta.x) - rectHalfSize.x, abs(centerDelta.y) - rectHalfSize.y);
    rectfactor = 1.0 - ceil(max(rectMinDelta, 0.0));
    rect = mix(rect, colourRect, rectfactor);
    
    return rect;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uvratio = (resolution.xy / resolution.x);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvPixelperfect = gl_FragCoord.xy/resolution.xy * uvratio;

    // Uh yeah woo yeah woo hoo
    vec3 col = samplescene(uvPixelperfect, time);
    
    // Test : sprite
    // vec3 col = vec3(sampleSpriteHead(vec2(uv.x, 1.0 - uv.y)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
