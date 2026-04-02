#version 420

// R a y   m a r c h i n g
// f i r s t   e x p e r i m e n t
// by Matteo Basei
// http://www.matteo-basei.it
// https://www.youtube.com/c/matteobasei

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

const float PI = 3.141592653589;

const int MAX_STEPS = 100;
const float MAX_DISTANCE = 100.0;
const float MIN_DISTANCE = 0.01;
const float NORMAL_EPSILON = 0.0001;
const float SHADOW_FACTOR = 0.5;

float getDistance(vec3 position)
{    
    vec2 columnPosition = vec2(0.5, 0.5);
    float columnRadius = 0.1;
    
    position = mod(position, 1.0);

    vec2 relativePosition = position.xz - columnPosition;
    float angle = PI + atan(relativePosition.y, relativePosition.x);

    float capital = 4.0 * max(0.0, position.y - 0.75);
    if (capital > 0.0)
    {
        columnRadius += 0.05 * sin(PI * capital) +
                        0.01 * abs(sin(6.0 * PI * capital)) -
                        0.02 * abs(sin(4.0 * angle)) * sin(PI * capital) -
                        0.005 * abs(sin(8.0 * angle)) * sin(PI * capital);
    }
    else
    {
        columnRadius -= 0.005 * max(0.0, sin(12.0 * angle));
    }
    
    float columnDistance =  length(relativePosition) - columnRadius;

    return columnDistance;
}

vec3 getNormal(vec3 position)
{
    vec3 near = vec3(getDistance(position - vec3(NORMAL_EPSILON, 0.0, 0.0)),
                     getDistance(position - vec3(0.0, NORMAL_EPSILON, 0.0)),
                     getDistance(position - vec3(0.0, 0.0, NORMAL_EPSILON)));
    
    vec3 direction = getDistance(position) - near;

    return normalize(direction);
}

float getRaymarch(vec3 point, vec3 direction)
{
    float result = 0.0;
    
    for (int i = 0; i < MAX_STEPS; ++i)
    {
        float distance = getDistance(point);
        
        result += distance;
        point += distance * direction;
        
        if (distance < MIN_DISTANCE ||
            result > MAX_DISTANCE) break;
    }
    
    return result;
}

float getLight(vec3 position, vec3 absoluteLightPosition)
{
    vec3 normal = getNormal(position);
    vec3 lightPosition = absoluteLightPosition - position;
    vec3 lightDiretion = normalize(lightPosition);
    float lightDistance = length(lightPosition);

    float result = clamp(dot(normal, lightDiretion), 0.0, 1.0);

    float lightRaymarch = getRaymarch(position + normal * MIN_DISTANCE * 2.0, lightDiretion);
    if (lightRaymarch < lightDistance) result *= SHADOW_FACTOR;

    return result;
}

vec3 getDirection(vec2 pixel, vec2 angle)
{
    vec3 direction = normalize(vec3(pixel, 1.0));

    float cosAngleX = cos(angle.x);
    float cosAngleY = cos(angle.y);
    float sinAngleX = sin(angle.x);
    float sinAngleY = sin(angle.y);

    mat2 rotationY = mat2(cosAngleX, sinAngleX,
                         -sinAngleX, cosAngleX);
    mat2 rotationX = mat2(cosAngleY, sinAngleY,
                         -sinAngleY, cosAngleY);

    direction.yz *= rotationX;
    direction.xz *= rotationY;
    
    return direction;
}

void main()
{
    vec2 pixel = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    pixel.y *= resolution.y / resolution.x;
    
    vec2 angle = PI * (mouse - 0.5);

    vec3 lightPosition = vec3(0.0, 0.5, 0.5 * time - 0.5);
    vec3 cameraPosition = vec3(0.0, 0.5, 0.5 * time);
    vec3 cameraDirection = getDirection(pixel, angle);

    float pointDistance = getRaymarch(cameraPosition, cameraDirection);
    
    vec3 point = cameraPosition + cameraDirection * pointDistance;

    vec3 color = vec3(getLight(point, lightPosition) / max(1.0, pointDistance));

    glFragColor = vec4(color, 1.0);
}
