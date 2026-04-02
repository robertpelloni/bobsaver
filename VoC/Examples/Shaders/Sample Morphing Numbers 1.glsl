#version 420

// original https://www.shadertoy.com/view/XsGGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float segment(vec2 uv)
{
    uv = abs(uv);
    float f = max(0.45+uv.x,0.225+uv.y+uv.x);
    return f;
}

float sevenSegment(vec2 uv,int num)
{
    float seg= 5.0;
    seg = (num!=-1 && num!=1 && num!=4                    ?min(segment(uv.yx+vec2(-0.450, 0.000)),seg):seg);
    seg = (num!=-1 && num!=1 && num!=2 && num!=3 && num!=7?min(segment(uv.xy+vec2( 0.225,-0.225)),seg):seg);
    seg = (num!=-1 && num!=5 && num!=6                    ?min(segment(uv.xy+vec2(-0.225,-0.225)),seg):seg);
    seg = (num!=-1 && num!=0 && num!=1 && num!=7          ?min(segment(uv.yx+vec2( 0.000, 0.000)),seg):seg);
    seg = (num==0 || num==2 || num==6 || num==8           ?min(segment(uv.xy+vec2( 0.225, 0.225)),seg):seg);
    seg = (num!=-1 && num!=2                              ?min(segment(uv.xy+vec2(-0.225, 0.225)),seg):seg);
    seg = (num!=-1 && num!=1 && num!=4 && num!=7          ?min(segment(uv.yx+vec2( 0.450, 0.000)),seg):seg);
    
    return seg;
}

float sevenSegmentFloat(vec2 uv, float num, float digit) {
    float start = 1.0-.9/pow(6.,digit);
    float m = smoothstep(start,1.0,fract(num));
    if (m<0.01)
        return sevenSegment(uv,int(num));
    else {
        float s1 = sevenSegment(uv,int(num));
        float s2 = sevenSegment(uv,int(mod(num+1.0,10.)));
        m = sin(pow(m,2.5)*2.2)/sin(2.2);
        return 1.0/mix(1.0/s1, 1.0/s2, m);
    }
}

float curveFract(float x) {
    float f = fract(x);
    f = 1.0-cos(f*3.1416);
    return floor(x)+f*.4999;
}

float log10 = log(10.0);
float showNum(vec2 uv,float nr, bool zeroTrim)
{
    bool neg = nr<0.0;
    if (neg) nr *= -1.;
    
    float digitCount = max(1.0,log(nr)/log10+.000001+1.0);
    float seg= 5.0;
    
    // Center number
    float dc = curveFract(digitCount)-0.5;
                // ATempt to center 1 +0.5*smoothstep(0.0,2.0,nr / pow(10.,floor(digitCount)-1.0));
    uv *= (4.+dc)*.25;
    uv.x -= dc * .375 + uv.y * 0.07;
    
    digitCount = floor(digitCount);
    if (uv.x>-5.25 && uv.x<0.0 && abs(uv.y)<0.75)
    {
        float digit = floor(-uv.x / .75);
        nr /= pow(10.,digit);
        nr = mod(nr,10.0);
        if (neg && digit==digitCount)
            nr = -2.;
        else
            if (floor(nr)<=0. && zeroTrim && digit>=digitCount && digit!=0.0)
                nr = -1.0;
        seg = sevenSegmentFloat(uv+vec2( 0.375 + digit*.75,0.0),nr,digit);
    }
    return seg;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy) / resolution.y *1.1;
    glFragColor = vec4(0.0);
   
    //float nr = sevenSegmentFloat( uv, mod(time,10.0));
    //float nr = showNum(uv,(1.0+sin(time*.25))*1005.5,true);
    float nr = showNum(uv,time*10.,true);
    glFragColor.r = 1.0-smoothstep(0.49,0.5, nr);
    //glFragColor.r = (1.0-smoothstep(0.49,0.5, nr))*texture2D(iChannel0,gl_FragCoord/resolution.xy).r;
}
