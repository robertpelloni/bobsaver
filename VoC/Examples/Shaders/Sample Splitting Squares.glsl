#version 420

// original https://www.shadertoy.com/view/ftsBDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float animatedSquare(vec2 uv, float time, float type)
{
    vec2 anim_uv = uv - 0.25;
    if (step(type, 0.5) == 0.0)
    {
        anim_uv -= vec2(0.25 * clamp(time*2.6-0.3, 0.0, 1.0),
                        0.25 * clamp(time*2.6-1.3, 0.0, 1.0));
    } else {
        anim_uv -= vec2(0.25 * clamp(time*2.6-1.3, 0.0, 1.0),
                        0.25 * clamp(time*2.6-0.3, 0.0, 1.0));
    }
    anim_uv = abs(anim_uv);
    
    float smoothness = fwidth(uv.x);
    
    return smoothstep(0.25+smoothness, 0.25, anim_uv.x) * 
            smoothstep(0.25+smoothness, 0.25, anim_uv.y);
    //return step(uv.x, -0.5)*step(uv.y, -0.5);
}

float cellrandom(vec2 xy)
{
    return fract(sin(dot(xy, vec2(12.9898,78.233))) * 43758.5453);
}

float get_rnd(float index, vec2 uv)
{
    vec2 new_uvs = uv*index;
    new_uvs -= fract(new_uvs);
    return cellrandom(new_uvs);
}

float get_type(float index, vec2 uv)
{
    vec2 new_uvs = uv*index;
    new_uvs -= fract(new_uvs);
    //return new_uvs.x;
    return step(abs(new_uvs.x - new_uvs.y), 0.5);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x -= 0.5;
    uv.x *= resolution.x / resolution.y;
    uv.x -= 0.5;
    
    float loopTime = time+0.00001;
    loopTime = mod(loopTime+5.0, 10.0);
    loopTime = abs(loopTime-5.0);
    loopTime -= 1.0;
    float fTime = ceil(loopTime);
    fTime = pow(2.,fTime);
    
    
    float rnd_1 = get_rnd(2., uv);
    float rnd_2 = get_rnd(4., uv);
    float rnd_3 = get_rnd(8., uv);
    float rnd_4 = get_rnd(16., uv);
    float rnd_5 = get_rnd(32., uv);
    
    vec2 uv_1 = vec2(fract(uv.x*fTime),
                fract(uv.y*fTime));
    uv = abs(uv_1*2.0-1.0);
    
    float animTime = mod(loopTime, 1.0);
    
    float square = animatedSquare(uv, animTime, get_type(2., uv_1));
    
    //glFragColor = vec4(vec3(rnd_1), 1.0);
    glFragColor = 1.0*vec4(vec3(square), 1.0);
    //glFragColor += vec4(uv, 0.0, 0.0);
    //glFragColor += 0.2*vec4(get_type(2., uv_1));
}
