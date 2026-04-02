#version 420

// original https://www.shadertoy.com/view/MdcGW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// initial inspiration:
// http://static1.squarespace.com/static/53c9cdf3e4b0669c8d19e691/53ffa2f8e4b048b8b84fef6f/53ffa473e4b0f2e23aea116f/1409262727455/MagnetoLayer+2013-06-14-00-13-54-324.gif?format=500w
    
const float bandSpacing = .02;
const float lineSize = 0.01;
const float segmentLength = .3;
#define WARP

float rand(float n){
    return fract(cos(n*89.42)*343.42);
}
float round(float x, float p)
{
    return floor((x+(p*.5))/p)*p;
}
float dtoa(float d, float amount)
{
    return clamp(1./(clamp(d,1./amount,1.)*amount),0.,1.);
}
float sdSegment1D(float uv, float a, float b)
{
    return max(max(a - uv, 0.), uv - b);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x*=resolution.x/resolution.y;
    
    #ifdef WARP
    // warp the hell out of the uv coords
    vec2 oldUV = uv;
    uv = pow(abs(uv), sin(time*vec2(.2,.7))*.35+1.)*sign(oldUV);
    #endif

    float bandRadius = round(length(uv),bandSpacing);
    vec3 bandID = vec3(rand(bandRadius),rand(bandRadius+1.),rand(bandRadius+2.));

    float distToLine = sdSegment1D(length(uv), bandRadius-(lineSize*.5), bandRadius+(lineSize*.5));
    float bandA = dtoa(distToLine, 400.);// alpha around this band.
    
    float bandSpeed = .1/max(0.05,bandRadius);// outside = slower
    float r = -3.*time+bandID.x *6.28;
    r *= bandSpeed;
    uv *= mat2(cos(r),sin(r),-sin(r),cos(r));

    float angle = mod(atan(uv.x,uv.y),6.28);// angle, animated
    float arcLength = bandRadius * angle;
    
    float color = sign(mod(arcLength, segmentLength*2.)-segmentLength);

    glFragColor = vec4(vec3(bandID * color * bandA),1);
}

