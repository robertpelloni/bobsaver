#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdGSRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const bool ENABLE_DOUBLE_LAYERS = true;
const bool ENABLE_CROSSFIRE     = false;
const bool ENABLE_SHADING       = true;
const bool ENABLE_AND_PATTERN   = false;
const bool ENABLE_INVERSION     = false;
const bool ENABLE_LOOPING       = true;
const bool ENABLE_LOOP_REWIND   = true;

const float LOOP_LENGTH = 420.0;
const float LAYER_A_SPEED = 144.0;
const float LAYER_B_SPEED = 96.0;

const vec3 COLOR = vec3(0.0, 1.0, 0.0);

int isPrime(int num)
{
     if (num <= 1) return 0;
     if (num % 2 == 0 && num > 2) return 0;

     for(int i = 3; i < int(floor(sqrt(float(num)))); i+= 2)
     {
         if (num % i == 0)
             return 0;
     }
     return 1;
}

int patternA(int x){
    return ((x*x)&x);
}
int patternB(int x){
    return (x>>7)&x;
}

float isMagical(int x, int y){
    int v;
    if (ENABLE_AND_PATTERN)
        v = x & y;
    else
        v = x ^ y;
    
    float r = patternA(v) > patternB(v) ? 0.0 : 1.0;
    if (ENABLE_INVERSION)
        r = 1.0 - r;
    return r;
}

void main(void)
{
    float time = time;
    if (ENABLE_LOOPING){
        while(time > LOOP_LENGTH) time -= LOOP_LENGTH;
        if (ENABLE_LOOP_REWIND && time > LOOP_LENGTH / 2.0)
            time = LOOP_LENGTH - time;
    }
    
    int XA = int(gl_FragCoord.x + time * LAYER_A_SPEED);
    int YA = int(gl_FragCoord.y + time * LAYER_A_SPEED);
   
    int XB = int(gl_FragCoord.x + time * LAYER_B_SPEED);
    int YB = int(gl_FragCoord.y + time * LAYER_B_SPEED);

    float VA, VB;
    if (ENABLE_CROSSFIRE){
        VA = isMagical(XA, YB);
        VB = isMagical(XB, YA);
    } else {
        VA = isMagical(XA, YA);
        VB = isMagical(XB, YB);
    }
    
    float V;
    if (ENABLE_DOUBLE_LAYERS)
        V = VA * VB;
    else
        V = VA;
    
    float S = 1.0;
    if (ENABLE_SHADING){
        vec2 halfRes = resolution.xy / vec2(2.0, 2.0);
        float dx = abs(float(gl_FragCoord.x) - halfRes.x) / float(halfRes.x);
        float dy = abs(float(gl_FragCoord.y) - halfRes.y) / float(halfRes.y);
        S = 1.0 - sqrt(dx * dx + dy * dy);
    } else
        S = 1.0;
    glFragColor = vec4(S * V, S * V, S * V, 1.0) * vec4(COLOR, 1.0);
}
