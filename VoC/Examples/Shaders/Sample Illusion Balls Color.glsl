#version 420

// original https://www.shadertoy.com/view/tlj3Dy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Most of the code is actually from Seb D. ( doc cosinus )

const vec3 AmbientColor = vec3(1,1,1);
const float AmbientIntensity = 0.6;
const vec3 DiffuseColor = vec3(.6,.4,.2);
const float DiffuseIntensity = 1.4;
const vec3 LightDirection = vec3(-0.35, 0.35, 1);
const int StripCount = 120;

void ball(vec2 uv, vec2 center, float radius, inout vec3 color, int band, float s, bool useBand)
{
    if (useBand && s>=float(band) && s< float(band+1))
        return;
    vec2 delta = (uv-center)/radius;
    float sqDistance = dot(delta, delta);
    if (sqDistance>1.)
        return;
    color = (
        AmbientIntensity * AmbientColor +
        DiffuseIntensity * dot(vec3(delta.x, delta.y, 1.0-sqrt(sqDistance)), normalize(LightDirection)) * DiffuseColor
    );    
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5) /resolution.yy;

    vec3 col = vec3(0);
    
    
    float timeCursor = mod(time, 5.0)/ 5.0;
    if ( timeCursor > .5 )
        timeCursor = 1.0 - 2.0 * (timeCursor - .5);
    else
        timeCursor = 2.0 * timeCursor;
    
    timeCursor = 2.0 * timeCursor - 1.0;
        
    
    float s = mod((uv.y+1.)*float(StripCount),3.);
    bool useBand =  timeCursor < uv.x;
    //if (true) // funny variation
    if ( useBand )
    {
        if (s<1.)
        {
            col = vec3(1.,.4,.4);
        }
        else if (s<2.)
        {
            col = vec3(.4,1,.4);
        }
        else
        {
            col = vec3(.4,.4,1);
        }
    }
    
    //col = mix ( col, vec3(.5,.5,.5), timeCursor);
    
    ball(uv, vec2(0,0.1),0.15, col,0,s, useBand);
    ball(uv, vec2(-0.7,-0.3),0.15, col,1,s, useBand);
    ball(uv, vec2(-0.5,0.3),0.15, col,1,s, useBand);
    ball(uv, vec2(0.35,-0.2),0.15, col,1,s, useBand);
    ball(uv, vec2(0.65,0.15),0.15, col,2,s, useBand);
    ball(uv, vec2(-0.25,-0.2),0.15, col,2,s, useBand);  
    
    glFragColor = vec4(col,1.0);
}
