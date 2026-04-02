#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define SCALE .150
#define SEED 1333.0
#define OCTAVES 6
#define PERSISTENCE 0.65
#define PI 3.1415
//Neon Wires
//by ninjapretzel
//Some perlin wave lines with a bunch of properites animated with sine and more perlin noise

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

void main( void ) {
    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) - .5;
    _seed = 133.7;
    _scale = 6.;
    _persistence = .65;
    
    float amp = 1.20 + .050 * nnoise(vec3(time*4.+uv.x*32., time*3., 0));
    
    
    
    defaultNoise();
    vec4 cc = vec4(0,0,0,1);
    for (int i = 0; i < 9; i++) {
        vec2 pos = uv;
        pos *= 5.0;
        pos.y /= amp * 4.0;
        pos.x *= .10 * _scale;
        pos.x -= 35.0;
        
        float v = noise(vec3(time *.5 + time*_scale+pos.x*8., pos.x * .05, 0.0)) - .5;
        float d = length(pos.y - v);
        //d *= (16.0 + 14.50 * sin(-2. * time + float(i)/9.0*2.0*PI));
        d *= .50 + 33.0 * noise(vec3(time * -6. + pos.x * 16.50, .01 * pos.x, 1.0));
        
        float r = .04 + .05 * sin(time + 2.0 * PI * ((float(i)+0.0)/9.0));
        float g = .04 + .05 * sin(time + 2.0 * PI * ((float(i)+3.0)/9.0));
        float b = .04 + .05 * sin(time + 2.0 * PI * ((float(i)+6.0)/9.0));
        cc.r += r/d;
        cc.g += g/d;
        cc.b += b/d;
        
        _scale *= 2.0;
        
        amp *= .72;
    }
    vec4 c = cc;//vec4(r/d, g/d, b/d, 1);
    glFragColor = c;
}
