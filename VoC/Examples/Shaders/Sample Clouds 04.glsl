#version 420

// original https://www.shadertoy.com/view/lsB3Wm

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

///////////////////////
float hash( vec2 p )
{
    float h = dot(p,vec2(127.1,311.7));
    
    return -1.0 + 2.0*fract(sin(h)*43758.5453123);
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}
///////////////////////

const float space = 0.48;
const int krnl = 1;

vec4 getTexCoordValue (float x, float y, vec2 uv, float scale)
{

    vec2 p = vec2 (x, y);
    //vec2 p = gl_FragCoord.xy / iResolution.xy;

    //vec2 uv = p*vec2(iResolution.x/iResolution.y,1.0);
    
    float f = 0.0;

    {
        uv *= scale;
        mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
        f  = 0.5000*noise( uv ); uv = m*uv;
        f += 0.2500*noise( uv ); uv = m*uv;
        f += 0.1250*noise( uv ); uv = m*uv;
        f += 0.0625*noise( uv ); uv = m*uv;
    }

    f = 0.5 + 0.5*f;
    
    f *= smoothstep( 0.0, 0.005, abs(p.x-0.0) );    
    
    return vec4( f, f, f, 1.0 );    
}

float getVolume (float x, float y, float time)
{    
    vec2 uv = vec2(x, y) / resolution.xy;    
    float vol = 0.0;
    const int layers = 6;
    float totalColor = 1.0;
    
    for (int i = 0; i < layers; ++i)
    {
    
        if (mod(float(i), 2.0) == 0.0)
        {
            uv.x += time * (0.01 + float(i) * 0.001);            
        } else {
            uv.y -= time * (0.01 + float(i) * 0.001);        
        }
        
        
        vec4 col = getTexCoordValue(x, y, uv, float(i) * 3.0 + 2.0);
        
        float amount = totalColor * 0.5;
        totalColor = totalColor - (amount);
        totalColor = max (totalColor, 0.0);
        
        vol += (col.r + col.g + col.b) * 0.333 * amount;        
    }
    return vol;
    
}

float filter (float vol, float space)
{
    vol = clamp (vol - space, 0.0, 1.0);    
    vol = vol * (1.0 / (1.0 - space));    
    return vol;
}

void drawBG()
{
    float h = gl_FragCoord.y / resolution.y;
    h = 1.0 - h;
    h *= 0.6;
    glFragColor = vec4(h, h, h + 0.5, 0.0);
    glFragColor.b = min (1.0, glFragColor.b);
    
}

void main(void)
{
    
    float t = 60.0 + time * 1.445;
    float s = sin(time);
    float vol = 0.0;
    vol += getVolume (gl_FragCoord.x, gl_FragCoord.y, t);    
    
    vec2 lightPos = resolution.xy * 1.0;    
    vec2 diff = gl_FragCoord.xy - lightPos;    
    vec2 diffNorm = normalize(diff) * 2.5;
    
    const int steps = 8;
    float shade = 0.0;
    
    for (int i = 0; i < steps; ++i)
    {
        float ifl = float(i);
        
        vec2 pos = gl_FragCoord.xy;
        float sample = getVolume (pos.x + diffNorm.x * ifl, pos.y + diffNorm.y * ifl, t);        
        shade += sample / float(steps);        
    }
    
    drawBG();
    
    
    vol = filter(vol, space);
    vol = clamp(vol, 0.0, 1.0);
    shade = filter(shade, space * 1.2);
    shade = clamp(shade, 0.0, 1.0);
    
    
    glFragColor.r += vol;
    glFragColor.g += vol;
    glFragColor.b += vol;
    
    
    shade *= 1.5;
    shade = 1.0 - shade;
    
    glFragColor.r *= shade;
    glFragColor.g *= shade;
    glFragColor.b *= shade;
    
    
    //////////////////////////////
    

    
}
