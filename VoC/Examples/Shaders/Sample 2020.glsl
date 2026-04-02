#version 420

// original https://www.shadertoy.com/view/3l2Bzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// 2020 - 🤮 Revision; by Philippe Desgranges
// Email: Philippe.desgranges@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

// Note: This shader is a fairly standard 2D composition with two layers. The digits
// are produced with bespoke signed distance functions (the fact that 2020 has only two diferent
// digits made the process easier).
//

#define S(a,b,c) smoothstep(a,b,c)

// outputs a colored shape with a black border from distance field (RGBA premultiplied)
vec4 border(vec3 color, float dist)
{
    vec4 res;
    
    float aa = 30. / resolution.x;
    
    res.a = S(0.25 + aa, 0.25, dist); 
    res.rgb = color *  S(0.2, 0.2 - aa, dist); 
    
    return res;
}

// Blend a premultiplied rbga color onto rgb
vec3 premulBlend(vec4 src, vec3 dst)
{
    return dst * (1.0 - src.a) + src.rgb;
}

// Blend a premultiplied rbga color onto rgba (accurate alpha handling)
vec4 premulBlend(vec4 src, vec4 dst)
{
    vec4 res;
    res.rgb = dst.rgb * (1.0 - src.a) + src.rgb;
    res.a = 1.0 - (1.0 - src.a) * (1.0 - dst.a); 
    
    return res;
}

// Distance field to the digit 0
float zeroDst(vec2 uv)
{
    float dist;
    
    uv.y -= 0.5;
    
    if (uv.y > 0.0) // upper part
    {
        uv.y = pow(uv.y, 1.8);
        dist = length(uv);
    }
    else if (uv.y > -1.1) // middle part
    {
        dist = abs(uv.x);
    }
    else  // lower part
    {
        uv.y += 1.1;
        uv.y = pow(-uv.y, 1.8);
        dist = length(uv);
    }
    
    return (abs(dist - 0.725) - 0.275);
}

// a box distance function
float box(vec2 p, vec2 b )
{
    vec2 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);
}

// Distance field to the digit 2
float twoDst(vec2 uv)
{
    uv.y -= 0.5;
    
    float topBar = box((uv + vec2(0.725, 0.0)) * vec2(1.0, 1.4), vec2(0.275, 0.0));
    
    if (uv.y > 0.0) // Top 'curve'
    {
        uv.y = pow(uv.y, 1.8);
        float dist = length(uv);
        return max(-topBar, (abs(dist - 0.725) - 0.275));
    }
    else
    {
        float bottomBar = box((uv + vec2(0.0, 1.83)) * vec2(1.0, 1.4), vec2(0.95, 0.299));
        
        float two = min(topBar, bottomBar);
        
        if (uv.y > -1.8)
        {    
            float curve = (cos(uv.y * 2.0) - 1.0) * 0.7;
            float x = 0.0 + uv.x - curve;
            float mid = abs(uv.y + 0.4) * 0.7;
            float x2 = 0.0 + uv.x - curve - mid * mid * 0.15 + 0.01;
         
            two = min(two, max(-x + 0.45, x2 -1.0));
        }
        return two;
    }

}

// Coordinate transform from global uv space to charcter space with poition and rotation
vec2 letterUVs(vec2 uv, vec2 pos, float angle)
{
    float c = sin(angle);
    float s = cos(angle);
    float sc = 1.35;
    uv -= pos;
    return uv.x * vec2(s * sc, c) + uv.y * vec2(-c * sc, s);
}

// Borrowed from BigWIngs (random 1 -> 4)
vec4 N14(float t) {
    return fract(sin(t*vec4(123., 104., 145., 24.))*vec4(657., 345., 879., 154.));
}

// Compute a randomized Bokeh spot inside a grid cell
float embersSpot(vec2 uv, vec2 id, float decimation)
{
    float accum = 0.0;
    
    for (float x = -1.0; x <= 1.0; x += 1.0)
    {
        for (float y = -1.0; y <= 1.0; y += 1.0)
        {
            vec2 offset = vec2(x, y);
            vec2 cellId = id + offset;
            vec4 rnd = N14(mod(cellId.x, 300.0) * 25.3 + mod(cellId.y, 300.0) * 6.67);
    
            vec2 cellUV = uv - offset + rnd.yz * 1.0;

            float dst = length(cellUV);

            //float radSeed = sin(time * 0.02 + rnd.x * 40.0);
            //float rad =  (abs(radSeed) - decimation) / (1.0 - decimation);
            
              float rad = rnd.y * 0.5;

            float intensity = S(rad, rad - 0.8, dst);
            
            accum += intensity;
        }
    }
    
    return accum;
}

// Computes a random layer of embers spots
float emberLayer(vec2 uv, float decimation)
{
    vec2 id = floor(uv);
    vec2 cellUV = (uv - id) - vec2(0.5, 0.5) ;

    float intensity = embersSpot(cellUV, id, decimation);
    
    return intensity;
}

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)), 
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*43758.5453);
}

// https://www.iquilezles.org/www/articles/voronoise/voronoise.htm
float VoroNoise( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    float k = 1.0 + 63.0*pow(1.0-v,4.0);
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec3  o = hash3( p + g )*vec3(u,u,1.0);
        vec2  r = g - f + o.xy;
        float d = dot(r,r);
        float w = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
        va += w*o.z;
        wt += w;
    }

    return va/wt;
}

// Computes the fire background
vec3 fire(vec2 uv)
{
    uv.x += sin(uv.y * 0.3 + time * 0.5)  + sin(uv.y * 0.8 + time * 1.23) * 0.25 - uv.y * 0.5;
    
    //accumulates several layers of bokeh
    float fire = VoroNoise(uv * vec2(1.0, 0.3) - vec2(0.0, time), 0.0, 1.0) * 0.8;// * 0.2;
    fire += VoroNoise(uv  * vec2(2.3, 1.68) - vec2(0.0, time * 3.0), 0.0, 1.0) * 0.5;
    fire += VoroNoise(uv * vec2(4.3, 3.3) - vec2(0.0, time * 6.0), 0.0, 1.0) * 0.1;
 
    
    fire -= emberLayer(uv * vec2(1.0, 0.7) * 1.6 - vec2(0.0, time) , 1.0) * 0.5;
    fire -= emberLayer(uv * vec2(1.0, 0.7) * 3.3 - vec2(0.0, time) , 1.0) * 0.25;
    
    //return vec3(fire);
    
    vec3 col = mix(vec3(2.0, 0.90, 0.55),  vec3(0.1, 0.0, 0.0), min(1.0, uv.y * 0.3 + fire));
    
    
    return col;
}

float shadowsIntensity = 0.74;
float shadowRadius = 1.1;

vec3 reflection(vec3 normal, vec2 uv)
{
    uv.x = -uv.x;
    uv += normal.xz * 3.0;
    return fire(uv);
}

float flatPart = -0.06;
float bevel = 0.065;

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( a, b, h ) + k*h*(1.0-h);
}

// Character two with outline and shadow (premultiplied RGBA)
vec4 twoCol(vec2 uvIn, vec3 col, vec2 pos, float angle)
{
    vec2 uv = letterUVs(uvIn, pos, angle);
    
    float dst = twoDst(uv);
    float dstR = smax(flatPart, twoDst(letterUVs(uvIn + vec2(0.05, 0.0), pos, angle)), bevel);
    float dstU =  smax(flatPart, twoDst(letterUVs(uvIn + vec2(0.0, 0.05), pos, angle)), bevel);
    
    float clampedDst = smax(flatPart, dst, bevel);
    vec3 n = normalize(vec3(dstR - clampedDst, 0.01, dstU - clampedDst));
    
    //col = n * 0.5 + vec3(0.5); 
    col *= 0.4;
    
    col += reflection(n, uvIn) * 0.8;
    
    vec4 res = border(col, dst);
    
   
    
    uv.y += 0.14;
    res.a = min(res.a +  S(shadowRadius, -1.0, twoDst(uv)) * shadowsIntensity, 1.0);
    
    return res;
}

// Character zero with outline and shadow (premultiplied RGBA)
vec4 zeroCol(vec2 uvIn, vec3 col, vec2 pos, float angle)
{
    //uv = letterUVs(uv, pos, angle);
    
    
    vec2 uv = letterUVs(uvIn, pos, angle);
    
    float dst = zeroDst(uv);
    float dstR = smax(flatPart, zeroDst(letterUVs(uvIn + vec2(0.05, 0.0), pos, angle)), bevel);
    float dstU =  smax(flatPart, zeroDst(letterUVs(uvIn + vec2(0.0, 0.05), pos, angle)), bevel);
    
    float clampedDst = smax(flatPart, dst, 0.01);
    vec3 n = normalize(vec3(dstR - clampedDst, bevel, dstU - clampedDst));
    
   
        //col = n * 0.5 + vec3(0.5); 
    col *= 0.4;
    
    if (dst < 0.21)
    {   
        col += reflection(n, uvIn) * 0.8;
    }
    
    vec4 res = border(col, zeroDst(uv));
    
    
    uv.y += 0.14;
    res.a = min(res.a +  S(shadowRadius, -1.0, zeroDst(uv)) * shadowsIntensity, 1.0);
    
    return res;
}

vec3 red = vec3(0.9, 0.01, 0.16);
vec3 yellow = vec3(0.96, 0.70, 0.19); // 248, 181, 51
vec3 green = vec3(0.00, 0.63, 0.34);  //1, 162, 88
vec3 blue = vec3(0.01, 0.57, 0.76);   //5, 142, 197

// 2020 with colors and shadows (premultiplied rgba)
vec4 yearCol(vec2 uv)
{
    float angle = sin(time) * 0.3;
    
    vec4 date = twoCol(uv, green, vec2(-2.5, 0.0), angle);
    date = premulBlend(zeroCol(uv, green, vec2(-0.8, 0.0), angle), date);
    date = premulBlend(twoCol(uv, green, vec2(0.8, 0.0), angle), date);
    date = premulBlend(zeroCol(uv, green, vec2(2.5, 0.0), angle), date);
    
    return  date;
}

float corona(vec2 uv, float blur)
{
      
    float angle = atan(-uv.x, -uv.y) / 6.2831 + 0.5;
    
    float copies = 9.0;
    //float step = (1.0 / copies);
    float quarter = floor(angle * copies + 0.5);
    
    float rot = -quarter * 6.2831 / copies;
    
    float s = sin(rot);
    float c = cos(rot);
    
    uv *= mat2(c, s, -s, c);
    
    float dst = length(uv) - 0.4;
    
    
    float dst2 = length((uv - vec2(0.0, 0.63)) * vec2(1.0, 1.2)) - 0.13;
    
    if (uv.y < 0.63)
    {
        dst = min(dst, abs(uv.x) - 0.06);// + 0.1, 0.1);
    }
    
    dst = smin(dst, dst2, 0.1);
    
    return S(-0.01 - blur, 0.01 + blur , dst);
}

// Compute a randomized Bokeh spot inside a grid cell
float coronaSpot(vec2 uv, vec2 id)
{
    float accum = 1.0;
    
    for (float x = -1.0; x <= 1.0; x += 1.0)
    {
        for (float y = -1.0; y <= 1.0; y += 1.0)
        {
            vec2 offset = vec2(x, y);
            vec2 cellId = id + offset;
            vec4 rnd = N14(mod(cellId.x, 300.0) * 25.3 + mod(cellId.y, 300.0) * 6.67);
    
            float t = time;
            
            vec2 cellUV = uv - offset + rnd.yz * 1.0 + vec2(sin(t * (rnd.x + 0.3)), cos(t * (rnd.z + 0.2))) * 0.2;

            
            float rot = rnd.y * rnd.x * 456.0 + time * (0.3 * (rnd.y - 0.5)) ;
            float c = cos(rot);
            float s = sin(rot);
            cellUV *= mat2(c,s,-s,c);

            float dst = rnd.y;
            
            float intensity = corona(cellUV * (1.5 + dst), dst * 0.2);
            
            accum *= mix(intensity, 1.0, dst);
        }
    }
    
    return accum;
}

// Computes a random layer of embers spots
float coronaLayer(vec2 uv)
{
    vec2 id = floor(uv);
    vec2 cellUV = (uv - id) - vec2(0.5, 0.5) ;

    return coronaSpot(cellUV, id);
}

// Final composition
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv *= 3.0;
    
    vec4 dateCol =  yearCol(uv); // 2020
    
    vec3 bg = fire(uv);
    
    
    float corona = coronaLayer(uv * 1.1);
    
    
    bg.rgb += mix(0.0,  corona, S(-2.0, 7.0, uv.y)) * 0.8;
 
    
    //add a bit of light
    dateCol.rgb -= uv.y * 0.15 * dateCol.a;
    bg.rgb -= uv.y * 0.03;
    
    // blend 2020 and BG
    vec3 col = premulBlend(dateCol, bg);
    
    // Gamma correction to make the image warmer
    float gamma = 0.8;
    col.rgb = pow(col.rgb, vec3(gamma));
    
    glFragColor = vec4(col,1.0);
}
