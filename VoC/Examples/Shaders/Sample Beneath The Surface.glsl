#version 420

// original https://www.shadertoy.com/view/tsS3zR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float opUnion(float d1, float d2) { return min(d1, d2); }
float opIntersection(float d1, float d2) { return max(d1, d2); }
float opSubtraction(float d1, float d2) { return max(d1, -d2); }
float opOnion(float d, float thikness) { return abs(d) - thikness; }

mat2 rotMat(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    
    return mat2(c, s, -s, c);
}

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float sdFish(vec2 p, float r)
{
    float upperCircle = sdCircle(p - vec2(0, 0.6) * r, r);
    float lowerCircle = sdCircle(p - vec2(0, -0.6) * r, r);
    
    float upperTail = sdCircle(p - vec2(1.4, 0.5) * r, r);
    float lowerTail = sdCircle(p - vec2(1.4, -0.5) * r, r);
    
    float body = opIntersection(upperCircle, lowerCircle);
    float tail = opSubtraction(opIntersection(upperTail, lowerTail), sdCircle(p - vec2(2, 0) * r, r));
    float eye = sdCircle(p - vec2(-0.4, 0.1) * r, 0.07 * r);
    return opSubtraction(opUnion(body, tail), eye);
}

float sdMovingFish(vec2 p, float r, float t, float speed, float period)
{
    float x = mod(p.x + 0.5 + speed * t, period) - 0.5;
    return sdFish(vec2(x, p.y), r);
}

float sdRect(vec2 p, vec2 r)
{
    vec2 d = abs(p) - r;
    return length(max(d, 0.0))
        + min(max(d.x, d.y), 0.0);
}

float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2)
{
    vec2 v0 = p1 - p0;
    vec2 v1 = p2 - p1;
    vec2 v2 = p0 - p2;
    
    vec3 sd = vec3(
        dot(p - p0, normalize(vec2(-v0.y, v0.x))),
        dot(p - p1, normalize(vec2(-v1.y, v1.x))),
        dot(p - p2, normalize(vec2(-v2.y, v2.x)))
    );

    return max(sd[0], max(sd[1], sd[2]));
}

float sdBoat(vec2 p, float s)
{
    vec2[] points = vec2[](
        vec2(+1.5, 0.0) * s,
        vec2(-1.5, 0.0) * s,
        vec2(-2.0, 1.0) * s,
        vec2(+2.0, 1.0) * s,
        vec2(0) // to make the array cyclic
    );
    points[points.length() - 1] = points[0];
    int pointCount = points.length() - 1;
    
    mat2 normalMat = mat2(0.0, 1.0, -1.0, 0.0);
    
    float maxSd = -99999.0;
    
    for (int i = 0; i < pointCount; i++)
    {
        vec2 p0 = points[i];
        vec2 p1 = points[i + 1];
        vec2 normal = normalize(normalMat * (p1 - p0));
        float sd = dot(p - p0, normal);
        maxSd = max(maxSd, sd);
    }
    
    return maxSd;
}

float sdSail(vec2 p, float s)
{
    return sdTriangle(
        p,
        vec2(vec2(-1.0, 1.0) * s),
        vec2(vec2(+0.0, 2.0) * s),
        vec2(vec2(+1.0, 1.0) * s)
    );
}

float sdFisher(vec2 p)
{
    float body = sdRect(p, vec2(0.015, 0.05)) - 0.008;
    float head = sdCircle(p - vec2(0, 0.09), 0.03);
    float rod = sdRect((p - vec2(0.05, 0.03)) * rotMat(-1.0), vec2(0.004, 0.1));
    float line = sdRect(p - vec2(0.13, -0.17), vec2(0.002, 0.25));
    
    return opUnion(opUnion(body, head), opUnion(rod, line));
}

float sdHook(vec2 p, float s)
{
    float base = opUnion(sdCircle(p, s * 0.7), sdRect(p - vec2(0, -1.5) * s, vec2(0.3, 1.0) * s));
    float hookCircle = opOnion(sdCircle(p - vec2(0, -3.3) * s, s), 0.2 * s);
    float mask = sdRect(p - vec2(-1.2, -3) * s, vec2(1, 1.0) * s);
    float hook = opSubtraction(hookCircle, mask);
    return opUnion(base, hook);
}

vec2 flipX(vec2 v) { return vec2(-v.x, v.y); }

float waterLevel(float xn, float t)
{
    return 0.7 + sin(time * 2.0 + xn * 2.3) * 0.03;
}

float waterGradient(float xn, float t)
{
    return 2.0 * cos(time * 2.0 + xn * 2.3) * 0.03;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    // Pixel coordinates normalized by the screen height
    vec2 uvn = gl_FragCoord.xy/resolution.y;
    // The screen width normalized by screen height;
    float nWidth = resolution.x / resolution.y;
    
    float water = waterLevel(uvn.x, time);
    
    vec3 col = vec3(0.79);
    if (uvn.y < water)
    {
        //col = vec3(0.193, 0.434, 0.8) * uv.y / waterLevel;
        col = vec3(0, 0.58, 0.58) * uvn.y / water;
    }
    
    float[] fish = float[](
        sdMovingFish(uvn - vec2(nWidth * 0.0, 0.12),         0.2, time, 0.1, 3.0),
        sdMovingFish(flipX(uvn - vec2(nWidth * 0.9, 0.2)),     0.12, time, 0.1, 2.0),
        sdMovingFish(uvn - vec2(nWidth * 0.3, 0.33),         0.1, time, 0.3, 6.0),
        sdMovingFish(flipX(uvn - vec2(nWidth * 0.9, 0.4)),     0.09, time, 0.12, 4.0),
        sdMovingFish(uvn - vec2(nWidth * 0.6, 0.47),         0.08, time, 0.16, 2.3),
        sdMovingFish(flipX(uvn - vec2(nWidth * 0.7, 0.55)), 0.07, time, 0.15, 2.0),
        sdMovingFish(uvn - vec2(nWidth * 0.2, 0.46),         0.06, time, 0.13, 2.0),
        sdMovingFish(uvn - vec2(nWidth * 0.1, 0.35),         0.05, time, 0.17, 2.5),
        sdMovingFish(flipX(uvn - vec2(nWidth * 0.2, 0.43)), 0.04, time, 0.1, 2.7),
        sdMovingFish(flipX(uvn - vec2(nWidth * 0.7, 0.34)), 0.1, time, 0.08, 2.2),
        sdMovingFish(uvn - vec2(nWidth * 0.3, 0.23),         0.1, time, 0.07, 2.3)
        );
    
    for (int i = 0; i < fish.length(); i++)
    {
        if (fish[i] < 0.0)
        {
            col = vec3(0);
        }
    }
    
    ///// Boat /////
    
    float boatX = nWidth / 2.0;
    float boatY = waterLevel(boatX, time) - 0.03;
    vec2 boatPos = vec2(boatX, boatY);
    mat2 boatRot = rotMat(waterGradient(boatX, time));
    
    vec2 fisherPos = (boatRot * vec2(0.10, 0.10)) + boatPos;
    fisherPos = round(fisherPos * resolution.y) / resolution.y; // Round to nearest pixel
    
    if (sdSail((uvn - boatPos) * boatRot, 0.1) < 0.0)
    {
        col = vec3(0.93);
    }
    
    if (sdFisher(uvn - fisherPos) < 0.0)
    {
        col = vec3(0);
    }
    
    if (sdHook(uvn - fisherPos - vec2(0.13, -0.42), 0.01) < 0.0)
    {
        col = vec3(0.5);
    }
    
    if (sdBoat((uvn - boatPos) * boatRot, 0.1) < 0.0)
    {
        col = vec3(0.99);
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
