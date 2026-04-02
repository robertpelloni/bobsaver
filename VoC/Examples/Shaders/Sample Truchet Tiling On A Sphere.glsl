#version 420

// original https://www.shadertoy.com/view/slcyz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Texture is made by using Truchet tiling. Each tile has 8 "connection points", 
//and 4 lines going from one point to another. Pattern of each tile is totaly random. 
//Texture is mapped to sphere by cubemapping. It uses two layers of Truchet tiling,
//If you want to increase your fps, just switch USE_TWO_LAYERS to false

//All of code made fully by myself, especially tiling and cube mapping.
//A just could not found how cube mapping works on the internet, so made
//formula by myself =)

//The way of generating this pattern and the idea of cubemapping was inspired by BigWIngs

#define PI 3.14159265359

#define USE_TWO_LAYERS true

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float rand(float p)
{
    return fract(sin(p * 1.231 + 4.123) * 5.212 + 5.214);
}

mat2 rmatrix(float a)  //--Function to rotate 2d vector
{
    float c = cos(a);
    float s = sin(a);

    return mat2(c, -s, s, c);
}

float lineDist(vec2 p, vec2 p1, vec2 p2)   //Distance to line starting and ending at p1 and p2 accordingly
{
    float h = dot(p - p1, p2 - p1) / pow(length(p2 - p1), 2.0);

    h = max(0.0, min(1.0, h));

    vec2 p3 = p1 * (1.0 - h) + p2 * h;
    return (length(p - p3));
}

float bezier(vec2 p, vec4 p1, vec4 p2)  //Distance to Bezier Curve. p1 and p2 
                                        //have subpoints coordinates at zw components
{
    float minDist = -1.0;
    float steps = 15.0;
    vec2 lp1 = p1.xy;
    vec2 lp2;

    for (float t = 1.0 / steps; t <= 1.01; t += 1.0 / steps)
    {
        vec2 A = p1.xy * (1.0 - t) + p1.zw * t;
        vec2 B = p1.zw * (1.0 - t) + p2.zw * t;
        vec2 C = p2.zw * (1.0 - t) + p2.xy * t;

        vec2 D = A * (1.0 - t) + B * t;
        vec2 E = B * (1.0 - t) + C * t;

        vec2 F = D * (1.0 - t) + E * t;

        lp2 = F;

        float dist = lineDist(p, lp1, lp2);

        if (minDist == -1.0 || dist < minDist)
            minDist = dist;

        lp1 = lp2;
    }

    return (minDist);
}

vec2 getPointByID(float i, float a1, float a2)  //Getting coordinate of connection point dy id
{
    vec2 p1;

    float iEdge = floor(i / 2.0);

    if (iEdge < 1.)
        p1.xy = vec2(a1 + a2 * step(0.5, fract(i / 2.0)), 0);
    else if (iEdge < 2.)
        p1.xy = vec2(1.0, a1 + a2 * step(0.5, fract(i / 2.0)));
    else if (iEdge < 3.)
        p1.xy = vec2(1.0 - a1 - a2 * step(0.5, fract(i / 2.0)), 1.0);
    else if (iEdge < 4.)
        p1.xy = vec2(0.0, 1.0 - a1 - a2 * step(0.5, fract(i / 2.0)));
    else
        p1.xy = vec2(0.5, 0.5);

    return (p1);
}

float bezierID(vec2 p, float i, float j)   //Distance to bezier curve by id of points
{
    vec4 p1, p2;

    float k1 = 0.33;
    float k2 = 0.2;

    float a1 = k1;
    float a2 = 1.0 - 2.0 * k1;

    float iEdge = floor(i / 2.0);
    float jEdge = floor(j / 2.0);

    p1.xy = getPointByID(i, a1, a2);
    p2.xy = getPointByID(j, a1, a2);

    if (iEdge == 0.0)
        p1.zw = vec2(p1.x, k2);
    else if (iEdge == 2.0)
         p1.zw = vec2(p1.x, 1.0 - k2);
    else if (iEdge == 1.0)
         p1.zw = vec2(1.0 - k2, p1.y);
    else if (iEdge == 3.0)
        p1.zw = vec2(k2, p1.y);

    if (jEdge == 0.0)
        p2.zw = vec2(p2.x, k2);
    else if (jEdge == 2.0)
         p2.zw = vec2(p2.x, 1.0 - k2);
    else if (jEdge == 1.0)
         p2.zw = vec2(1.0 - k2, p2.y);
    else if (jEdge == 3.0)
        p2.zw = vec2(k2, p2.y);

    return (bezier(p, p1, p2));
}

void getPath(vec2 id, out float path[8])  //Get the random path of each of four lines
{
    bool used[8] = bool[8](false, false, false, false, false, false, false, false);

    int an = 8;
    
    float rnum = rand(id);

    for (int i = 0; i < 8; i++)
    {
        rnum = rand(rnum) * float(an);
        int x = -1;

        for (float j = 0.0; j < rnum; j++)
        {
            x++;
            while (used[x])
                x++;
        }
        path[i] = float(x);
        used[x] = true;
        an--;
    }
}

void getTile(vec2 p, vec2 id, inout vec3 color) //Get the tile and ad it to color
{
    float lineW = 0.1;
    float shadow = 0.1;
    float path[8];

    getPath(id, path);

    for (int i = 0; i < 4; i++)
    {
        float res = bezierID(p, path[i * 2], path[i * 2 + 1]);

        if (res < lineW)
            color = vec3(1);
        else if (res < lineW + shadow)
            color *= 1.0 - (1.0 - (res - lineW) / shadow) * 0.8;
    }
}

void getTex(vec2 uv, inout vec3 color)   //This function just makes two layers of Truchet pattern
{
    vec2 uv1 = uv * 5.0;
    vec2 uv2 = uv;
    
    if (USE_TWO_LAYERS)
        getTile(fract(uv1), floor(uv1), color);
    getTile(fract(uv2), floor(uv2), color);
}

vec3 getRayDir(vec3 cameraDir, float cameraAngle, vec2 coord)
{
    vec3 xAxis = normalize(vec3(-cameraDir.z, 0, cameraDir.x)) * tan(cameraAngle / 2.0);
    vec3 yAxis = normalize(cross(cameraDir, xAxis)) * tan(cameraAngle / 2.0) * -1.0;
    vec3 result = normalize(cameraDir + xAxis * coord.x + yAxis * coord.y);

    return (result);
}

float map(in vec3 p)
{
    return length(p) - 0.4;
}

float marchRay(vec3 rayOrigin, vec3 rayDir)
{
    float t;
    float d = 0.0;
    float e = 0.001;
    float maxRange = 100.0;
    vec3 pos;

    for (t = 0.0; t <= maxRange; t += d)
    {
        pos = rayOrigin + rayDir * t;
        d = map(pos);

        if (d < e)
            break;
    }
    if (t > maxRange)
        return (-1.0);
    return (t);
}

vec3 getNorm(vec3 pos)
{
    vec2 e = vec2(0.0001, 0);
    float tp = map(pos);

    vec3 norm = -normalize(vec3(map(pos - e.xyy) - tp,
                               map(pos - e.yxy) - tp,
                               map(pos - e.yyx) - tp));
    return (norm);
}

vec3 cubeMap(vec3 p)   //Function for mapping 2d texture to 3d sphere
{
    vec3 ap = abs(p);
    float m = max(ap.x, max(ap.y, ap.z));
    vec2 uv;
    float side;

    if (ap.x == m)
    {
        uv.x = atan(p.z, p.x) / (PI / 4.0);
        uv.y = atan(p.y, p.x) / (PI / 4.0);
        side = 1.0 * sign(p.x);
    }
    if (ap.z == m)
    {
        uv.x = atan(p.x, p.z) / (PI / 4.0);
        uv.y = atan(p.y, p.z) / (PI / 4.0);
        side = 2.0 * sign(p.z);
    }
    if (ap.y == m)
    {
        uv.x = atan(p.x, p.y) / (PI / 4.0);
        uv.y = atan(p.z, p.y) / (PI / 4.0);
        side = 3.0 * sign(p.y);
    }
    return vec3(uv, side);
}

void main(void)
{
    vec2 uv;
    vec2 screenUV = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.y;
    
    vec3 color = vec3(0);
    
    float camPitch = cos(time / 35.0);
    float camYaw = time / 25.0;
    float cameraDist = 2.0;
    
    vec3 cameraPos = cameraDist * vec3(cos(camYaw) * cos(camPitch), sin(camPitch), sin(camYaw) * cos(camPitch));
    vec3 cameraDir = -normalize(cameraPos);
    
    vec3 rayDir = getRayDir(cameraDir, PI / 3.0, screenUV);

    vec3 p = rayDir;

    float t = marchRay(cameraPos, rayDir);

    if (t != -1.0) //---if ray hit the sphere----
    {
        vec3 sp = cameraPos + rayDir * t;
        vec3 cm = cubeMap(sp);
        uv = cm.xy;
        uv *= 4.0;
        uv += 100.0 * cm.z;
        color = vec3(0.05);
        getTex(uv, color);
    }
    else
    {
        vec3 cm = cubeMap(p);
        uv = cm.xy;
        uv *= 10.0;
        uv += 100.0 * cm.z;
        getTex(uv, color);
        color *= 0.5;
    }

    float r = length(screenUV);

    color *= (1.0 - r);

    glFragColor = vec4(color, 1.);
}
