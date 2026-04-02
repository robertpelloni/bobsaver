#version 420

// original https://www.shadertoy.com/view/3dffz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//width of lines
#define _Width 0.05    

//width of the borders of the lines
#define _Border 0.003    

//frequency of the noise
#define _NoiseFreq 50.0

//strength of the noise
#define _NoiseStr 0.01    

//speed of the "simulation"
#define _Speed 5.0

//portion of the time(from 0 to 1), that will be spent on "growing" the line
//rest of the time will be spent "widening" the line
#define _GT 0.5    

float hash( float n )
{
    n = mod(n, 691.564);
    return fract(sin(n)*43758.5453);
}

float perlin(float x) {
    float f = fract(x);
    float i = floor(x);
    return mix(hash(i), hash(i+1.0), smoothstep(0.0, 1.0, f));
}

vec2 hash2( vec2 p )
{
    p = mod(p, 132.5);
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

float drawLine(inout vec2 uv, inout float draw, float i, float f) {
    float grow = saturate(f/_GT);
    float widen = saturate((f-_GT)/(1.0-_GT))*_Width;

    vec2 norm = hash2(vec2(i, i*1.1))-0.5;
    vec2 nnorm = normalize(norm);

    uv -= norm;

    uv = mat2x2(nnorm.x, nnorm.y, -nnorm.y, nnorm.x) * uv;
    float per = (perlin((uv.y+i)*_NoiseFreq)-0.5)*_NoiseStr;

    uv.x += per;

    float tx = uv.x - (step(0.0, uv.x)-0.5)*widen;

    float ans = draw*smoothstep(_Border+0.003, _Border, abs(tx))*step(uv.y, mix(-2.0, 2.0, grow));
    draw = saturate(draw - step(2.0*abs(uv.x), widen));
    uv.x = tx - per;

    uv = mat2x2(nnorm.x, -nnorm.y, nnorm.y, nnorm.x) * uv;
    uv += norm;

    return ans;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    
    float tim = (time)*_Speed;
    float timei = floor(tim);
    float timef = fract(tim);

    float bord = 0.0;
    float draw = 1.0;

    bord += drawLine(uv, draw, timei, timef);

    timei -= 1.0;

    for(float i = 0.0; i < 500.0; i++) {
        bord += drawLine(uv, draw, timei-i, 1.0);
        if(draw < 0.5) break;
    }
    
    glFragColor = vec4(bord, bord, bord, 1.0);
}
