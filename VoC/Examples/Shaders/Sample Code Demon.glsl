#version 420

// original https://www.shadertoy.com/view/tlyGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define MAX_DIM (max(resolution.x,resolution.y))

#define MATRIX_W (floor(MAX_DIM/75.0))
#define MATRIX_H (floor(MAX_DIM/75.0))

//-----------------UTILITY MACROS-----------------

#define time ((sin(float(__LINE__))/PI/GR/E+1.0/GR/PI)*time+1000.0)
#define saw(x) (acos(cos(x))/PI)
#define sphereN(uv) (clamp(1.0-length(uv*2.0-1.0), 0.0, 1.0))
#define zero(x) (smoothstep(-1.0/GR/PI/E, 1.0/GR/PI/E, x))
#define clip(x) (smoothstep(0.25, .75, x))
#define TIMES_DETAILED (1.0)
#define angle(uv) (atan(uv.y, uv.x))
#define angle_percent(uv) ((angle(uv)/PI+1.0)/2.0)
#define hash(p) (fract(sin(vec2( dot(p,vec2(127.5,313.7)),dot(p,vec2(239.5,185.3))))*43458.3453))

#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)
#define rormal(x) (normalize(sin(vec3(time, time/GR, time*GR)+seedling)*.25+.5))
#define rotatePoint(p,n,theta) (p*cos(theta)+cross(n,p)*sin(theta)+n*dot(p,n) *(1.0-cos(theta)))

//-----------------SEEDLINGS-----------------------
float seedling = 0.0;
float stretch;
vec2 targetResolution = vec2(512.0);

//-----------------AUDIO ALGORITHM-----------------

float lowAverage()
{
    const int iters = 32;
    float product = 1.0;
    float sum = 0.0;
    
    float smallest = 0.0;
    
    for(int i = 0; i < iters; i++)
    {
        float sound = 0.0;//texture(iChannel0, vec2(float(i)/float(iters), 0.5)).r;
        smallest = 
        
        product *= sound;
        sum += sound;
    }
    return max(sum/float(iters), pow(product, 1.0/float(iters)));
}

//-----------------SIMPLEX ALGORITHM-----------------

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187, // (3.0-sqrt(3.0))/6.0
                        0.366025403784439, // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626, // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i = floor(v + dot(v, C.yy) );
    vec2 x0 = v - i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                     + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
{
    const vec2 C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i = floor(v + dot(v, C.yyy) );
    vec3 x0 = v - i + dot(i, C.xxx) ;

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );

    // x0 = x0 - 0.0 + 0.0 * C.xxx;
    // x1 = x0 - i1 + 1.0 * C.xxx;
    // x2 = x0 - i2 + 2.0 * C.xxx;
    // x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy; // -1.0+3.0*C.x = -0.5 = -D.y

    // Permutations
    i = mod289(i);
    vec4 p = permute( permute( permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
                              + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
                     + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z); // mod(p,7*7)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ ); // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                 dot(p2,x2), dot(p3,x3) ) );
}
//-----------------BASE IMAGE--------------------------

#define R(r)  fract( 4e4 * sin(2e3 * r) )  // random uniform [0,1[
vec4 stars(vec2 uv)
{
    vec4 stars = vec4(0.0);
    for (float i = 0.; i < 32.0; i ++)
    {
        float r = R(i)/ 256.0         // pos = pos(0)  +  velocity   *  t   ( modulo, to fit screen )
        / length( saw( R(i+vec2(.1,.2)) + (R(i+vec2(.3,.5))-.5) * time ) 
                 - saw(uv) );
        stars += r*vec4(flux(r*PI+i), 1.0);
    }
    
    return stars-1.0/16.0;
}

vec4 galaxy(vec2 uv)
{
    vec2 uv0 = uv;
    float r = length(uv);
    uv *= 5.0*(GR);
    
    
    float r1 = log(length(uv)+1.)*2.0;
    float r2 = pow(log(length(uv)+1.)*3.0, .5);
    
    float rotation = time*PI*2.0;
    
    float theta1 = atan(uv.y, uv.x)-r1*PI+rotation*.5+seedling;
    float theta2 = atan(uv.y, uv.x)-r2*PI+rotation*.5+seedling;
    
    vec4 color = vec4(flux((seedling*GR+1.0/GR)*time/GR), 1.0);
    
    vec4 final = acos(1.0-(cos(theta1)*cos(theta1)+sqrt(cos(theta1+PI)*cos(theta1+PI)))/2.0)*(1.0-log(r1+1.))*color
              + cos(1.0-(cos(theta2)*cos(theta2)+cos(theta2+PI/2.)*cos(theta2+PI/2.))/2.0)*(1.25-log(r2+1.))*color;
         
    final.rgba += color;
    
    final /= r1;
    final *= 2.0;
    final -= .25;
    
    final = sqrt(clamp(final, 0.0, 1.0));
    
    float weight = clamp(length(clamp(final.rgb, 0.0, 1.0)), 0.0, 1.0);
    return final*smoothstep(0.0, 1.0/GR/PI/E, 1.0-r);
}

//-----------------IMAGINARY TRANSFORMATIONS-----------------

vec2 cmul(vec2 v1, vec2 v2) {
    return vec2(v1.x * v2.x - v1.y * v2.y, v1.y * v2.x + v1.x * v2.y);
}

vec2 cdiv(vec2 v1, vec2 v2) {
    return vec2(v1.x * v2.x + v1.y * v2.y, v1.y * v2.x - v1.x * v2.y) / dot(v2, v2);
}

vec2 mobius(vec2 uv, vec2 multa, vec2 offa, vec2 multb, vec2 offb)
{
    vec2 numerator = cmul(uv, multa) + offa;
    vec2 denominator = cmul(uv, multb) + offb;
    
    //numerator /= (abs(denominator)+1.0);
    
    vec2 quotient = (cdiv(numerator, denominator));
    
    for(int i = 0 ; i < 4; i++)
    {
        numerator = cmul(uv, multa) + offa+sin(vec2(float(i)-time*GR, -float(i)+time));
        quotient += (cdiv(numerator, quotient));
    }
    
    
    
    vec2 next = quotient;

    float denom = length(fwidth(uv));//max(fwidth(uv.x),fwidth(uv.y));
    denom += 1.0-abs(sign(denom));

    float numer = length(fwidth(next));//min(fwidth(next.x),fwidth(next.y));
    numer += 1.0-abs(sign(numer));

    stretch = denom/numer;
    
    seedling = (floor(quotient.x)*3.0+floor(quotient.y));
    
    return quotient;
}

//-----------------ITERATED FUNCTION SYSTEM-----------------

vec2 iterate(vec2 uv, vec2 dxdy, out float magnification, vec2 multa, vec2 offa, vec2 multb, vec2 offb)
{
    vec2 a = uv+vec2(0.0,         0.0);
    vec2 b = uv+vec2(dxdy.x,     0.0);
    vec2 c = uv+vec2(dxdy.x,     dxdy.y);
    vec2 d = uv+vec2(0.0,         dxdy.y);//((gl_FragCoord.xy + vec2(0.0, 1.0)) / resolution.xy * 2.0 - 1.0) * aspect;

    vec2 ma = mobius(a, multa, offa, multb, offb);
    vec2 mb = mobius(b, multa, offa, multb, offb);
    vec2 mc = mobius(c, multa, offa, multb, offb);
    vec2 md = mobius(d, multa, offa, multb, offb);
    
    float da = length(mb-ma);
    float db = length(mc-mb);
    float dc = length(md-mc);
    float dd = length(ma-md);
    
    magnification = stretch;
    
    vec2 final = mobius(uv, multa, offa, multb, offb);
    
    return final;
}
    

float getEyes(vec2 uv)
{
    vec2 p = uv;

    p.y += 1.0/PI;

    p.x *= GR;

    vec4 a = vec4(-1.0/GR, 1.0/GR, 0, 0);
    vec4 b = vec4(1.0/GR, 1.0/GR, 0, 0);

    p.y += cos(uv.x*(7.0+saw(time)))/PI;

    float distA = length(p.xy-a.xy);
    float distB = length(p.xy-b.xy);

    float fade_lengthA = .20;
    float fade_lengthB = .20;

    float color = clamp((1.0-distA/fade_lengthA)*distB, 0.0, 1.0)
                  +clamp((1.0-distB/fade_lengthB)*distA, 0.0, 1.0);
    return color;
}

float getTeeth(vec2 uv)
{
    vec2 p = uv;
    p.x *= PI;
    p.y *= PI*(cos(p.x/PI/PI));
    p.y += 1.5*cos(p.x)+1.0;
    p.y *= (sin(time*PI*20.0+seedling))*.25+2.0;

    float r = p.x*p.x+p.y*p.y;
    
    float xy = sin(p.x*PI*10.0)+cos(p.y*3.0+PI);

    return clamp(clamp((3.0/(r*r*r)-p.y*p.y), 0.0, 1.0)*xy, 0.0, 1.0);
}

vec3 demon(vec2 uv)
{
    float eyes = getEyes(uv);
    float teeth = getTeeth(uv);
    
    return vec3(clamp(eyes+teeth, 0.0, 1.0));
}

const float kCharBlank = 12.0;
const float kCharMinus = 11.0;
const float kCharDecimalPoint = 10.0;
float SampleDigit(const in float fDigit, const in vec2 vUV)
{        
    if(vUV.x < 0.0) return 0.0;
    if(vUV.y < 0.0) return 0.0;
    if(vUV.x >= 1.0) return 0.0;
    if(vUV.y >= 1.0) return 0.0;
    
    // In this version, each digit is made up of a 4x5 array of bits
    
    float fDigitBinary = 0.0;
    
    if(fDigit < 0.5) // 0
    {
        fDigitBinary = 7.0 + 5.0 * 16.0 + 5.0 * 256.0 + 5.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 1.5) // 1
    {
        fDigitBinary = 2.0 + 2.0 * 16.0 + 2.0 * 256.0 + 2.0 * 4096.0 + 2.0 * 65536.0;
    }
    else if(fDigit < 2.5) // 2
    {
        fDigitBinary = 7.0 + 1.0 * 16.0 + 7.0 * 256.0 + 4.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 3.5) // 3
    {
        fDigitBinary = 7.0 + 4.0 * 16.0 + 7.0 * 256.0 + 4.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 4.5) // 4
    {
        fDigitBinary = 4.0 + 7.0 * 16.0 + 5.0 * 256.0 + 1.0 * 4096.0 + 1.0 * 65536.0;
    }
    else if(fDigit < 5.5) // 5
    {
        fDigitBinary = 7.0 + 4.0 * 16.0 + 7.0 * 256.0 + 1.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 6.5) // 6
    {
        fDigitBinary = 7.0 + 5.0 * 16.0 + 7.0 * 256.0 + 1.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 7.5) // 7
    {
        fDigitBinary = 4.0 + 4.0 * 16.0 + 4.0 * 256.0 + 4.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 8.5) // 8
    {
        fDigitBinary = 7.0 + 5.0 * 16.0 + 7.0 * 256.0 + 5.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 9.5) // 9
    {
        fDigitBinary = 7.0 + 4.0 * 16.0 + 7.0 * 256.0 + 5.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 10.5) // '.'
    {
        fDigitBinary = 2.0 + 0.0 * 16.0 + 0.0 * 256.0 + 0.0 * 4096.0 + 0.0 * 65536.0;
    }
    else if(fDigit < 11.5) // '-'
    {
        fDigitBinary = 0.0 + 0.0 * 16.0 + 7.0 * 256.0 + 0.0 * 4096.0 + 0.0 * 65536.0;
    }
    
    vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
    float fIndex = vPixel.x + (vPixel.y * 4.0);
    
    return mod(floor(fDigitBinary / pow(2.0, fIndex)), 2.0);
}

vec4 fire(vec2 p)
{
    p.x *= 1.0/E/GR;
    p.y *= PI/GR;
    float tempX = (p.y+.5)*cos(p.x*4.0*PI+time)*2.0;
    float tempY = (p.y+.5)*sin(p.x*4.0*PI+time)*2.0;

    p.x = tempX;
    p.y = tempY;

    p.x += .5*snoise(vec2(time*.6+256.0, p.y));
    p.y += .5*snoise(vec2(time*.6+500.0, p.x));    

    float x_max = 0.56999993;
    float y_max = 0.74999976;

    float R = x_max;
    float r = .1;

    float x = snoise(vec2(time*.6+256.0, p.y))*.25+.875;
    float y = snoise(vec2(time*.6+256.0, p.x))*.25-.625;

    vec4 c = vec4(x, y, 0.0, 0.0);

    vec2 Z = p*vec2(.85,1.0);
    int iterations_temp;
    const float max_iterations =6.0;
    float depth_trap = 4500.0;
    for(int iterations=0; iterations < int(max_iterations); iterations++) 
    {
        Z = c.xy + cmul(Z.xy, vec2(tanh(Z.x), tanh(Z.y)));

        if(dot(Z,Z)>depth_trap) {
            break;
        }
        iterations_temp = iterations;
    }

    float NIC = (Z.x * Z.x) + (Z.y * Z.y);
    NIC = float(iterations_temp)/max_iterations-log(sqrt(NIC))/float(iterations_temp);
    float red = clamp(sin(NIC)+.25, 0.0, 1.0);//red*3.0/4.0);
    float green = clamp(sin(NIC)*sin(NIC), 0.0, red*3.0/5.0);

    /*
int temp = int(p.x*64.0);
for(int i = 0; i < 64 i++)
if(i == temp)
green = Frequency[int(i)];
*/    

    //if(red -green > 0.79) return texture(Frequency, vec2(p.x, p.y)).rgba;
    return vec4(red, green , 0.0, 0.0);

    /*
//3-phase flux of 3 different coloring patterns
return vec4(red, green, blue, 0.0) * clamp(sin(time*5.0+0.0), 0.0, 1.0)
+ vec4(green, red, green, 0.0) * clamp(sin(time*5.0+4.0*PI/3.0), 0.0, 1.0)
+ vec4(green, green, red, 0.0) * clamp(sin(time*5.0+2.0*PI/3.0), 0.0, 1.0);
*/
}

vec3 scienceordie(vec2 uv)
{
    
    float scale = E/GR;
    uv = uv*scale-scale/2.0;
    //uv = rotatePoint(vec3(uv, 0.0), vec3(0.0, 0.0, 1.0), sin(time*PI)).xy;
    //uv += cos(vec2(time*PI, time*GR*PI))/GR/PI;
    uv.y -= .1/GR;
    float depth = demon(uv).r;
    float angle =  depth*PI+time;
    
    //uv.xy += depth*vec2(cos(angle), sin(angle))/MATRIX_W;
    
    vec2 fract_matrix = fract(uv*vec2(MATRIX_W,MATRIX_H));
    vec2 floor_matrix = floor(uv*vec2(MATRIX_W,MATRIX_H));
    float number = (mod(time*sin(floor_matrix.x+floor_matrix.y*MATRIX_W), 10.0));
    float digit = SampleDigit(number, GR*fract_matrix);
    
    
    vec3 body = smoothstep(0.0, 1.0/GR, smoothstep(0.0, 1.0/GR*E/PI, sqrt(clamp(1.0-length(uv*vec2(1.0, 1.0/GR)*GR), 0.0, 1.0)))*demon(uv*1.125));
    
    vec3 science = vec3(0.0, digit, 0.0)*(1.0-body)+body;
    float or = zero(-uv.x);
    
    vec4 die = clamp(fire(uv), 0.0, 1.0);
    
    vec3 scene = science*or+(1.0-body)*(1.0-or)*die.rgb;;//+(1.0-or)*body*flux(time+body.r*PI*2.0);
    return scene;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    glFragColor.rgb = scienceordie(uv);
    glFragColor.a = 1.0;
}

