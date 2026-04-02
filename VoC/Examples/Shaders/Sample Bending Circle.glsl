#version 420

// original https://www.shadertoy.com/view/4t33Rn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Created by soma_arc - 2016
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

// from Syntopia http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
vec2 rand2n(vec2 co, float sampleIndex) {
    vec2 seed = co * (sampleIndex + 1.0);
    seed+=vec2(-1,1);
    // implementation based on: lumina.sourceforge.net/Tutorials/Noise.html
    return vec2(fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453),
                fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 23421.631));
}

vec2 cPos1 = vec2(1.2631, 0);
vec2 cPos2 = vec2(0, 1.2631);
float cr1 = 0.771643;
float cr2 = 0.771643;
const float PI = 3.14159265359;

vec2 circleInverse(vec2 pos, vec2 circlePos, float circleR){
    return ((pos - circlePos) * circleR * circleR)/(length(pos - circlePos) * length(pos - circlePos) ) + circlePos;
}

vec2 reverseStereoProject(vec3 pos){
    return vec2(pos.x / (1. - pos.z), pos.y / (1. - pos.z));
}

float ly;
vec3 stereoProject(vec2 pos){
    float x = pos.x;
    float y = pos.y;
    float x2y2 = x * x + y * y;
    return vec3((2. * x) / (1. + x2y2),
                (2. * y) / (1. + x2y2),
                (-1. + x2y2) / (1. + x2y2));
}

vec3 getCircleFromSphere(vec3 upper, vec3 lower){
    vec2 p1 = reverseStereoProject(upper);
    vec2 p2 = reverseStereoProject(lower);
       return vec3((p1 + p2) / 2., distance(p1, p2)/ 2.); 
}

bool revCircle = false;
bool revCircle2 = false;
const int ITERATIONS = 50;
float colCount = 0.;
bool outer = false;
int IIS(vec2 pos){
    colCount = 0.;
    //if(length(pos) > 1.) return 0;

    bool fund = true;
    int invCount = 1;
    for(int i = 0 ; i < ITERATIONS ; i++){
        fund = true;
        if (pos.x < 0.){
            pos *= vec2(-1, 1);
            invCount++;
               fund = false;
        }
        if(pos.y < 0.){
            pos *= vec2(1, -1);
            invCount++;
            fund = false;
        }
        if(revCircle){
            if(distance(pos, cPos1) > cr1 ){
                pos = circleInverse(pos, cPos1, cr1);
                invCount++;
                colCount++;
                fund = false;
            }
        }else{
            if(distance(pos, cPos1) < cr1 ){
                pos = circleInverse(pos, cPos1, cr1);
                invCount++;
                colCount++;
                fund = false;
            }
        }
        
        if(revCircle2){
            if(distance(pos, cPos2) > cr2 ){
                pos = circleInverse(pos, cPos2, cr2);
                invCount++;
                colCount++;
                fund = false;
            }
        }else{
            if(distance(pos, cPos2) < cr2 ){
                pos = circleInverse(pos, cPos2, cr2);
                invCount++;
                colCount++;
                fund = false;
            }
        }
        
        if(fund){
            if(length(pos) > 1.5){
                outer = true;
                return 0;
            }
            return invCount;
        }
    }

    return invCount;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 calcCircleFromLine(vec4 line){
    float a = line.x;
    float b = line.y;
    float c = line.z;
    float d = line.w;
    
    float bcad = b * c - a * d;
    float a2 = a * a;
    float b2 = b * b;
    float c2 = c * c;
    float d2 = d * d;
    float c2d2 = (1. + c2 + d2);
    vec2 pos = vec2(((1. + a2) * d + b2 * d - b * c2d2)/(-2. * bcad),
                     (a2 * c + (1. + b2) * c - a * c2d2)/ (2. * bcad));
    return vec3(pos, distance(pos, line.xy));
}

const float sampleNum = 30.;
void main(void) {
    float t = mod(time, 10.);
    t = abs(t - 5.) / 5.;
    
    float ratio = resolution.x / resolution.y / 2.0;
    vec3 sum = vec3(0);
    float x = 0.57735;

    float bendX = t;// 0. + 1. * abs(sin(time));;//PI / 6.;
    mat3 xRotate = mat3(1, 0, 0,
                        0, cos(bendX), -sin(bendX),
                        0, sin(bendX), cos(bendX));
    float bendY = 0.;//PI/6.5;//-abs(0.8 * sin(time));
    mat3 yRotate = mat3(cos(bendY), 0, sin(bendY),
                         0, 1, 0,
                         -sin(bendY), 0, cos(bendY));
    float y = .57735;
    vec3 c1 = getCircleFromSphere(vec3(0, y, sqrt(1. - y * y))* xRotate,
                                  vec3(0, y, -sqrt(1. - y * y))* xRotate);
    vec3 c2 = getCircleFromSphere(vec3(x, 0, sqrt(1. - x * x)) * yRotate,
                                  vec3(x, 0, -sqrt(1. - x * x)) * yRotate);
    
    cr1 = c1.z;
    cr2 = c2.z;
    cPos1 = c1.xy;
    cPos2 = c2.xy;
    if(y > cPos1.y){
        revCircle = true;
    }
    if(x > cPos2.x){
        revCircle2 = true;
    }
    for(float i = 0. ; i < sampleNum ; i++){
        vec2 position = ( (gl_FragCoord.xy + rand2n(gl_FragCoord.xy, i)) / resolution.yy ) - vec2(ratio, 0.5);

        position *= ( 2.2 + ( t * 8.));
        //position += vec2(cos(time), 0.3 * sin(time));

        int d = IIS(position);
        
        if(d == 0){
            sum += vec3(0.,0.,0.);
        }else{
            if(mod(float(d), 2.) == 0.){
                if(outer){
                    sum += hsv2rgb(vec3(0.4 + 0.02 * colCount, 1., 1.));
                }else{
                    sum += hsv2rgb(vec3(0.02 * colCount, 1., 1.));
                }
            }else{
                if(outer){
                    sum += hsv2rgb(vec3(0.8 + 0.02 * colCount, 1., 1.));
                }else{
                    sum += hsv2rgb(vec3(0.7 + 0.02 * colCount, 1., 1.));
                }
            }
        }
    }
    glFragColor = vec4(sum/sampleNum, 1.);
}
