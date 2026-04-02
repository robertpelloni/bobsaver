#version 420

// original https://www.shadertoy.com/view/XsGGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float lineWidth = 6.0/resolution.x;

float segment(vec2 uv)
{
    uv = abs(uv);
    
    //Round edges
    uv.y = max(uv.y-0.225, 0.);
    float f = length(uv)+.43;
    
    //Bevel edges
    //float f = max(0.45+uv.x,0.225+uv.y+uv.x);
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
    float start = 1.0-.9/pow(9.,digit);
    float m = smoothstep(start,1.0,fract(num));
    if (m<0.01)
        return sevenSegment(uv,int(num));
    else {
        float s1 = sevenSegment(uv,int(num));
        float s2 = sevenSegment(uv,int(mod(num+1.0,10.)));
        m = sin(pow(m,2.5)*2.35)/sin(2.35);
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
                // Attempt to center one +0.5*smoothstep(0.0,2.0,nr / pow(10.,floor(digitCount)-1.0));
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

vec3 getFrameColor(vec2 uv, float gt) {
    //float nr = showNum(uv,gt*(10.-9.8*mouse.xy*resolution.xy/resolution.x),true);
    float nr = showNum(uv,gt,true);
    
    vec3 clr = vec3(0.0);
    clr.g = 0.8-0.8*smoothstep(0.00,lineWidth, abs(nr-0.49)); // Yellow outline
    clr.r = 0.8-0.8*smoothstep(0.49,0.49+lineWidth, nr); // The numbers
    clr.b += 0.4-0.4*smoothstep(0.45,0.52,1.0-nr); // Background with shadow
    clr.rg += 0.25-0.25*pow(smoothstep(0.00,0.1, abs(nr-0.49)),0.25); // Yellow glow
    clr += 0.12-0.12*smoothstep(0.40,0.45, nr); // Stretchmarks
    return clamp(clr,0.0,1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy) / resolution.y;
    
    //float gt = 200.+mouse*resolution.xy.x*0.1;//time;
    float gt = time;
    vec3 clr = vec3(0.0);
    
    for (float i = 0.0; i < 16.0; i += 1.0)
        clr += pow(getFrameColor(uv, gt+i/700.),vec3(1.5))*(i+1.0);
    glFragColor = vec4(pow(clr/136.,vec3(1.0/1.5)),1.0);
    //glFragColor = vec4(getFrameColor(uv, gt),1.0);
    /*
    for (float i = 0.0; i < 16.0; i += 1.0)
        clr += getFrameColor(uv, gt+i/1000.)*(i+1.0);
    glFragColor = vec4(clr/136.,1.0);
*/
}
