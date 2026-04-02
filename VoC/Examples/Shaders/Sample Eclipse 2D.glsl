#version 420

// original https://www.shadertoy.com/view/wl2SWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DAY_COLOR vec3(0.2, 0.3, 0.5)
#define NIGHT_COLOR vec3(0.1,0.1,0.1)
#define SUN_COLOR vec3(1.2, 1.1, 0.9)
#define MOON_COLOR vec3(0.0, 0.0, 0.0)

#define SUN_RADIUS 0.1
#define MOON_RADIUS 0.099

vec3 skyColor(float distMoonSun)
{
    return mix(NIGHT_COLOR, DAY_COLOR, smoothstep(0.0, 1.0, distMoonSun / 0.22));
}

float rand(float seed)
{
    float val = 0.0;
    
    for (int i = 0; i < 5; i++)
    {
        val += 0.240 * float(i) * sin(seed * 0.68171 * float(i));
    }
    return val;
}

vec3 baseColor(float distMoonSun, float distFromSun, float distFromMoon)
{
    vec3 col = vec3(0);
    if (distFromMoon < MOON_RADIUS)
    {
        col = MOON_COLOR;
    }
    else if (distFromSun < SUN_RADIUS)
    {
        col = SUN_COLOR;
    }
    else
    {
        col = skyColor(distMoonSun);;
        
        vec2 star = gl_FragCoord.xy;
        if (rand(star.y * star.x) >= 2.12 && rand(star.y + star.x) >= 0.8)
        {
            vec3 starCol = mix(vec3(2.0,2.0,2.0), DAY_COLOR, smoothstep(0.0,1.0, distMoonSun / 0.14));
            col = max(col, starCol);
        }
    }
    return col;
}

vec3 rayColor(vec2 vecMoonSun, vec2 vecFromSun, float distMoonSun, float distFromSun)
{
    vec3 skyCol = skyColor(distMoonSun);
    
    vec2 unit = vecFromSun / distFromSun; // unit vec
    vec2 norm = vec2(-unit.y, unit.x);
    
    vec3 col = vec3(0);
    // ray traverses moon
    if ((abs(dot(norm, vecMoonSun)) < MOON_RADIUS && dot(vecFromSun, vecMoonSun) > 0.0) || distMoonSun < MOON_RADIUS)
    {
        float proj = dot(unit, vecMoonSun);
        float delta = sqrt(MOON_RADIUS * MOON_RADIUS - distMoonSun * distMoonSun + proj * proj);
        vec2 root = clamp(vec2(proj - delta, proj + delta), vec2(0.0), vec2(distFromSun));
        float radius = min(SUN_RADIUS, distFromSun);
        col = (clamp(root.x, 0.0, radius) + max(radius - root.y,0.0)) * SUN_COLOR +            
            ((distFromSun - clamp(root.y, radius, distFromSun)) + max(root.x - radius,0.0)) * skyCol +
            (root.y - root.x) * MOON_COLOR;
    }
    else
    {        
        col = max(distFromSun - SUN_RADIUS, 0.0) * skyCol + min(distFromSun, SUN_RADIUS) * SUN_COLOR;
    }
    col /= distFromSun;
    
    // apply attenuation based on squared distance
    col *= 1.0 / (40.0 * max(0.01, distFromSun * distFromSun));
    
    return col;
}

void main(void)
{
    // normalize and center fragment coordinates
    float aspect = resolution.x / resolution.y;
    
    vec2 sun = vec2(0.118);
    vec2 moon = sun - cos(time * 0.6) * vec2(0.11, 0.07);
    // mouse debug mode
    //moon = mouse*resolution.xy.xy / resolution.xy - 0.5;
    vec2 pos = gl_FragCoord.xy / resolution.xy - 0.5;
    
    sun.x *= aspect;
    moon.x *= aspect;
    pos.x *= aspect;    
    
    vec2 vecMoonSun = moon - sun;
    vec2 vecFromSun = pos - sun;
    vec2 vecFromMoon = pos - moon;
        
    float distMoonSun = length(vecMoonSun);
    float distFromSun = length(vecFromSun);
    float distFromMoon = length(vecFromMoon);
    
    vec3 rayCol = rayColor(vecMoonSun, vecFromSun, distMoonSun, distFromSun);
    vec3 baseCol = baseColor(distMoonSun, distFromSun, distFromMoon);
    
    glFragColor = vec4(baseCol + rayCol, 1.0);
}
