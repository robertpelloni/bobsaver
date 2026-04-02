#version 420

// original https://www.shadertoy.com/view/4tdfRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718
#define PI 3.14159265

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

mat2 rot(in float theta)
{
    return mat2(cos(theta),-sin(theta), sin(theta), cos(theta));
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

void main(void)
{
    // Normalized pixel coordinates (from -0.5 to 0.5)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = vec2(0.5) - uv;
    uv.x *= resolution.x/resolution.y;
    uv.y -= 0.1;
    
    vec2 noisevec = vec2(
        noise(uv+ time*0.5),
        noise(uv*rot(0.5) + time*0.5+ 1.554));
        
    float triDist = sdEquilateralTriangle((noisevec*0.05+uv)*rot(PI));
    vec3 col = vec3(smoothstep(0.,1.,sin(triDist*(200. + sin(time*0.2)*50.))));
    col *= smoothstep(1.,0.,sdEquilateralTriangle((uv*2.)*rot(PI))*25.);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
