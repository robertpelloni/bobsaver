#version 420

// original https://www.shadertoy.com/view/llsczf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 lightDirection = normalize(vec3(-.5, -.1, 0.0));

#define innerRadius 1.0
#define atmoRadius 1.2
#define waterLevel .45

#define PI 3.14159265359
#define gamma 2.2
#define invgamma 1.0 / gamma

const float scaleDepth = .25;
const float scale = 1.0 / (atmoRadius - innerRadius);
const float scaleOverScaleDepth = scale / scaleDepth;
const float g = -.99;
const float g2 = g*g;
const vec3 invWavelength = vec3(
        pow(1.0 / .65, 4.0),
        pow(1.0 / .57, 4.0),
        pow(1.0 / .475, 4.0));

const float kr = .0025;
const float km = .0010;
const float kr4pi = kr * 4.0 * PI;
const float km4pi = km * 4.0 * PI;
const float esun = 20.0;

#define hash(a) fract(sin(a)*12345.0) 
float noise(vec3 x, float c1, float c2) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*c2+ c1*p.z;
    return mix(
        mix(
            mix(hash(n+0.0),hash(n+1.0),f.x),
            mix(hash(n+c2),hash(n+c2+1.0),f.x),
            f.y),
        mix(
            mix(hash(n+c1),hash(n+c1+1.0),f.x),
            mix(hash(n+c1+c2),hash(n+c1+c2+1.0),f.x),
            f.y),
        f.z);
}
float noise(vec3 p){

    float a = noise(p, 883.0, 971.0);
    float b = noise(p + 0.5, 113.0, 157.0);
    return (a + b) * 0.5;
}
float map4( in vec3 p ) {
    float f;
    f  = 0.50000*noise( p ); p = p*2.02;
    f += 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p );
    return clamp(f, 0.0, 1.0);
}

float height(vec3 dir){
    float h;
    
    if (abs(dir.y) > innerRadius * .9){
        dir += 10.0;
        h = map4(dir * 3.0+ map4(dir * 5.0) * (sin(time)*.5+.5)*1.5);
        h = clamp(h + waterLevel * .2, 0.0, 1.0);
    }else
        h = map4(dir * 3.0+ map4(dir * 5.0) * (sin(time)*.5+.5)*1.5);
    
    return h;
}

vec2 map(vec3 pos){
    float l = length(pos);
    float h = height(pos / l);
    float rh = max(.45, h);
    return vec2(l - (1.0 + .2 * rh), h);
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
                      e.yyx*map( pos + e.yyx ).x + 
                      e.yxy*map( pos + e.yxy ).x + 
                      e.xxx*map( pos + e.xxx ).x );
}

vec3 getGroundColor(vec3 pos, float h){
    vec3 normal = calcNormal(pos);
    float light = clamp(dot(-lightDirection, normal), 0.0, 1.0);
    
    float n = dot(normal, normalize(pos));
    
    light += pow(normal.y * .5 + .5, 2.0) * .01; // ambient
    
    vec3 col = vec3(0.0);
    
    float l = h - waterLevel;
    if (l < 0.0)
        // water
        col = mix(vec3(0.3, 0.6, 1.0), vec3(0.0, 0.0, 1.0), clamp(pow(-l*25.0, 3.0), 0.0, 1.0));
    else{
        // land
        
        // poles
        if (abs(pos.y) > innerRadius * .9)
            col = vec3(1.0);
        else{
            if (l < 0.02)
                col = vec3(0.9, 0.85, 0.8); // sand
            else if (l < .2){
                if (n < .95)
                    col = vec3(.2, .2, .2); // rock
                else
                    col = vec3(0.0, 0.55, 0.02); // grass
            } else{
                if (n < .95)
                    col = vec3(.2); // rock
                else
                    col = vec3(1.0); // snow
            }
        }
    }
    
    return col * light;
}

vec2 raySphere(in vec3 ro, in vec3 rd, in float rad) {
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro,ro) - rad*rad;
    float det = b*b - 4.0 * c;
    if (det > 0.0){
        det = sqrt(det);
        return vec2(0.5 * (-b - det), 0.5 * (-b + det));
    }
    return vec2(-1.0, -1.0);
}

vec3 sampleAtmosphere(vec3 ro, vec3 rd, float len){
    vec3 scatter = vec3(0.0);
    
    #if 0
    
    float t = 0.0;
    float slength = len * .1;
    vec3 pos;
    for (int i = 0; i < 10; i++){
        pos = ro + rd * len;
        
        float h = length(pos);
        
        float den = exp(scaleOverScaleDepth * (innerRadius - h));
        
        float light = max(dot(pos / h, -lightDirection), 0.0);
        
        vec3 atten = exp(-light * (invWavelength * kr4pi + km4pi));
        
        scatter += atten * den * slength * scale;
        
        t += slength;
    }
    
    scatter *= invWavelength * kr * esun;
    
    #endif
    
    return scatter;
}

vec3 march(vec3 ro, vec3 rd){
    vec2 ray = raySphere(ro, rd, atmoRadius);
    if (ray.x < 0.0) return vec3(0.0);
    
    float t = ray.x;
    vec2 d;
    vec3 pos;
      vec2 ld = vec2(1000.0, 1.0);
    for (int i = 0; i < 100; i++){
        pos = ro + rd * t;
        d = map(pos);
        
        if (d.x > ld.x && d.x > atmoRadius){
            // getting farther away, and outside the planet
            return sampleAtmosphere(ro  + rd * ray.x, rd, ray.y - ray.x);
        }
        
        if (d.x < 0.0){
            vec3 atmo = sampleAtmosphere(ro + rd * ray.x, rd, t - ray.x);
            return getGroundColor(pos, d.y) + atmo;
        }
        
        ld = d;
        t += max(d.x * .5, .01);
    }
    
    return vec3(0.0);
}

vec3 tonemap(vec3 color)
{
    float white = 2.;
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float toneMappedLuma = (1. + luma / (white*white)) / (1. + luma);
    return pow(color * toneMappedLuma, vec3(invgamma));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec3 dir = vec3((uv.x - .5), (uv.y - .5) * resolution.y / resolution.x, 1.0);
    
    dir = normalize(dir);
    
    float t = mouse.x*resolution.x*.01;
    
    vec3 campos = vec3(sin(t), 0.0, cos(t)) * (4.0 * (1.0 - (mouse.y*resolution.y / resolution.y)) + atmoRadius*1.1);
    vec3 right = vec3(sin(t + PI * .5), 0.0, cos(t + PI * .5));
    vec3 fwd = normalize(-campos);
    
    vec3 color = march(campos, normalize(right * dir.x + fwd * dir.z + vec3(0.0, dir.y, 0.0)));
    
    color = tonemap(color);
    
    glFragColor = vec4(color, 1.0);
}
