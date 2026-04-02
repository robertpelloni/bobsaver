#version 420

// original https://www.shadertoy.com/view/tsSyDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM_OCTAVES 5

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// https://www.iquilezles.org/www/articles/warp/warp.htm
float pattern( in vec2 p )
{
    vec2 q = vec2( fbm( p + vec2(0.0,0.0) ),
                   fbm( p + vec2(5.2,1.3) ) );

    return fbm( p + 4.0*q );
}

vec3 colour(float x) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.0, 0.0);
    
    return a + b * cos(6.28318*(c*x+d));
}

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = 0.7*abs(2.0*(uv-0.5));
    uv.y += uv.x / 10.0;

    float noise = fbm(time*0.2+uv*10.0) / 4.0;
    float noiseTex = pattern(rotate(uv*10.0*(1.0+(0.05*sin(time*0.5))), time*0.01)) * 0.5+cos(0.2*time+sin(time)*0.2);
    
    float inside = (sin((uv.x+uv.y))*10.0) + (uv.y*10.0+uv.x*10.0);
    float mask = (uv.y*2.0 + sin(inside)) / 1.5;
    
    vec3 col = colour(noiseTex+mask);
    col.rg += -abs(rotate(uv, 0.3*time+noise*10.0).xy);

    glFragColor = vec4(col,1.0);
}
