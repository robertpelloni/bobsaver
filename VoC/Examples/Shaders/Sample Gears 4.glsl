#version 420

// original https://www.shadertoy.com/view/wlyXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//properties
float sphereSize = 0.5;
float innerRadius = 0.1;
float gearCenterSize = 0.1;
float theetSize = 0.2;
float theetNumber = 10.0;
float squareSize = 0.04;
float speed = -1.0;
float padding = 0.003;
float degToRad = 0.01745329251;

// Make a rotation matrice from an angle in radians
mat2x2 Rotation(float angle)
{
    mat2x2 rot = mat2x2(cos(angle), -sin(angle),
                        sin(angle), cos(angle));
    return rot;
}

//Create a square shape and center it in the center of the screen
float Square(vec2 squareUV, vec2 offset, float sizeX, float sizeY, float rotation)
{
    float screenRatio = resolution.x / resolution.y;
    mat2x2 rot = Rotation(rotation);
    
    squareUV -= vec2(screenRatio * 0.5,0.5);
    squareUV = rot * squareUV;
    squareUV += vec2(screenRatio * 0.5,0.5);
    
    squareUV -= offset;
    squareUV = abs(squareUV - vec2(screenRatio *0.5,0.5));
        
    return smoothstep(sizeX + padding , sizeX, squareUV.x) * smoothstep(sizeY + padding , sizeY, squareUV.y);
    //return clamp( min( sizeX - squareUV.x, sizeY - squareUV.y) / fwidth(squareUV.x) + 0.5, 0.0, 1.0);
}

//Create a sphere at the center of the screen
float Sphere(float radius, vec2 sphericalUV)
{
    float sphere = length(sphericalUV);
    return smoothstep(radius + padding,radius,sphere);
}

//Place a bunch of square around the center of the screen and orient them
float Theet(float numberTheet, float offset, vec2 resizeUV, float squareSize)
{
    float square = 0.0;
    for(int i = 0; i <= int(numberTheet); i++)
    {
        float segment = 360.0 / numberTheet;
        float rotation = segment * float(i);
        rotation *= degToRad;
        
        square += Square(resizeUV, vec2(offset,0.0), squareSize, squareSize, rotation);
    } 
    return square;
}

float Gear(vec2 uv, vec2 offset, float size, float speed, float numberTheet, float supportNumber, float theetSize, float timeOffset)
{
    float screenRatio = resolution.x / resolution.y;
    
    
    //Make base UV  
    uv *= size;
    uv -= (size - 1.0) * 0.5;
    
    
    vec2 sphericalUV = -1. + 2. * uv;        
    vec2 resizeUV = uv;
    resizeUV.x *= screenRatio;
    sphericalUV.x *= screenRatio;
    resizeUV -= offset * 0.5;

    //Make uv Rotate
    mat2x2 rot = Rotation((time + timeOffset) * speed);
    resizeUV -= vec2(screenRatio * 0.5,0.5);
    resizeUV = rot * resizeUV;
    resizeUV += vec2(screenRatio * 0.5,0.5);
    
    sphericalUV -= offset;
    
    //Create two anulus, one for the exterior and one for the interior
    float gearCenter = Sphere(gearCenterSize, sphericalUV);
    float innerCircle = Sphere(sphereSize - innerRadius, sphericalUV);
    float gearHole = Sphere(gearCenterSize * 0.5, sphericalUV);
    float sphere = Sphere(sphereSize, sphericalUV);
    sphere -= innerCircle;
    sphere += gearCenter;
    sphere -= gearHole * (supportNumber + 1.0) * 5.0;
    
    //Create Theets
    float square = Theet(numberTheet, sphereSize * 0.5 + theetSize * 0.5, resizeUV, theetSize);
    
    //Add theets to the gear
    float gear = square + sphere;
    
    //Add support line for the gear
    float support = 0.0;
    for(int i = 0; i <= int(supportNumber); i++)
    {
        float segment = 180.0 / supportNumber;
        support += Square(resizeUV, vec2(0.0,0.0), innerRadius * 0.2, sphereSize * 0.45, segment * float(i) * degToRad);
    }
    gear += support;    
    
    //Clamp the result between 0 and 1
    gear = clamp(gear,0.0,1.0);
    return gear;
}

//
//Compute image
//
void main(void)
{
    //Base UV
    vec2 uv = gl_FragCoord.xy / resolution.xy;  
    
    //Generate Gears and create a composition
    //Composition 1
    float gear = Gear(uv, vec2(0.0,0.0), 1.0, -1.0, theetNumber, 3.0, squareSize, 0.0);
    //Composition 2
    vec2 comp2Offset = vec2(1.3,-1.5);
    float comp2Size = 1.6;
    
    gear += Gear(uv, vec2(0.0,0.0) + comp2Offset, 1.0 * comp2Size, -1.0, theetNumber, 3.0, squareSize, 0.0);
    gear += Gear(uv, vec2(1.7,0.0) + comp2Offset * 2.0, 2.0 * comp2Size, 2.0, theetNumber * 0.5, 2.0, squareSize * 1.8, 0.0);
    gear += Gear(uv, vec2(1.2,0.8) + comp2Offset, 1.0 * comp2Size, -1.0, theetNumber, 3.0, squareSize, 0.45);  
    gear += Gear(uv, vec2(-1.7,0.0) + comp2Offset * 2.0, 2.0 * comp2Size, 2.0, theetNumber * 0.5, 2.0, squareSize * 1.8, 0.3); 
    //Composition 3
    vec2 comp3Offset = vec2(-2.5,1);
    float comp3Size = 1.6;
    
    gear += Gear(uv, vec2(0.0,0.0) + comp3Offset, 1.0 * comp3Size, -1.0, theetNumber, 3.0, squareSize, 0.0);
    gear += Gear(uv, vec2(-0.5,-1.66) + comp3Offset * 2.0, 2.0 * comp3Size, 2.0, theetNumber * 0.5, 3.0, squareSize * 2.0, 0.35);
    gear += Gear(uv, vec2(1.45,0.95) + comp3Offset * 2.0, 2.0 * comp3Size, 2.0, theetNumber * 0.5, 3.0, squareSize * 2.0, 0.25);
    gear += Gear(uv, vec2(2.65,0.95) + comp3Offset * 2.0, 2.0 * comp3Size, -2.0, theetNumber * 0.5, 3.0, squareSize * 2.0, 0.25);
    
    //Show Gear
    glFragColor = vec4(gear, gear, gear, 1.0);
}
