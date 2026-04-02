#version 420

// original https://www.shadertoy.com/view/WdlSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ROOT2 1.4142136
#define PI 3.14159265
#define aa 15.0/min(resolution.x, resolution.y)

const float numOfTilesY = 5.0;

// palette by Inigo Quilez
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 color(float c) {
    // 0.0 < c < 1.0 covers the full palette
    return pal( c, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float vnoise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    
    // distort the uv plane with a shift per pixel
    float noise = 2.0*PI*vnoise(0.5*numOfTilesY*uv+0.2*time);
    vec2 shift = .02 * vec2(cos(noise), sin(noise));
    uv += shift;

    // tile the image
    uv *= numOfTilesY;
    vec2 fuv = fract(uv); // fractional part within til, runs from 0-1
    vec2 iuv = floor(uv); // integer index vector of tile
    
    // distance function to the edges of the tiles, based on the fractional part
    vec2 dist = 1.0-2.0*abs(fuv);
    
    vec3 col = vec3(0.0);
    
    // parameters for moving two layers of circles around, using the integer part of the tiles
    float phase1 = 10.0*random(iuv);
    vec2 shapeShift1 = 0.2*vec2(cos(time+phase1),sin(time+phase1));
    float phase2 = -4.3*random(iuv);
    vec2 shapeShift2 = 0.3*vec2(cos(2.*time+phase2),sin(time+phase2));
    
    col = mix (color(iuv.y/numOfTilesY+0.1).xyz, col , 1.0-smoothstep(0.1, 0.1+aa, 1.0-length(dist)));
    col = mix (color(0.4*iuv.x/numOfTilesY+0.1).xyz, col , 1.0-smoothstep(0.4, 0.4+aa, 1.0-length(dist+shapeShift1)));
    col = mix (color(0.5*(iuv.x+iuv.y)/numOfTilesY+0.2).xyz, col , 1.0-smoothstep(0.6, 0.6+aa, 1.0-length(dist+shapeShift2)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
