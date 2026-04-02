#version 420

// Fermat's spiral
// Reference: https://qiita.com/doxas/items/00567758621bb506e584

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define r resolution
#define t time

const float n = 100.; // number of lights
const float radius = 0.014; // radius of lights
const float Radius = 0.08; // radius of the innermost orbit
const float rot = 0.053; // speed of rotation
const float colChange = 0.7; // rate of color change
const float aveBright = 0.75; // average brightness
const float PI  = 3.141592653589793;

void main(void){
    vec2 p = (gl_FragCoord.xy * 2. - r) / min(r.x, r.y);
    vec3 destColor = vec3(0.);
    
    vec3 aveLight = vec3(aveBright); // average light
    float amp = 4. - aveBright; // amplitude
    
    vec3 innerColor = vec3(sin(colChange * t), sin(1.1 * colChange * t + 2./3. * PI), tan(1.2 * colChange * t + 4./3. * PI)) * amp + aveLight;
    vec3 outerColor = vec3(sin(1.1 * colChange * t + 5./3. * PI), sin(1.2 * colChange * t + 4./3. * PI), tan(colChange * t)) * amp + aveLight;
    
    for(float i = 0.; i < n; i++){

        float j = i + 1.;
        vec2 q = p + vec2(cos(t * j * rot), sin(t * j * rot)) * sqrt(j) * Radius;
        vec3 mixedColor = mix(innerColor, outerColor, j / n);

        destColor += mixedColor * pow(radius, 2.) / pow(length(q), 2.);
    }
    glFragColor = vec4(destColor, 1.);
}
