#version 420

// original https://www.shadertoy.com/view/4tdBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718
#define PI 3.14159265
#define palette(t) pal(t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) )

// http://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdEquilateralTriangle( in vec2 p )
{
    const float k = sqrt(3.0);
    
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = vec2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
                 43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
        (c - a)* u.y * (1.0 - u.x) +
        (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

mat2 rot(in float theta)
{
    return mat2(cos(theta),-sin(theta), sin(theta), cos(theta));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = vec2(0.5) - uv;
    uv.x *= resolution.x/resolution.y;
    
    float rotime = time*0.2;
    
    float theta = atan(uv.y,uv.x);
    
    vec2 fuv = uv*rot(rotime);
    vec2 fbm1 = vec2(fbm(fuv), fbm(fuv + time*0.1 + 0.2));
    vec2 fbm2 = vec2(fbm(fuv + fbm1.x + 0.120*time), fbm(uv + fbm1.y - 0.220*time) );
    
    float radius = sdEquilateralTriangle(uv*rot(PI)*3.);
    
    float thmod = (theta+fbm2.x*fbm2.y*1.0/(radius))/PI + 1.;
    
    
    
    vec3 fbmColor = palette(thmod + fbm2.y) * (fbm2.x*fbm2.x*fbm2.x*fbm2.x +0.7);
    fbmColor = mix(fbmColor, vec3(1.,1.,1.), 0.2);
    vec3 col = smoothstep(0.,1.,radius*35.) * fbmColor;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
