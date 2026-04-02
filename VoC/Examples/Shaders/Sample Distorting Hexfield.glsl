#version 420

// original https://www.shadertoy.com/view/fsyGDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Distorting Hexfield" by Sagie Levy 2021.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Email:sagielevy21@gmail.com

#define scale 14.

#define minShrinkFactor .2
#define colorA vec3(0.914, 0.278, 0.047) * 10.
#define colorB vec3(0.047, 0.682, 0.914) * 2.

#define distortionOriginsCount 3
#define distortMovespeed 0.8

#define gridOffset 100.

// Returns a psuedo-random float between 0 and 1 for a given float c
float Random(float c)
{
    return fract(43758.5453123 * sin(c));
}

float HexDist(vec2 p) {
    p = abs(p);
    
    float c = dot(p, normalize(vec2(1,1.73)));
    c = max(c, p.x);
    
    return c;
}

// output: xy - local uv, zw - hex coords. 
// Note: zw are not whole numbers!
vec4 HexCoords(vec2 uv) {
    vec2 r = vec2(1, 1.73);
    vec2 h = r * .5;
    
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;
    
    vec2 gv = dot(a, a) < dot(b,b) ? a : b;
    
    vec2 id = uv-gv;
    return vec4(gv.x, gv.y, id.x,id.y);
}

vec2 HexCoords2UV(vec4 hc) {
    return hc.xy + hc.zw;
}

vec2[] offsets = vec2[](
    vec2(0, 0), vec2(1, 1.73) * .5, vec2(1, -1.73) * .5, vec2(1, 0), vec2(-1, 0), vec2(-1, -1.73) * .5, vec2(-1, 1.73) * .5,
    vec2(2, 0), vec2(2. * .75, -1.73 * .5), vec2(2. * .75, 1.73 * .5), vec2(1, 1.73), 
    vec2(0, 1.73), vec2(-1, 1.73), vec2(-2, 0), vec2(-2. * .75, 1.73 * .5),
    vec2(-2. * .75, -1.73 * .5), vec2(-1., -1.73), vec2(0, -1.73), vec2(1., -1.73)
);

int offsetsCount = 1 + 6 + 12;

float DisplaceEffect(vec4 hexCoord, vec2 distortOrigin) {    
    //return 1. - smoothstep(.0, 1.5, length(hexCoord.zw - HexCoords(distortOrigin).zw));// Debug: show effect in descrete tile jumps.

    // The further the effect is allowed to apply the more neighbours will be needed to sample.
    return 1. - smoothstep(.0, 3.5, length(hexCoord.zw - distortOrigin));
}

// Returns local position of displaced hex.
vec2 DisplaceHex(vec4 hexcoords, vec2 distortOrigin) {
    vec2 displacementDir = normalize(distortOrigin - hexcoords.zw);
    
    vec2 displacement = (length(displacementDir) < 0.001 ? normalize(hexcoords.xy) : displacementDir) * 
        DisplaceEffect(hexcoords, distortOrigin);
    
    return hexcoords.xy + displacement;
}

float DisplacedHexSize(vec4 hexcoords, vec2 distortOrigin) {
    return mix(1., minShrinkFactor, DisplaceEffect(hexcoords, distortOrigin));
}

vec2 GetInteractiveDistortionOrigin() {
    return (mouse*resolution.xy.xy-.5*resolution.xy) * scale / resolution.y + gridOffset;
}

vec2 GetAutoDistortionOrigin(int i) {
    float xSpeed = mix(.4, 3.5, Random(float(i) * 9024.));
    float ySpeed = mix(.4, 3.5, Random(float(i) * 94.));
    float movement = time * distortMovespeed * mix(.8, 1., Random(float(i) * 138.));
    
    float aspect = resolution.x / resolution.y;
    return vec2(sin(movement * xSpeed) * .5 * aspect, cos(movement * ySpeed) * .5) * scale + gridOffset;
}

vec3 ApplyInteractiveDistortionEffect(vec4 hc) {
    vec3 col = vec3(0);
    vec2 distortionOrigin = GetInteractiveDistortionOrigin();
    
    for (int i = 0; i < offsetsCount; i++) {
        vec2 offset = offsets[i];
        
        vec4 currHC = HexCoords(HexCoords2UV(hc) - offset);
        
        vec2 displacedPos = DisplaceHex(currHC, distortionOrigin) + offset;
        float displacedShrinkFactor = DisplacedHexSize(currHC, distortionOrigin);
        float colorFactor = smoothstep(minShrinkFactor, 1., displacedShrinkFactor);
        float currDistFromHexFactor = max(.5 * displacedShrinkFactor - HexDist(displacedPos), 0.);
        
        col += mix(colorA, colorB, colorFactor) * currDistFromHexFactor;
        //col += vec3(DisplaceEffect(currHC, distortionOrigin), 0, 0); // Debug: show effect area.
    }
    
    return col;
}

vec3 ApplyAutoDistortionEffect(vec4 hc) {
    vec3 col = vec3(0);

    for (int i = 0; i < offsetsCount; i++) {        
        vec2 offset = offsets[i];
        vec4 currHC = HexCoords(HexCoords2UV(hc) - offset);
        
        vec2 displacedPos = vec2(1000.);
        float displacedShrinkFactor = 1.;
        
        for (int j = 0; j < distortionOriginsCount; j++) {
            vec2 distortionOrigin = GetAutoDistortionOrigin(j);            

            displacedPos = min(displacedPos, DisplaceHex(currHC, distortionOrigin) + offset);
            displacedShrinkFactor = min(displacedShrinkFactor, DisplacedHexSize(currHC, distortionOrigin));
        }

        float colorFactor = smoothstep(minShrinkFactor, 1., displacedShrinkFactor);
        float currDistFromHexFactor = max(.5 * displacedShrinkFactor - HexDist(displacedPos), 0.);

        col += mix(colorA, colorB, colorFactor) * currDistFromHexFactor;
    }
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv = uv * scale + gridOffset;
    
    vec4 hc = HexCoords(uv);
    //vec3 col = (mouse*resolution.xy.z > 1.) ? ApplyInteractiveDistortionEffect(hc) : ApplyAutoDistortionEffect(hc);
    vec3 col = ApplyAutoDistortionEffect(hc);
    
    glFragColor = vec4(col,1.0);
}
