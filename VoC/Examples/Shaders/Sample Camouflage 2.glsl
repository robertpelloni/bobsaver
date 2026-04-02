#version 420

// original https://www.shadertoy.com/view/wdyyRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_FREQS 50
#define MPI 3.14159265359
float timescale = 1.50;

float random (in vec2 _st) {
     return fract(sin(1.0+dot(_st,vec2(127.1,311.7)))*43758.545); 
}

float random (in float _st) {
    return fract(sin(dot(vec2(_st, 0.0),
                         vec2(127.1,311.7)))*
        43758.545);
}
float lastrandom = 0.0;
float nextrandom(float a)
{
    float r = random (lastrandom);
    lastrandom = r + a;
    return r;
}

struct freq
{
    float a;
    float phase;
    float xfreq;
    float yfreq;
};
    
freq freqs[MAX_FREQS];
freq freqs2[MAX_FREQS];
int freqs_count = 0;

void InitFreqs(float time)
{
    int oc = freqs_count = 0;
    lastrandom = floor(time*timescale);
    for (int i = 0; i < MAX_FREQS; i++)
    {
        freqs[oc].a = nextrandom(float(i*5 + 0) / 5.0);
        freqs[oc].xfreq = (nextrandom(float(i*5 + 1) / 5.0)*2.0 - 1.0) * (1.0 - freqs[oc].a) * (float(MAX_FREQS));
        freqs[oc].yfreq = (nextrandom(float(i*5 + 2) / 5.0)*2.0 - 1.0) * (1.0 - freqs[oc].a) * (float(MAX_FREQS));
        freqs[oc].phase = nextrandom(float(i*5 + 3) / 5.0) * 2.0 * MPI;

        oc = ++freqs_count;
    }
}

void InitFreqs2(float time)
{
    int oc = freqs_count = 0;
    lastrandom = floor(time*timescale) + 4.0;
    for (int i = 0; i < MAX_FREQS; i++)
    {
        freqs2[oc].a = nextrandom(float(i*5 + 0) / 5.0);
        freqs2[oc].xfreq = (nextrandom(float(i*5 + 1) / 5.0)*2.0 - 1.0) * (1.0 - freqs2[oc].a) * (float(MAX_FREQS));
        freqs2[oc].yfreq = (nextrandom(float(i*5 + 2) / 5.0)*2.0 - 1.0) * (1.0 - freqs2[oc].a) * (float(MAX_FREQS));
        freqs2[oc].phase = nextrandom(float(i*5 + 3) / 5.0) * 2.0 * MPI;

        oc = ++freqs_count;
    }
}

void main(void)
{
    InitFreqs(time);
    InitFreqs2(time);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float value = 0.0;
    
    for (int oi = 0; oi < freqs_count; oi++)
    {
        value += freqs[oi].a * sin(freqs[oi].xfreq * uv.x + freqs[oi].yfreq * uv.y);
    }

    float value2 = 0.0;
    
    for (int oi = 0; oi < freqs_count; oi++)
    {
        value2 += freqs2[oi].a * sin(freqs2[oi].xfreq * uv.x + freqs2[oi].yfreq * uv.y);
    }
    

    vec3 col1 = vec3(0.2, 0.6, 0.01);
    vec3 col2 = vec3(0.02, 0.3, 0.001);
    vec3 col3 = vec3(0.5, 0.7, 0.03);
    vec3 col4 = vec3(0.03, 0.01, 0.000);
    vec3 col = value < 0.0 ? value2 < 0.0 ? col1 : col3 : value2 < 0.0 ? col2 : col4;
    // Output to screen
    glFragColor = vec4(col,1.0);
}
