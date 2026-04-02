#version 420

// original https://www.shadertoy.com/view/MtdXzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 pos, float radius)
{
    return clamp(((1.0-abs(length(pos)-radius))-0.99)*100.0, 0.0, 1.0);
    
}

float line( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = -p - a;
    vec2 ba = -b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    float d = length( pa - ba*h );
    
    return clamp(((1.0 - d)-0.99)*25.0, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv *= 2.;
    uv.x *= resolution.x / resolution.y;
    
    
    float c = circle(uv,1.);
    float Tau = 6.2831853071;
    float unit = Tau / time;
    float r = 0.;
    float g = 0.;
    float b = 0.;
    float t =999.+ time *0.5;
    vec3 col = vec3(0.);
    for(int i = 0;i < 256;i++)
    {
        float Fi = float(i)*1.;
        
        float v1 = Tau ;
        float v2= (t *11.11 );
        float OffLight = .025;
        
        float p = mod( Fi ,v1) * (t+140.) *0.012;
        float p2 =mod( Fi ,v2) * (t+140.) *0.012;
        
        float FiStart = float(p);
        float FiNext = float(p2);
        
        
        vec2 start = vec2(sin( FiStart ),cos(FiStart));
        vec2 end = vec2(sin( FiNext ),cos(FiNext  ));
        
        r += line(uv,start ,end) ;    
        
        p = mod( Fi ,v1 ) * (t+140.+ OffLight) *0.012;
        p2 =mod( Fi ,v2 ) * (t+140.+ OffLight) *0.012;
        
        FiStart = float(p);
        FiNext = float(p2);
        
        
        start = vec2(sin( FiStart ),cos(FiStart));
        end = vec2(sin( FiNext ),cos(FiNext  ));
        
        g += line(uv,start ,end) ;    
        
        
        p = mod( Fi ,v1  ) * (t+140.+ OffLight+ OffLight) *0.012;
        p2 =mod( Fi ,v2 ) * (t+140.+ OffLight+ OffLight) *0.012;
        
        FiStart = float(p);
        FiNext = float(p2);
        
        
        start = vec2(sin( FiStart ),cos(FiStart));
        end = vec2(sin( FiNext ),cos(FiNext  ));
        
        b += line(uv,start ,end) ;   
        
    }
    
    

    glFragColor = vec4(r,g,b, 1.0);
}
