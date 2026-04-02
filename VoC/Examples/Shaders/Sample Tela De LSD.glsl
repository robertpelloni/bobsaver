#version 420

// original https://www.shadertoy.com/view/wtBXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415
#define SIN(t) (.5*sin(t)+.5)
#define COS(t) (.5*cos(t)+.5)
#define ss(a,b,c) smoothstep(a,b,c)

float spiral(vec2 puv, int iter, float thick)
{
    float sp = length( puv.x - puv.y);
    float movableRef = puv.y;
    
    
    // after 2.*pi
    for(int i = 0; i < iter; i++)
    {
        movableRef = movableRef + 2.*PI;
        sp = min(sp, length(puv.x - movableRef ));    
    }
    
    // before 0
    sp = min(sp, length(puv.x - puv.y + 2.*PI ));  
    
    return ss(thick, 0., sp);
}

vec3 spiralRGB(vec2 puv, float thick, float offset)
{
    int iter = 15;
    vec2 scale = vec2(30.,1.);
    vec2 offs = vec2(offset,0.);
    
    puv *= scale;
    
    float r = spiral(puv, iter, thick);
    puv = puv + offs;
    float g = spiral(puv, iter, thick);
    puv = puv + offs;    
    float b = spiral(puv, iter, thick);
    
    return vec3(r,g,b);
}

float radials(vec2 puv, float segments, float intensity,
              float width, float power)
{
    // last value in interval
    float end = 2.*PI/segments;
    // angle mod
    float puvM = mod(puv.y, end);
    //normalize
    puvM /= end;
    // inverse
    float puvMInv = 1.-puvM; 
    puvM =       pow(puvM, power);
    puvMInv = pow(puvMInv, power);
    float res =  intensity*ss(1. - width/2., 1., puvM);
    res = (res + intensity*ss(1. - width/2., 1.,puvMInv));
    return res;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    vec2 muv = mouse*resolution.xy.xy/resolution.y;

    if(true)
    {
        vec2 save = uv;
        float grid = 7.;
        uv.x += (.0851*length(save))*sin(uv.y*grid + time);
        uv.y += (.0851*length(save))*sin(uv.x*grid + time);
    }
    
    vec2 puv = vec2(length(uv), atan(uv.y, uv.x));
    
    puv.x += radials(puv, 15., 0.1 + .02*sin(puv.y*(12.) + time),
                     .9, .4);
    
    // Rotation
    puv.y += mod(time, 2.*PI) - PI;
    
    vec3 col = spiralRGB(puv,
                         4.5 - .9*COS(1.5*time),
                         .2 + SIN(time*2.) + 0.5*SIN(puv.y));

    // DEBUG Radials
    //col = vec3(radials(puv, 10., 0.1, .9, .6));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
