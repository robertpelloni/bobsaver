#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3slyWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define TWO_PI 6.28318530

uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}
uint hash( uvec2 v ) { 
    return hash( v.x ^ hash(v.y)); 
}

float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}
float random( vec2  v ) { 
    return floatConstruct(hash(floatBitsToUint(v)));
}

float noise(vec2 uv){
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float noise( vec2 uv, float detail){
    float n = 0.;
    float m = 0.;

    for(float i = 0.; i < detail; i++){
        float x = pow(2., i);
        float y = 1./x;
        
        n += noise(uv*x+y)*y;
        m += y;
    }
    
    return n/m;
    
}
mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 selectColor(float b){
    float n = 4.;
    vec3 cols[5];
    cols[0] = vec3( 0.9490196078431372, 0.5686274509803921, 0.23529411764705882);
    cols[1] = vec3( 0.2627450980392157, 0, 0.39215686274509803);
    cols[2] = vec3( 0.8784313725490196, 0.08627450980392157, 0.4823529411764706);
    cols[3] = vec3( 0, 0.7137254901960784, 0.7372549019607844);
    cols[4] = vec3( 1, 0.5019607843137255, 0);
    
    float i = floor(b*n);
    float f = fract(b*n);
    f = f*f*(3.-2.*f);
    int i1 = int(i);
    int i2 = int(i) + 1;
    vec3 col = mix(cols[i1], cols[i2], f);
    //col = col*col*(3.0-2.0*col);
    
    return col;
    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec2 gv = vec2(length(uv), atan(uv.y, uv.x)+time*.5);
    //gv.y += gv.x*.5*sin(time*.1);
    gv.y = (gv.y+PI)/TWO_PI;
    
    gv.y = abs(fract(gv.y*5.)-.5);
    gv.x *= 1.;
    gv.x += sin(time*.05)*sin(time*.08+.4)*7.-7.;
    
    gv *= rot(noise(gv,2.));
    float n = noise(gv*5., 1.);
    vec3 col = selectColor(n*n);//hsv2rgb(vec3(n*n,1.,1.));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
