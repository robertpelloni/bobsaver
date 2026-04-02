#version 420

// original https://www.shadertoy.com/view/flXyRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
#define sabs(x) sqrt(x*x+0.0001)
//#define sabs(x, k) sqrt(x*x+k)-0.1

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

float cc(float a, float b) {
    float f = thc(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float cs(float a, float b) {
    float f = ths(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21(vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

float mlength(vec3 uv) {
    return max(max(abs(uv.x), abs(uv.y)), abs(uv.z));
}

float smin(float a, float b)
{
    float k = 0.03;
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    // How far squares travel before stopping etc
    float rep = 3. * pi;
    
    // Stop-Start time (a is time, since you can't spell "time" without "a")
    float m = min(mod(time, rep), 0.5 * rep);
    float a = -pi + rep * floor(time/rep) 
                  + rep * smoothstep(0., 0.5 * rep, m);
    
    // Amplitude of sin wave
    float c = 0.8 * cos(0.4 * time);
    
    // Scale + translate uv 
    float sc = 4.5; // + cos(resolution.y * 3. * uv.x);
    uv *= sc;
    uv.y += 0.25;
    uv.x += c + mix(a, time, 0.5);
    
    // Smallest square size
    float r = 0.025;
    // Square outline width
    float w = 0.02;// + 0.01 * thc(8., time + 20. * uv.x);
    
    // Draw sin wave
    float k = sc / resolution.y;
    float s = 1. - 0.98 * smoothstep(-k, k, abs(-uv.y + c * cos(uv.x)) - w);
    
    vec3 e = vec3(0.5);
    vec3 col = vec3(s);
    
    float n = 40.;   
    for (float i = n - 1.; i >= 0.; i--) {
        // Offset time for each square
        a += mix(-1., 1., 0.5 - 0.5 * cos(time + i * pi / 400.)) * pi / n;
        
        // Rescale each square
        //r *= 1.08;
        r = mix(0.05, 0.4, cos(a + time + 1. * pi * i / n) * 0.5 + 0.5);
        
        // sgn determines which side of the sin wave the boxes are on
        float sgn = -1.;
        
        // sq is a constant used for finding the normal to the wave
        // (mix between 1 and sqrt(2) so the box "bounces" correctly-ish)
        float mx = mix(1., sqrt(2.), abs(ths(1., 2. * a + 4. * time)));
        float sq = mx * sgn * (r + 0.5 * w) / sqrt(c * c * sin(a) * sin(a) + 1.);
        
        // First vector is point on wave, 2nd vector is normal
        vec2 p = vec2(a, c * cos(a)) - sq * vec2(c * sin(a), 1.); 

        // Translate + rotate uv to p
        vec2 uv2 = (uv - p) * Rot(a + c * sin(a));
        
        // Draw box
        float box = w - abs(sdBox(uv2, vec2(0.8 * r - 0.5 * w)) - 0.2 * r);
        s = (i/40.) * smoothstep(-k, k, box);
        
        vec3 col2 = pal(0.5 * a + i/n * 2., e, e, e, 0.5 * vec3(0,1,2)/3.);
        col2 = vec3(1.); // uncomment me for colors
        col = mix(col, col2, s);
    }
    
    // Lighten the colors
    col = sqrt(col);

    //col += 0.25 * step(abs(uv.y - c * cos(a) + c * sin(a) * (uv.x - a)), 0.04);
    
    glFragColor = vec4(col,1.0);
}
