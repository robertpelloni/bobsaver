#version 420

// original https://www.shadertoy.com/view/llGfRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// yx's commodore shape from here - https://www.shadertoy.com/view/4lGfzK
//
// Raymarched by Del 25/11/2018

float cbm(vec2 p)
{
    const float A = 10.;
    const float B = 0.034 * A;
    const float C = 0.166 * A;
    const float E = 0.364 * A;
    const float F = 0.52 * A;
    const float G = 0.53 * A;
    const float H = 0.636 * A;
    const float I = 0.97 * A;
    
    p.y = abs(p.y);
    
    float outerCircle = length(p)-I*.5;
    float innerCircle = length(p*vec2(F/G,1))-F*.5;
    float verticalMask = p.x-(H-I*.5);
    
    float topMask = p.y-C-B*.5;
    float bottomMask = p.y-B*.5;
    float angleMask = ((p.x-p.y)-A+I*.5+E*.5)/sqrt(2.);
    
    float vents = max(max(angleMask,max(topMask,-bottomMask)), -verticalMask);
    
    float ring = max(max(outerCircle,-innerCircle),verticalMask);
    
    return min(vents, ring);
}

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}
#define    TAU 6.28318

float map(vec3 p)
{
    float time = time+0.2;
    p.z -= 13.0+sin(fract(time*0.15)*TAU)*2.0;
    
    float twist = 0.5+sin(fract(time*0.25)*TAU)*0.5;
    twist *= p.y * 0.1;
    p.xz *= rotate(twist+fract(time*0.26)*TAU);
    
    float dist = cbm(p.xy);
    
    float dep = 0.5;
    vec2 e = vec2( dist, abs(p.z) - dep );
    dist = min(max(e.x,e.y),0.0) + length(max(e,0.0));
    dist -= 0.07;
    return dist;
}

// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ.
vec3 normal( in vec3 p )
{
    // Note the slightly increased sampling distance, to alleviate
    // artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.0025, -0.0025); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}
vec3 render(vec2 uv)
{
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(uv, 1.95));
    vec3 p = vec3(0.0);
    float t = 0.;
    for (int i = 0; i < 100; i++)
    {
        p = ro + rd * t;
        float d = map(p);
        if (d < .001 || t > 100.) break;
        t += d *0.75;
    }
    
    vec3 c = vec3(0.35,0.35,0.45);
    c*= 1.2-abs(uv.y);
    
    if (t<100.0)
    {
           vec3 lightDir = normalize(vec3(1.0, 1.0, 0.5));
        vec3 nor = normal(p);

        float dif = max(dot(nor, lightDir), 0.0);
        c = vec3(0.5) * dif;

        float tf = 0.02;
        c += vec3(0.65,0.6,0.25) + reflect(vec3(p.x*tf, p.y*tf,tf), nor);

        vec3 ref = reflect(rd, nor);
        float spe = max(dot(ref, lightDir), 0.0);
        c += vec3(2.0) * pow(spe, 32.);
    }

    c *= 1.0 - 0.3*length(uv);
    return c;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.);
}

