#version 420

// original https://www.shadertoy.com/view/4tsBDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rand(float p)
{
    float x = fract(sin(p * 31.16544)*213.351654);
    float y = fract(sin(p * 37.16584)*23.351654);
    return vec2(x,y)-0.5;
}

float circle(vec2 uv,float Size)
{
    return clamp(  Size - length(uv)*31.,0.,1.);    
}

vec2 Turbulance(vec2 p,float freq,float amp,float iteration)
{    
    for(float i = 0.;i< iteration;i++)
    {
        p.x += sin(p.y * freq) * amp;
        p.y += sin(p.x * freq) * amp;
        freq *= 2.;
        amp *= 0.5;
    }
    return p;
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    float disto = 1.125;
    
    //uv = mix(Turbulance(uv,13.,.05,8.),uv,sin(time)*0.5+0.5);
    
    vec4 colo = vec4(0.);
    float pDuration = 1.;
    float Speed = 0.5;
    float RandomSpeed = 1.;
    float pStartSize = 1.4;    
    float pEndSize = 8.0;
    
    
    for(float i = 0.;i < 100.;i++)
    {
        float particleRId = fract((sin(32.32165465*31.06549874*i*i)*0.5+0.5) *321.654);
        
        float pRatio = i / 100.;
        float Life = mod(time+particleRId,pDuration);
        
        vec2 startPos = vec2(0.,0.)*0.5;
        vec2 r = normalize(rand(particleRId)) * 1.4f;
        
        
        //r = Turbulance(r,sin(time),.1,1.);
        
        vec2 MoveUp = vec2(sin(time),cos(time)) * 1.5*Life*Speed*0.;
        
        vec2 ParticlePos = (uv-startPos) + r*RandomSpeed*Life - MoveUp;
        
        
        float pSize = mix(pStartSize,pEndSize,Life) ;
        float particle = circle(ParticlePos, pSize);
        
        colo += particle * vec4(hsv2rgb(vec3(Life*0.2+time*.5,1.,1.)),1.) * (1. - Life)*1.1;
    }
    
    glFragColor = colo;
}
