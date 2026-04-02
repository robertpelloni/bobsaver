#version 420

// original https://www.shadertoy.com/view/3sKGz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define TAU (2.0*PI)

vec2 ConvertToPolar(vec2 rectCoord)
{
    //vectors becomes: magnitude, angle
    return vec2(length(rectCoord), atan(rectCoord.y, rectCoord.x));
}

vec2 ConvertToRect(vec2 polarCoord)
{
    return vec2(polarCoord.x * cos(polarCoord.y), polarCoord.x * sin(polarCoord.y));
}

vec3 ColorTransition(vec3 colorA, vec3 colorB)
{
    float pct = abs(sin(time))/2.0;

    return vec3(mix (colorA, colorB, pct));
}

vec2 pMod2(inout vec2 p, vec2 size) 
{
    vec2 c = floor((p + size * 0.5) / size);
    p = mod(p + size * 0.5, size) - size * 0.5;
    return c;
}

float DistanceCircle(float radius, vec2 origin)
{
    return length(origin) - radius;
}

float DistanceRoundedBox(float radius, vec2 origin)
{
    /*the more pow increment the less rounded the box is*/
    origin = origin * origin;
    origin = origin * origin;
    float d8 = dot(origin, origin);
    return pow(d8, 1.0 / 8.0) - radius;
}

float DistanceBox(vec2 size, vec2 origin)
{
    origin = abs(origin);
    float dx = 2.0*origin.x - size.x;
    float dy = 2.0*origin.y - size.y;
    return max(dx, dy);
}

float DrawMotionOne(vec2 position)
{
    position = abs(position);
    vec2 p_position = ConvertToPolar(position);
    p_position.y += position.x * sin(time);//rotation
    p_position.x *= 1.0 + position.y;//mod radius
    position = ConvertToRect(p_position);
    float distanceThree = DistanceBox(vec2(0.5, 0.5), position + vec2(0.0));
    return distanceThree;
}

float DrawCaleidoscopeSimple(vec2 position, float times)
{
    vec2 p_pos = ConvertToPolar(position);
    p_pos.y = mod(p_pos.y, TAU / times);
    p_pos.y += time;
    position = ConvertToRect(p_pos);
    pMod2(position, vec2(0.5));
    float d1 = DistanceCircle(0.2, position);
    float d2 = DistanceBox(vec2(0.2), position - vec2(0.1));
    return min(d1, d2);
}

float DrawCaleidoscopeEffect(vec2 position, float times, vec2 size)
{
    vec2 p_pos = ConvertToPolar(position);
    float beta = TAU / times;
    float np = p_pos.y / beta;
    p_pos.y = mod(p_pos.y, beta);
    float m2 = mod(np, 2.0);
    if (m2 > 1.0)
    {
        p_pos.y = beta - p_pos.y;
    }
    p_pos.y += time;
    position = ConvertToRect(p_pos);

    //make repeating patron
    pMod2(position, size);

    float d1 = DistanceCircle(0.1, position);
    float d2 = DistanceBox(vec2(0.1), position - vec2(0.1));
    return min(d1, d2);
}
//post processing methods
void Rotation(inout vec2 position, float angle)
{
    position = vec2(position.x * cos(angle) + position.y * sin(angle), 
        -position.x * sin(angle) + position.y * cos(angle));
}

vec3 ChangeSaturation(vec3 color, vec2 position)
{
    Rotation(position, time);
    color = clamp(color, 0.0, 1.0);
    return pow(color, vec3(length(position)));//more saturate at borders
    
    //return pow(color, vec3(1.0 /length(position)));//more saturate at center
    //saturate roullete
    //return pow(color, vec3(abs(position.x)/ length(position), abs(position.y)/ length(position),length(position)));
}

void main(void)
{   
    vec3 crimson =  vec3(0.7, 0.02, 0.23);
    vec3 elecgreen = vec3(0.04, 1.0, 0.16);
    vec3 outputColor = vec3(0.0);

    //setup scaling and origin pos
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(0.5);
    uv.x *= resolution.x / resolution.y;
    //uv.y *= resolution.x / resolution.y;
    

    
    vec2 offset = uv;
    Rotation(offset, time);

    float distance = DrawCaleidoscopeEffect(uv-offset, 25.0, vec2(0.5));
    float md = mod(distance, 0.1);
    float nd = abs(distance / 0.1) ;

    if (abs(distance) < 0.1)
    {
        outputColor = ColorTransition(crimson, elecgreen);
    }
    
    if (abs(md) < 0.01)
    {
        outputColor = (distance < 0.0) ? crimson / nd : elecgreen / nd;
    }
    
    //apply postProccessing before outputing 
    
    glFragColor = vec4(ChangeSaturation(outputColor, uv), 1.0);
}

