#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define SCALE .150
#define SEED 1333.1337
#define OCTAVES 8
#define PERSISTENCE 0.765
#define PI 3.1415
//Thingy
//by ninjapretzel
//Based off of another photoshop tutorial 
//http://www.quantumpetshop.com/tutorials/elecrings.asp
//Splits it into 6 regions based on how the effect is composed.
//Cell 0 - Brightness = Raw difference noise
//Cell 1 - Blended with black-white radial gradient
//Cell 2 - Output levels adjustment (.38, .49) -> (0.0, 1.0)
//Cell 3 - Rendering changes to Brightness/Distance (to center)
//Cell 4 - pre-divide Brightness value Curves adjustment, .5 region is brightest, (0, 1) are darkest.
//Cell 5 - Uses the 'color' (.5, 2.0, 15.0) as a blend color

float _seed;
float _scale;
float _persistence;
void defaultNoise() {
    _seed = SEED;
    _scale = SCALE;
    _persistence = PERSISTENCE;
}

float hash(float n) { return fract(sin(n)*_seed); }
float lerp(float a, float b, float x) { return a + (b-a) * x; }
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0 + 113.0*p.z;

    return mix(mix(    mix( hash(n+0.0), hash(n+1.0),f.x),
            mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
           mix(    mix( hash(n+113.0), hash(n+114.0),f.x),
            mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}
float nnoise(vec3 pos, float factor) {    
    float total = 0.0
        , frequency = _scale
        , amplitude = 1.0
        , maxAmplitude = 0.0;
    
    for (int i = 0; i < OCTAVES; i++) {
        total += noise(pos * frequency) * amplitude;
        frequency *= 2.0, maxAmplitude += amplitude;
        amplitude *= _persistence;
    }
    
    float avg = maxAmplitude * .5;
    if (factor != 0.0) {
        float range = avg * clamp(factor, 0.0, 1.0);
        float mmin = avg - range;
        float mmax = avg + range;
        
        float val = clamp(total, mmin, mmax);
        return val = (val - mmin) / (mmax - mmin);
    } 
    
    if (total > avg) { return 1.0; }
    return 0.0;
}
float nnoise(vec3 pos) { return nnoise(pos, .5); }
float diff(float a, float b) { return abs(a-b); }
float diffNoise(vec3 pos, float factor) {
    float v = nnoise(pos);
    for (int i = 0; i < 5; i++) {
        pos.z += 2.0;
        v = diff(v, nnoise(pos, factor));
    }
    return v;    
}
float diffNoise(vec3 pos) { return diffNoise(pos, .5); }

float map(float val, float olda, float oldb, float newa, float newb) {
    float oldRange = olda-oldb;
    float newRange = newa-newb;
    float p = (val - olda) / oldRange;
    return newa + (newRange * p);
}
float curvesMid(float val) {
    val = clamp(val, 0.0, 1.0);
    if (val < .5) {
        val = map(val, 0.0, .5, .0, 1.);    
    } else {
        val = map(val, .5, 1., 1., 0.);    
    }
    return val;
}
float levels(float val, float a, float b, float c, float d) {
    val = clamp(val, a, b);
    return map(val, a,b,c,d);
}

void main( void ) {
    defaultNoise();
    
    vec2 scaledPos = (gl_FragCoord.xy / resolution.xy);
    scaledPos.y = 1.0 - scaledPos.y;
    scaledPos *= vec2(3.0, 2.0);
    vec2 cellCoord = floor(scaledPos);

    int cell = int(cellCoord.x + (cellCoord.y * 3.0));
    vec2 uv = scaledPos - cellCoord - .5;
    uv *= 10.;
    //glFragColor = vec4(uv, cell / 6.0, 1);
    vec3 pos = vec3(uv * 1.0, -200. + time * .2 );
    float v = 0.;
    v = diffNoise(pos);
    
    
    if (cell >= 1) {
        float grad = length(uv)/(4.0 + sin(time));
        v = lerp(v, grad, .6);
    }

    if (cell >= 2) {
        v = levels(v, .38, .49, 0.0, 1.0);
    }

    if (cell >= 3) {
    }

    if (cell >= 4) { 
        v = curvesMid(v);
    }
    
    float d = max(1.0, length(uv));
    vec4 color;
    if (cell >= 5) { 
        color = vec4(0.51 * v/d, 2.0 *v/d, 15.0 *v/d, 1);
        d *= .2 + .5 * (1.0 + sin(time));
    } else if (cell >= 3) {
        color = vec4(vec3(v/d), 1.0);
    } else {
        color = vec4(vec3(v), 1.0);
    }
    glFragColor = color;

}
