#version 420

// original https://www.shadertoy.com/view/4lG3RD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Material
{
    vec4    m_Color;
    vec4    m_EmissiveColor;
    float     m_Specular;
    float     m_Reflection;
    float     m_Opacity;
    float    m_Refraction;
};

struct WorldObject
{
    vec3         m_Position;
    float         m_Scale;
    Material     m_Material;
    float         m_DistanceField;
};
    
// Constants
const float EPSILON = 0.01;
const int MAX_STEPS = 64;
const float STEP_REDUCTION = 1.0;
const float PI = 3.14159;

const float FOGGINESS_FACTOR = 1.0 / 20.0;
const float CONSTANT_FOG_FACTOR = 1.0;
const vec4 SKY_COLOR = vec4(0.5,0.6,0.7, 1.0);
const vec4 SUN_COLOR = vec4(1.0,0.9,0.7, 1.0);
const vec3 SUN_DIRECTION = vec3(cos(PI * 1.25), sin(PI * 1.25), 0.0);
const float SUN_POWER_FACTOR = 2.0;

// Declarations
vec4 PointLight(in vec3 point, in vec3 lightPosition, in Material color);
void RenderImage(in vec3 point, out float stepSize, out Material color);

// Math methods
float LengthSquared(in vec3 vector)
{
    return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z;
}

float ShiftRange(in vec2 sourceRange, 
                 in vec2 destRange, 
                 in float value)
{
    float sourceMagnitude     = sourceRange.y - sourceRange.x;
    float destMagnitude     = destRange.y - destRange.x;
    
    float unitValue = (value - sourceRange.x) / sourceMagnitude;
    float shiftedValue = (value * destMagnitude) + destRange.x;
    
    return shiftedValue;
}

float Rand(vec2 randInput)
{ 
    return fract(sin(dot(randInput, vec2(12.9898, 4.1414))) * 43758.5453);
}

float Noise(vec2 noiseInput) 
{
    const vec2 d = vec2(0.0, 1.0);
      vec2 b = floor(noiseInput), f = smoothstep(vec2(0.0), vec2(1.0), fract(noiseInput));
    return mix(mix(Rand(b), Rand(b + d.yx), f.x), mix(Rand(b + d.xy), Rand(b + d.yy), f.x), f.y);
}

float Equal(in float left, 
            in float right)
{
    float under = step(left - EPSILON * 0.001, right);
    float over     = step(right, left + EPSILON * 0.001);
    
    return under * over;
}

vec2 ShiftRange(in vec2 sourceRange, 
                 in vec2 destRange, 
                 in vec2 value)
{
    float sourceMagnitude     = sourceRange.y - sourceRange.x;
    float destMagnitude     = destRange.y - destRange.x;
    
    vec2 unitValue = (value - sourceRange.x) / sourceMagnitude;
    vec2 shiftedValue = (value * destMagnitude) + destRange.x;
    
    return shiftedValue;
}

struct Camera
{
    vec3     m_Position;
    vec3     m_Up;
    vec3     m_Forward;
    vec3     m_Right;
    float     m_FocalDistance;
};
    
// Global
Camera g_MainCamera;

vec3 RayDirection(in vec3     forward,
                  in float     focalDistance,
                  in vec3     right,
                  in vec3     up,
                  in vec2     screenSpaceCoord,
                  in float     aspectRatioXOverY)
{
    return normalize(forward * focalDistance + 
                     right * screenSpaceCoord.x * aspectRatioXOverY +
                     up * screenSpaceCoord.y);
}

vec3 CalculateWorldPoint(in vec3 origin, 
                         in vec3 direction, 
                         in float stepSize)
{
    return origin + direction * stepSize;
}

    
// Distance Field Methods:
    
float SphereDistanceField(in vec3 point, 
                         in float radius)
{
    
    return length(point) - radius;
}

float BoxDistanceField(in vec3 point,
                       in vec3 bounds)
{
    return length(max(abs(point)-bounds, 0.0));
}

float PlaneDistanceField(in vec3 point,
                         in vec3 axis)
{
    return distance(point * axis, axis);
}

float CylinderDistanceField( vec3 point, float bounds )
{
  return length(point.xz)-bounds;
}

float CappedCylinderDistanceField( vec3 point, vec2 bounds )
{
  vec2 dist = abs(vec2(length(point.xz),point.y)) - bounds;
  return min(max(dist.x,dist.y),0.0) + length(max(dist,0.0));
}

float EllipsoidDistanceField( in vec3 point, in vec3 bounds )
{
    return (length( point/bounds ) - 1.0) * min(min(bounds.x,bounds.y),bounds.z);
}

float CapsuleDistanceField( vec3 point, vec3 capsuleStart, vec3 capsuleEnd, float radius )
{
    vec3 pa = point - capsuleStart, ba = capsuleEnd - capsuleStart;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - radius;
}
                         
                         
          
// Distortion Methods

vec3 Translate(in vec3 point,
               in WorldObject object)
{
    return point - object.m_Position;
}

vec3 Scale(in vec3 point,
           in WorldObject object)
{
    return point / object.m_Scale;
}
               

vec3 Repeat(in vec3 point,
            in vec3 axis,
            in vec3 repeatFactor)
{
    vec3 repeatedPoint;
    repeatedPoint = mod(point, repeatFactor) - repeatFactor * 0.5;
    repeatedPoint = repeatedPoint * axis + (vec3(1) - axis) * point;
    
    return repeatedPoint;
}

// Scene creation
float Union(float left, float right)
{
    return min(left, right);
}

float Substraction(float source, float substract)
{
    return max(source, -substract);
}

float Intersection(float left, float right)
{
    return max(left, right);
}

// Retrieve the normal for the world
vec3 CalculateWorldNormal(in vec3 point)
{
    const float SAMPLE_SIZE = 0.1;
    vec3 gradient = vec3(0);
    
    float leftStep = 0.0;
    float rightStep = 0.0;
    Material unusedColor;
    
    RenderImage(point + vec3(SAMPLE_SIZE, 0,0), leftStep, unusedColor);
    RenderImage(point - vec3(SAMPLE_SIZE, 0,0), rightStep, unusedColor);
    gradient.x = leftStep - rightStep;
    
    RenderImage(point + vec3(0, SAMPLE_SIZE,0), leftStep, unusedColor);
    RenderImage(point - vec3(0, SAMPLE_SIZE,0), rightStep, unusedColor);
    gradient.y = leftStep - rightStep;
    
    RenderImage(point + vec3(0, 0,SAMPLE_SIZE), leftStep, unusedColor);
    RenderImage(point - vec3(0, 0,SAMPLE_SIZE), rightStep, unusedColor);
    gradient.z = leftStep - rightStep;
    
    return normalize(gradient);
}

float Mandlebrot(vec2 uv)
{
    vec2 z = vec2(0.0);

    for(int i=1; i<64; i++) 
    {
        z = vec2(z.x*z.x-z.y*z.y, 2.*z.x*z.y) + uv; 
        if(length(z) > 2.) 
        {
           return float(i) / 64.;
        }
       }
    
    return 1.0;
}

void RenderImage(in vec3 point, 
                 out float stepSize, 
                 out Material material)
{
    
    vec3 shapePoint = point;
    // Create a floor
    WorldObject floorPlane;
    floorPlane.m_Position = vec3(0, -2.5, 0);
    floorPlane.m_Material.m_Color = vec4(0.6, 0.6, 0.6, 1.0);
    floorPlane.m_Material.m_Specular = 40.0;
    floorPlane.m_Material.m_Opacity = 1.0;
    
    shapePoint = Translate(shapePoint, floorPlane);
    
   
    //shapePoint.y += noiseResult;

    
    float scale = 1.0 / 5.0;
    floorPlane.m_DistanceField = shapePoint.y - (-1.0 + Mandlebrot(point.xz * scale) * 1.0);
    
    //+ Mandlebrot(point.xz * scale)* 5.0
    
    stepSize =  floorPlane.m_DistanceField + shapePoint.y;

}

struct PointLightData
{
    vec3     m_Position;
    float     m_AttenuationRadius;
    float     m_AttenuationExponent;
    vec4     m_Color;
};

struct DirectionalLightData
{
    vec4 m_Color;
    vec3 m_Direction;
};

vec4 CalculateDirectionalLight(in vec3 point,
                in DirectionalLightData light,
                in Material material,
                in vec3 normal)
{
    vec3 worldNormal = normal;
    vec3 surfaceToLight = -light.m_Direction;
    
    
    // Calculate how much diffuse
    float diffuseFactor = max(dot(surfaceToLight, worldNormal), 0.0);
    vec4 diffuseColor = vec4(1.0) * diffuseFactor;
    
    
    
    return diffuseColor;
    
}

vec4 RenderLighting(in vec3 point,
                    in Material material,
                    in vec3 normal)
{
    DirectionalLightData centerLight;
    centerLight.m_Direction = SUN_DIRECTION;
    centerLight.m_Color = vec4(1.0,1.0,1.0, 1.0);
    
    vec4 lighting = CalculateDirectionalLight(point, centerLight, material, normal);
    
    
    return lighting;
}

const vec4 WORLD_COLOR = vec4(0, 0, 0, 1);

void main(void){
    
    vec4 finalColor = WORLD_COLOR;
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 screenSpace = ShiftRange(vec2(0, 1), vec2(-1, 1), uv);
    
    Camera camera;
    camera.m_Position         = vec3(cos(time) * 7.0,2.0,sin(time)*7.0);
    camera.m_Up             = vec3(0,1,0);
    camera.m_Forward         = normalize(vec3(0) - camera.m_Position);
    camera.m_Right            = normalize(cross(camera.m_Up, camera.m_Forward));
    camera.m_FocalDistance     = 1.0;
    vec3 cameraRay = RayDirection(camera.m_Forward,
                                  camera.m_FocalDistance,
                                  camera.m_Right,
                                  camera.m_Up,
                                  screenSpace,
                                  resolution.x / resolution.y);
    
    g_MainCamera = camera;
    
    float previousStep = 0.0;
    float currentStep = 0.0;
    
    vec3 worldPoint = vec3(0.0);
    for(int i = 0; i < 64; ++i)
    {
        worldPoint = CalculateWorldPoint(camera.m_Position, cameraRay, currentStep);
        
        Material objectMaterial;
        float renderStep = 0.0;
        
        RenderImage(worldPoint, renderStep, objectMaterial);
        
        // multiply the epsilon to be more lenient towards the back
        if(renderStep < 0.01)
        {
            vec3 normal = CalculateWorldNormal(worldPoint);
            vec4 lightingColor =  RenderLighting(worldPoint, objectMaterial, normal);
            
            finalColor = lightingColor;
            
           
            break;
        }
        
        previousStep = renderStep;
        currentStep += renderStep * (float(i) / 64.0);
    }
    
    
    float sunAmount = max( dot( cameraRay, -SUN_DIRECTION ), 0.0 );
    vec4  fogColor  = mix( vec4(0.4,0.6,0.7,1.0), // bluish
                           vec4(1.0,0.9,0.7,1.0), // yellowish
                           pow(sunAmount,10.0) );
    
    float b = 0.03;
    finalColor = mix(finalColor, fogColor, 1.0 - exp(-currentStep*b));
    
    glFragColor = finalColor;
}
