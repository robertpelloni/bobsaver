#version 420

// original https://www.shadertoy.com/view/XdXcDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141593;
const float KPT180 = 0.017453;
const float WATER_AMP = 0.35;
const float WATER_FRECQ = 4.97;
const float WAVE_LENGHT = 5.1;
const float WAVE_SPEED = 7.8;
float rand(float n){return fract(sin(n) * 43758.5453123);}
#define WATER_TIME (time*WAVE_SPEED/6.0)

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(16.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}
float noise(float p){
    float fl = floor(p);
  float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}
float frequency(float l) {
    float w = 2.0*PI/l;
    return w;
}
float phase(float w, float speed){
    float phase = speed*w;
    return phase;
}
float waveHeight(float amplitude, vec2 directional, vec2 uv, float w, float time, float phasa){
    float waveH = float(amplitude* dot(directional, uv) * w +phasa * time);
    return waveH;
}
float wave_shape(vec2 uv){
    vec2 waveShape = 1.0-abs(cos(uv));
    vec2 smoothWaveShape = abs(sin(uv));
    waveShape = -(mix(waveShape, smoothWaveShape, waveShape)) + 1.0;
    return pow(1.0-pow(waveShape.x * waveShape.y,0.6),0.67);
}
vec3 rotXAxis(vec3 Directional, float teta){
    teta = KPT180*teta;
    Directional.yz *= mat2(cos(teta), sin(teta), -sin(teta), cos(teta));
    return Directional;
}
vec3 rotYAxis(vec3 Directional, float teta){
    teta = KPT180*teta;
    Directional.xz *= mat2(cos(teta), -sin(teta), sin(teta), cos(teta));
    return Directional;
}
vec3 rotZAxis(vec3 Directional, float teta){
    teta = KPT180*teta;
    Directional.xy *= mat2(cos(teta), -sin(teta), sin(teta), cos(teta));
    return Directional;
}
float map(vec3 position){
    float amplitude = WATER_AMP;
    float l = WAVE_LENGHT;
    float s = WAVE_SPEED;
    float waveH = 0.0; 
    float dif = 0.0;
    float w = frequency(l);
    float p = phase(w,s);
    vec2 directional = vec2(1.1,1.1);
    vec2 uv = position.xz;
        for(int i = 0; i<4; i++){
            dif =  wave_shape(w *(uv+WATER_TIME));
            dif += wave_shape(w *(uv-WATER_TIME));
            waveH += dif * amplitude;
            w*=1.2; amplitude*=0.6;
        }
    return  (position.y - waveH) ;
}

float Trace(vec3 origin, vec3 directional, out vec3 position){
    float t = 0.0;
    for (int i = 0; i <32; i++){
        vec3 position = origin + directional * t;
           float dif = map(position);
        t += dif * 0.9;
    }
    return t;
}

float mapCircle(vec3 p){
   return length(p) - 1.0;
}
float TraceSun(vec3 origin, vec3 directional, out vec3 position){
    float t = 0.0;
    for (int i = 0; i <16; i++){
        vec3 position = origin + directional * t + vec3(0.0,-7.0,-10.0);
        position.x *=0.78;
           float dif = mapCircle(position);
        t += dif * 0.6;
    }
    return t;
}
//use float cool)))
vec3 GradientMap(vec3 heightMap){
return mix(vec3(0.9,0.92,0.91),vec3(0.0,0.5,0.85), heightMap);
}
void main(void)
    
{
       //Init UV
       vec2 uv = gl_FragCoord.xy/resolution.xy;
       uv = 2.0*uv - 1.0;
       uv.x *= resolution.x/resolution.y;
    
    //Init Space 
    vec3 origin = vec3(WAVE_SPEED,1.4,-1.0); 
    vec3 directional = normalize(vec3(uv,1.0)) ;
    directional = rotXAxis(directional, -60.0 * fract(time*0.006));
    directional = rotZAxis(directional, 0.0);
    directional = rotYAxis(directional, 15.0);
    
    
       //Trace
    vec3 position = vec3(0.0,0.0,0.0) ;
    float t = Trace(origin, directional, position);
    vec3 dist = origin - position;
    
    //TraceSun
    vec3 SunPosition = vec3(0.0);
    vec3 DirectionalSun = normalize(vec3(uv,1.0)) ;
    vec3 originSun = vec3(0.0,0.0,0.0); 
    float tSun = TraceSun(originSun, DirectionalSun, SunPosition);
    
    //Height Map
    vec3 hm;
    float attenuation = 1.0 /(1.0 +t*t*0.08);
    hm = vec3(attenuation);
    
    //HeightMapSun
    vec3 hms;
    float attenuationSun = 2.0 /(1.0 +tSun*tSun*0.08);
    hms = vec3(attenuationSun);
    
    //Diffuse
    vec3 gm; 
    gm = GradientMap(hm);
    
    //DiffuseSun
    hms =1.0* hms*vec3(0.8,0.7,0.1);
    
    //Gamma corection
    float gamma = 1.6;
    gm = pow(gm, vec3(1.0/gamma));
    
    //SumColor
    vec3 fc = gm + hms;
    glFragColor = vec4(fc,1.0);
}
