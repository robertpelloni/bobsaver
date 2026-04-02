#version 420

// original https://www.shadertoy.com/view/XdlyD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Camera
vec3 CameraPos = vec3(7.0, 3.0, -7.0);
vec3 TargetPoint = vec3(2.0, 0.0, 0.0);

vec3 currentColor = vec3(1.0, 1.0, 1.0);
const float EPSILON_RAYMARCH = 0.01;
const float EPSILON_NORMAL = 0.0001;
const int RAYMARCHING_STEP = 64;
const float MOVE_SPEED = 2.0;
const float ROTATION_SPEED = 0.2;

// -----TRANSFORMATION-------------------------
// Repetition
vec3 Repetition(vec3 p, vec3 c)
{
    return mod(p, c) - 0.5 * c;
}

// Rotation
vec3 Rotation( vec3 p, mat3 m )
{
    return inverse(m) * p;
}

// Translation
vec3 Translation(vec3 p, vec3 displacement)
{
    return p + displacement;
}
//---------------------------------------------

// Union
float Union(float previous, float current, vec3 color)
{
    if(previous < current)
        return previous;
    
    currentColor = color;
    return current;
}

// Intersection
float Intersection(float previous, float current, vec3 color)
{
    if(previous > current)
        return previous;
    
    currentColor = color;
    return current;
}

// Soustraction
float Substract(float previous, float current, vec3 color)
{
    if(previous > -current)
        return previous;
    
    currentColor = color;
    return current;
}

//------SHAPES---------------------------------
// Sphere
float SD_Circle(vec3 pos, float radius)
{
    return length(pos) - radius;
}

// Round Box
float SD_RoundBox(vec3 p, vec3 b, float r)
{
  return length(max(abs(p) - b, 0.0)) - r;
}

// Points of the dice
float SD_DicePoints(vec3 pos)
{
    // 1
    float val = SD_Circle(pos - vec3(-1.5, 0.0, 0.0), 0.3);
    
    // 2
    val = min(val, SD_Circle(pos - vec3(-0.70, 0.70, 1.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(0.70, -0.70, 1.5), 0.3));
    
    // 3
    val = min(val, SD_Circle(pos - vec3(-0.70, -1.5, 0.7), 0.3));
    val = min(val, SD_Circle(pos - vec3(0.70, -1.5, -0.7), 0.3));
    val = min(val, SD_Circle(pos - vec3(0.0, -1.5, 0.0), 0.3));
    
    // 4
    val = min(val, SD_Circle(pos - vec3(0.7, 1.5, 0.7), 0.3));
    val = min(val, SD_Circle(pos - vec3(-0.70, 1.5, 0.7), 0.3));
    val = min(val, SD_Circle(pos - vec3(-0.7, 1.5, -0.7), 0.3));
    val = min(val, SD_Circle(pos - vec3(0.70, 1.5, -0.7), 0.3));
    
    // 5
    val = min(val, SD_Circle(pos - vec3(0.0, 0.0, -1.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(0.70, 0.70, -1.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(-0.70, -0.70, -1.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(0.70, -0.70, -1.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(-0.70, 0.70, -1.5), 0.3));
    
    // 6 
    val = min(val, SD_Circle(pos - vec3(1.5, 0.70, 0.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(1.5, 0.70, -0.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(1.5, 0.0, 0.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(1.5, 0.0, -0.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(1.5, -0.70, 0.5), 0.3));
    val = min(val, SD_Circle(pos - vec3(1.5, -0.70, -0.5), 0.3));
    return val;
}
//---------------------------------------------

// Test all the SD function to determine the nearest point
float SceneSDF(vec3 pos)
{
    float moveTime = MOVE_SPEED * time;
    //pos = Translation(pos, vec3(moveTime, moveTime, moveTime));
    pos = Repetition(pos, vec3(12.0, 12.0, 12.0));
    
    float rotationTime = ROTATION_SPEED * time;
    
    pos = Rotation(pos, mat3(1.0, 0.0, 0.0,
                             0.0, cos(rotationTime), sin(rotationTime),
                             0.0, -sin(rotationTime),cos(rotationTime)));
    
    pos = Rotation(pos, mat3(cos(rotationTime), 0.0, sin(rotationTime),
                             0.0, 1.0, 0.0,
                             -sin(rotationTime), 0.0, cos(rotationTime)));
    
    float result = 999999999999999999.0;
    result = Union(result, SD_RoundBox(pos, vec3(1.5, 1.5, 1.5), 0.1), vec3(1.0, 0.0, 0.0));
    result = Intersection(result, SD_Circle(pos, 2.3), vec3(1.0, 0.0, 0.0));
    result = Substract(result, SD_DicePoints(pos), vec3(1.0, 1.0, 1.0));
    return result;
}

// Lambert lighting
float Lambert(vec3 lightDir, vec3 normal)
{
    return max(0.1, dot(lightDir, normal));
}

// Compute the normal by approximating the nearest points
vec3 ComputeNormal(vec3 pos, float currentDistance)
{
    return normalize(
        vec3(
            SceneSDF(pos + vec3(EPSILON_NORMAL, 0.0, 0.0)) - currentDistance,
            SceneSDF(pos + vec3(0.0, EPSILON_NORMAL, 0.0)) - currentDistance,
            SceneSDF(pos + vec3(0.0, 0.0, EPSILON_NORMAL)) - currentDistance)
    );
}

// Determine the distance of the objects
float RayMarching(vec3 origin, vec3 rayDir)
{
    float dist = 0.0;
    float nearest = 0.0;
    float result = 0.0;
    
    for(int i = 0; i < RAYMARCHING_STEP; i++)
    {
        vec3 currentPos = origin + rayDir * dist;
        nearest = SceneSDF(currentPos);
        if(nearest <= EPSILON_RAYMARCH)
        {
            vec3 lightDir1 = normalize(vec3(1.0, 1.0, -1.0));
            vec3 normal = ComputeNormal(currentPos, nearest);
            result = Lambert(lightDir1, normal);
            return result;
        }
        dist += nearest;
    }
    return result;
}

// LookAt Camera
mat3 setCamera()
{  
    vec3 zaxis = normalize(TargetPoint - CameraPos);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 xaxis = cross(up, zaxis);
    vec3 yaxis = cross(zaxis, xaxis);
    
    return mat3(xaxis, yaxis, zaxis);
}

// Pixel function
void main(void)
{
    // Move the camera
    //CameraPos.z += time * MOVE_SPEED;
    
    // Move the lookAt point
    //TargetPoint.z += time * MOVE_SPEED;

    // Compute LookAt Matrix
    mat3 lookAtMat = setCamera();
    
    // ray direction
    vec2 p = gl_FragCoord.xy / resolution.xy - 0.5;
    p.x *= resolution.x / resolution.y;
    vec3 RayDir = lookAtMat * normalize( vec3(p.xy,2.0) );
    
    float val = RayMarching(CameraPos, RayDir);
    vec3 col =  val * currentColor;
    glFragColor = vec4(col, 1.0);
}
