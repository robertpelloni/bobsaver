#version 420

// original https://www.shadertoy.com/view/tdKGzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795

float torusDist(vec3 p, float r1, float r2)
{
    float d = sqrt(pow(p.z, 2.0) + pow(length(p.xy) - r1, 2.0));
    if(r2 <= d)
        return d - r2;
    else
        return r2 - d;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 getColor(vec3 p, float r1, float time, vec3 cp)
{
    vec4 col = vec4(0, 0, 0, 0.25);//black
    
    float t = atan(p.y, p.x) / (2.0*PI) + 0.5;

    float rings = 10.;

    t = rings*r1*t;

    float colorNum = 2.0;
    float colorChange = 0.025;//0 - 1

    if(0.9 < fract(t + time))
    {
        col.rgb = hsv2rgb(vec3((t + (1. + colorChange)*time)/colorNum, 1.0, 1.0));
        col.rgb *= 50. / pow(distance(p, cp), 2.);
        
        col.a = 1.0;//opaque
    }
    
    return col;
}

void main(void)
{
    float time = 4.*time;
    
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.0) / resolution.y;
    
    vec2 um = (mouse*resolution.xy.xy - resolution.xy/2.0) / resolution.y;
    um = 1.5*um.yx;
    float umLength = 0.3*length(um);
    um = normalize(um);
    
    
    float r1 = 1.0 / umLength;
    float r2 = 0.75;//0.55 + 0.5*sin(time/5.0);
    
    float torusCameraDist = 0.5*r2;
    
    vec3 cp = vec3(-r1, 0, 0);
    vec3 i = vec3(um.y, 0, -um.x);
    vec3 j = vec3(um.x, 0, um.y);
    vec3 k = -vec3(0, 1, 0);
    
    //vec3 cp = vec3(r1, 0, 3);
    //vec3 i = vec3(0, 1, 0);
    //vec3 j = normalize(vec3(-3, 0, 3));
    //vec3 k = normalize(vec3(-3, 0, -3));
    
    
    float zoom = 0.007;
    
    
    uv *= 0.01;
    vec3 ld = normalize(uv.x * i + uv.y * j + zoom * k);
    
    vec4 col = vec4(0);
    bool searchAgain = true;
    
    vec3 smp = cp;
    
    while(searchAgain)
    {
        searchAgain = false;
        
        vec3 p = smp;
        
        for(int i = 0; i < 200; i++)
        {
            float d = torusDist(p, r1, r2);
            p += d * ld;
            
            if(d < 0.01)
            {
                vec4 nc = getColor(p, r1, time, cp);
                col.rgb = mix(nc.rgb, col.rgb, col.a);
                col.a = 1. - (1. - col.a)*(1. - nc.a);
                
                smp = p + 0.01 * ld;
                
                searchAgain = true;
                
                break;
            }
        }
    }
    
    // Output to screen
    glFragColor = vec4(col.a * col.rgb, 1.0);
}
