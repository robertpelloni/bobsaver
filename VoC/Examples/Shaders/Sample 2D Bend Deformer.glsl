#version 420

// original https://www.shadertoy.com/view/WtSfW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec3 GetCheckboard(vec2 p)
{
    vec3 PALETTE[5];
    PALETTE[0] = vec3( 38, 70, 83)/255.0;
    PALETTE[1] = vec3( 42,157,143)/255.0;
    PALETTE[2] = vec3(233,196,105)/255.0;
    PALETTE[3] = vec3(244,162, 97)/255.0;
    PALETTE[4] = vec3(231,111, 81)/255.0;
    
    float offsetX = p.x < 0.0 ? 1.0 : 0.0;
    float offsetY = p.y < 0.0 ? 1.0 : 0.0;
    
    float ttt = (sin(time * 0.5) + 1.0) * 0.5;
    float sss = mix(20.0, 50.0, ttt);
    float checkBoardX = abs(round(abs(p.x) * sss) + offsetX);
    float checkBoardY = abs(ceil(abs(p.y) * sss) + offsetY + checkBoardX);
    int c1 = int(mod(checkBoardX + checkBoardY, 5.0));
    
    return
        c1==0 ? PALETTE[0]:
        c1==1 ? PALETTE[1]:
        c1==2 ? PALETTE[2]:
        c1==3 ? PALETTE[3]:
                PALETTE[4];
}

float GetArcLength(vec2 circleCenter, vec2 p)
{
    vec2  dir = p - circleCenter;
    float radius = length(dir);
    float d = dot(normalize(dir), vec2(0, 1));

    d = clamp(d, -0.9999999, 0.9999999);
    return acos(d) * radius;
}

vec2 MapArcOnCircle(vec2 circleCenter, float radius, float arc)
{
    float halfCirconference = PI * radius;
    float v = arc / halfCirconference;
    float a = v * PI;
    vec2  dir = vec2(sin(a), cos(a));
    return circleCenter + dir * radius;
}

vec2 UnbendPoint(vec2 p, vec2 bendCircleCenter, float bendCircleRadius, float t, float ox)
{
    float derrivedRadius = distance(p, bendCircleCenter);
    float d = derrivedRadius - bendCircleRadius;
    float s  = GetArcLength(bendCircleCenter, p);
    float safety = clamp((t - 0.01) / 0.01, 0.0, 1.0);
    s = mix(abs(p.x - ox), s, safety);

    float bendCircleRadiusT0 = 1.0 / PI + d;
    float bendCircleHalfCirconference = PI * bendCircleRadiusT0;
    float dynamicArcLength = mix(1.0, bendCircleHalfCirconference, t);

    vec2  mp = MapArcOnCircle(bendCircleCenter, derrivedRadius, dynamicArcLength);
    float sp = GetArcLength(bendCircleCenter, mp);
    return vec2(s / sp, d);
}

void main(void)
{
    vec2  uv    = gl_FragCoord.xy/resolution.xy;
    vec2  mouse = (mouse*resolution.xy.xy/resolution.xy);
    float vignette = clamp((length(uv - 0.5) - 0.35) * 1.5, 0.0, 1.0);
    float screenRatio = resolution.y/resolution.x;
    uv.y    *= screenRatio;
    mouse.y *= screenRatio;

    vec2  m = (mouse - 0.5) * 2.0 * vec2(1,1);
    vec2  p = (uv    - 0.5) * 2.0 * vec2(1,1);
    float bendAmount = (sin(time) + 1.0) * 0.5;

    //if(mouse*resolution.xy.z == 0.0) m = vec2(0,-0.48);

    float bendCircleRadius = 1.0 / max(0.01, (PI * bendAmount));
    vec2  bendCircleCenter = vec2(m.x, -bendCircleRadius + m.y + 1.0/PI);
    vec2  up = UnbendPoint(p, bendCircleCenter, bendCircleRadius, bendAmount, m.x);
    vec3  pattern = GetCheckboard(up);

    float sl = abs(up.y) * 150.0;
    sl = 1.0 - clamp(sl, 0.0, 1.0);
    sl = clamp(sl * 2.0, 0.0, 1.0);
    
    vec3 col = pattern;
    col = mix(col, col * 0.5, up.y < 0.0 ? 1.0 : 0.0);
    col = mix(col, vec3(0.1, 0.1, 0.1), sl);
    col = mix(col, col * 0.0, vignette);
    glFragColor = vec4(col, 1.0);
}
