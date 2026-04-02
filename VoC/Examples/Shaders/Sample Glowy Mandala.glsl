#version 420

// original https://www.shadertoy.com/view/tsdyDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define res resolution

float t;

const int colorsPerGradient = 6;

//--------------------------------------GRADIENT-----------------------------------
//--------------------------------color point array logic--------------------------
//-------------------------------------by Krabcode---------------------------------

struct colorPoint
{
    float pos;
    vec3 val;
};

colorPoint emptyColorPoint()
{
    return colorPoint(1.1, vec3(1.,0.,0.));
}

float map(float value, float start1, float stop1, float start2, float stop2)
{
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
}

float norm(float value, float start, float stop)
{
    return map(value, start, stop, 0., 1.);
}

int findClosestLeftNeighbourIndex(float pos, colorPoint[colorsPerGradient] gradient)
{
    for(int i = 0; i < 100; i++){
        if(pos >= gradient[i].pos && pos <= gradient[i+1].pos){
            return i;
        }
        if(i >= gradient.length()){
            return 0;
        }
    }
    return 0;
}

vec3 gradientColorAt(float normalizedPos, colorPoint[colorsPerGradient] gradient)
{
    float pos = clamp(normalizedPos, 0., 1.);
    int leftIndex = findClosestLeftNeighbourIndex(pos, gradient);
    int rightIndex = leftIndex + 1;
    colorPoint A = gradient[leftIndex];    
    colorPoint B = gradient[rightIndex];
    float normalizedPosBetweenNeighbours = norm(pos, A.pos, B.pos);
    return mix(A.val, B.val, normalizedPosBetweenNeighbours);
}

vec3 hexToRgb(int color)
{
    float rValue = float(color / 256 / 256);
    float gValue = float(color / 256 - int(rValue * 256.0));
    float bValue = float(color - int(rValue * 256.0 * 256.0) - int(gValue * 256.0));
    return vec3(rValue / 255.0, gValue / 255.0, bValue / 255.0);
}

vec3 gammaCorrect(vec3 rgb)
{
    return pow(smoothstep(0., 1., rgb), vec3(1.0/2.2));
}

vec4 gammaCorrect(vec4 rgba)
{
    return vec4(gammaCorrect(rgba.rgb), 1.);
}

// find some cool gradients at https://colorhunt.co/

/*
colorPoint[colorsPerGradient] gradient = colorPoint[](
        colorPoint(0.00, hexToRgb(0x6a2c70)),
        colorPoint(0.25, hexToRgb(0xb83b5e)),
        colorPoint(0.50, hexToRgb(0xf08a5d)),
        colorPoint(0.75, hexToRgb(0xeeecda)),
        colorPoint(1.00, hexToRgb(0xeeecda)));
*/

float cubicPulse( float c, float w, float x )
{
    x = abs(x - c);
    if( x>w ) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}

float getSine(float x, float y){
    y += .5   *sin(0.8*x+y*6.);
    y += .25  *sin(1.2*x-y*6.+t);
    y += .125 *sin(2.9*x+y+t*.8);
    y += .015 *sin(4.9*x+y+t*1.34);
    return y;
}

float getSineNeighboursSum(vec2 cv){
    float sum = 0.;
    cv.y = fract(cv.y*4.)+.5;
    for(float y = cv.y-2.; y <= cv.y+1.; y++){
       sum += cubicPulse(0., .4, abs(getSine(cv.x, y)));
    }
    return sum;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 cv = (gl_FragCoord.xy - .5 * res.xy) / res.y;
    colorPoint[colorsPerGradient] gradient = colorPoint[](
        colorPoint(0.0, hexToRgb(0x6a2c70)*.1),
        colorPoint(0.2, hexToRgb(0x6a2c70)),
        colorPoint(0.5, hexToRgb(0xb83b5e)),
        colorPoint(0.75, hexToRgb(0xf08a5d)),
        colorPoint(1., hexToRgb(0xeeecda)),
        colorPoint(1., hexToRgb(0xeeecda))
    );

    t = time;
    vec2 mandalaCoord = vec2(cos(12.*atan(cv.y, cv.x)), length(cv));
    float y = getSineNeighboursSum(mandalaCoord);
    y = pow(y, 1.0);
    vec3 col = gradientColorAt(y, gradient);
    glFragColor = vec4(gammaCorrect(col),1.0);
}
