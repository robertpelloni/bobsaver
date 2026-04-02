#version 420

// original https://www.shadertoy.com/view/3tXBWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/// A simple 2D landscape created using Perlin noise.
/// Plus some strange-looking trees. :)

//Set the Tree Colours
vec3 branchColour;
vec3 leafColour;

//USEFUL FUNCTIONS//
//RNG Returning a Float (0. to 1.)
float randomValue(vec2 uv)
{
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

//RNG Returning a Vec2 (0. to 1.)
vec2 randomVector(vec2 uv)
{
    vec3 a = fract(uv.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(vec2(a.x * a.y, a.y * a.z));
}

//RNG Returning a Diagonal Vec2 (4 Directions)
vec2 randomLimitedVector(vec2 uv)
{
    vec2 randomVector = randomVector(uv);
    return vec2(round(randomVector.x) * 2. - 1.,
                round(randomVector.y) * 2. - 1.);
}

//Map
float map(float value, float currentMin, float currentMax, float targetMin, float targetMax)
{
    return targetMin + (targetMax - targetMin) * ((value - currentMin) / (currentMax - currentMin));
}

//Smootherstep
float smootherstep(float value)
{
    return 6.0 * pow(value, 5.) - 15. * pow(value, 4.) + 10. * pow(value, 3.);
}

vec2 lengthdir(vec2 basePoint, float direction, float lngth)
{
    return basePoint + vec2(cos(direction) * lngth, sin(direction) * lngth);
}

//RGB to HSV Converter
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//DRAW FUNCTIONS//
//Draw a Line
void drawLine(vec2 uv, vec2 point1, vec2 point2, float thickness, float blur, inout float value)
{
    //Get Sides of a Triangle
    float a = distance(uv, point2);
    float b = distance(uv, point1);
    float c = distance(point1, point2);
    
    //Calculate Point's Distance from the Line
    float distanceFromLine = sqrt(abs(pow(a, 2.) - pow((pow(a, 2.) - pow(b, 2.) + pow(c, 2.)) / (2. * c), 2.)));
    
    //Get Pixel's Value
    float pixelValue = smoothstep(thickness + blur, thickness, distanceFromLine);
    pixelValue *= smoothstep(thickness + blur, thickness, a + b - c);
    value = mix(value, 1., pixelValue);
}

//Draw a Disk
void drawDisk(vec2 uv, vec2 position, float radius, float blur, vec3 colour, inout vec3 value)
{
    float pixelValue = smoothstep(radius + blur, radius, distance(position, uv));
    value = mix(value, colour, pixelValue);
}

//Draw a Disk with Return Value
float diskValue(vec2 uv, vec2 position, float radius, float blur)
{
    return smoothstep(radius + blur, radius, distance(position, uv));
}

//Draw a Branch (Less Computationally Expensive drawLine)
void drawBranch(vec2 uv, vec2 point1, vec2 point2, float thickness, float blur, vec3 colour, inout vec3 value)
{
    //Get Sides of a Triangle
    float a = distance(uv, point2);
    float b = distance(uv, point1);
    float c = distance(point1, point2);
    
    //Calculate Point's Distance from the Line
    float distanceFromLine = sqrt(abs(pow(a, 2.) - pow((pow(a, 2.) - pow(b, 2.) + pow(c, 2.)) / (2. * c), 2.)));
    
    //Get Pixel's Value
    float pixelValue = smoothstep(thickness + blur, thickness, distanceFromLine);
    pixelValue *= float(a + b < c + thickness + blur);
    value = mix(value, colour, pixelValue);
}

//Draw a Tree
void drawTree(vec2 uv, vec2 basePoint, int branches, int iterations, float size, vec3 branchColour, vec3 leafColour, inout vec3 value)
{
    //Draw the Trunk
    drawBranch(uv, basePoint, vec2(basePoint.x, basePoint.y + size), 0.003, 0.001, branchColour, value);
    
    //Draw the Branches
    for (int i = 0; i < branches; i ++)
    {
        //Set Branch Properties
        float randomFactor = map(randomValue(vec2(basePoint.y) * float(i)), 0., 1., 0.3, 1.);
        float branchLength = size;
        float branchAngle = 50.;
        float branchThickness = 0.0015;
        
        //Set Previous && Current Branch Position
        vec2 currentBranch;
        vec2 previousBranch = lengthdir(basePoint, radians(90.), 
                                        distance(basePoint, vec2(basePoint.x, basePoint.y + size)) * randomFactor);
        for (int j = 0; j < iterations; j ++)
        {
            //Change the Branch Properties
            randomFactor = map(randomValue(vec2(previousBranch.y)), 0., 1., 0.5, 1.);
            branchLength *= 0.8 * randomFactor;
            branchAngle -= 15. * randomFactor;
            branchThickness -= 0.00025;
            
            float angleSign = sign(float(mod(float(j) + float(i), 2.) == 0.) - 0.5);
            float currentAngle = radians(90. + branchAngle * angleSign);
            float currentLength = branchLength * randomFactor;
            
            //Set Current Branch Position for Draw
            currentBranch = lengthdir(previousBranch, currentAngle, branchLength);
            drawBranch(uv, previousBranch, currentBranch, branchThickness, 0.001, branchColour, value);
            drawDisk(uv, currentBranch, 1. / (currentBranch.y - basePoint.y) * size * 0.03, 0.0001, leafColour, value);
            //drawDisk(uv, currentBranch, (currentBranch.y - basePoint.y) * 0.15, 0.0001, leafColour, value);
            
            //Set Current Branch Position for the Next Iteration
            currentBranch = lengthdir(previousBranch, currentAngle, currentLength);
            previousBranch = currentBranch;
        }
    }
}

//Perlin Noise
float perlinNoise(vec2 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float amplitude = 1.;
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get Pixel's Position Within the Cell && Cell's Position Within the Grid
        vec2 pixelPosition = fract(uv * frequency);
        vec2 cellPosition = floor(uv * frequency);

        //Get Gradient Vectors of the Cell's Points
        vec2 gradientVector1 = randomLimitedVector(cellPosition);
        vec2 gradientVector2 = randomLimitedVector(vec2(cellPosition.x + 1., cellPosition.y));
        vec2 gradientVector3 = randomLimitedVector(vec2(cellPosition.x, cellPosition.y + 1.));
        vec2 gradientVector4 = randomLimitedVector(vec2(cellPosition.x + 1., cellPosition.y + 1.));

        //Calculate Distance Vectors from the Cell's Points to the Pixel
        vec2 distanceVector1 = vec2(pixelPosition.x, - pixelPosition.y);
        vec2 distanceVector2 = vec2(- (1. - pixelPosition.x), - pixelPosition.y);
        vec2 distanceVector3 = vec2(pixelPosition.x, 1. - pixelPosition.y);
        vec2 distanceVector4 = vec2(- (1. - pixelPosition.x), 1. - pixelPosition.y);

        //Calculate Dot Product of the Gradient && Distance Vectors
        float dotProduct1 = dot(gradientVector1, distanceVector1);
        float dotProduct2 = dot(gradientVector2, distanceVector2);
        float dotProduct3 = dot(gradientVector3, distanceVector3);
        float dotProduct4 = dot(gradientVector4, distanceVector4);

        //Apply Smootherstep Function on the Pixel Position for Interpolation
        vec2 pixelPositionSmoothed = vec2(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y));

        //Interpolate Between the Dot Products
        float interpolation1 = mix(dotProduct1, dotProduct2, pixelPositionSmoothed.x);
        float interpolation2 = mix(dotProduct3, dotProduct4, pixelPositionSmoothed.x);
        float interpolation3 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        
        pixelValue += (interpolation3 * 0.5 + 0.5) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//Draw a Hill
void drawHill(vec2 uv, vec3 colour, float blur, float speed, float flatness, float xOffset, float yOffset, bool drawTrees, inout vec3 value, float frequency, int octaves, float lacunarity, float persistence)
{
    float noiseValue = perlinNoise(vec2(uv.x + xOffset + time * speed, 0.5), frequency, octaves, lacunarity, persistence) * flatness;
    float pixelValue = smoothstep(noiseValue, noiseValue - blur, uv.y - yOffset);
    value = mix(value, colour, pixelValue);
    
    if (drawTrees && uv.y < 0.8)
    {
        float treeX = floor(uv.x + xOffset + time * speed);
        treeX += map(randomValue(vec2(treeX)), 0., 1., 0.12, 0.88);
        float treeY = perlinNoise(vec2(treeX, 0.5), frequency, octaves, lacunarity, persistence) * flatness;
        drawTree(uv, vec2(treeX - xOffset - time * speed, treeY + yOffset - randomValue(vec2(treeX)) * 0.02), 4, 4, 0.17, branchColour, leafColour, value);
    }
}

//Draw a Fog
void drawFog(vec2 uv, vec2 yBorders, float speed, float density, float contrast, float frequency, int octaves, float lacunarity, float persistence, inout vec3 value)
{
    //Get the Noise Value
    float noiseValue = perlinNoise(vec2(uv.x * 0.8 + time * speed, uv.y), frequency, octaves, lacunarity, persistence);
    
    //Create Gradient Masks
    float densityGradient = smoothstep(yBorders.y + 0.6, yBorders.y, uv.y);
    float whiteGradient = smoothstep(yBorders.x + 0.3, yBorders.x - 0.2, uv.y) * 0.3 * density;
    
    //Adjust the Value
    noiseValue = smoothstep(0.2, 0.7, noiseValue) * densityGradient * 0.75 * density + whiteGradient;
    noiseValue = clamp(map(noiseValue, 0., 1., 0. - contrast, 1.1) * densityGradient, 0., 1.);
    value = mix(value, vec3(noiseValue + 0.2), noiseValue);
    //value = vec3(noiseValue);
}

//MAIN//
void main(void)
{
    //Remap the gl_FragCoord.xy
    vec2 uv = gl_FragCoord.xy / resolution.y;
    float aspectRatio = resolution.y / resolution.x;
    
    //Set the Colours
    vec3 skyColour1 = hsv2rgb(vec3(216. / 360., 17. / 100., 100. / 100.));
    vec3 skyColour2 = hsv2rgb(vec3(37. / 360., 34. / 100., 92. / 100.));
    
    vec3 hillColour1 = hsv2rgb(vec3(200. / 360., 16. / 100., 59. / 100.));
    vec3 hillColour2 = hsv2rgb(vec3(15. / 360., 6. / 100., 30. / 100.));
    vec3 hillColour3 = hsv2rgb(vec3(194. / 360., 35. / 100., 28. / 100.));
    
    branchColour = hsv2rgb(vec3(30. / 360., 35. / 100., 40. / 100.));
    leafColour = hsv2rgb(vec3(144. / 360., 50. / 100., 45. / 100.));
    
    vec3 sunColour = vec3(45. / 360., 0. / 100., 100. / 100.);    //in HSV model
    vec2 sunPosition = vec2(1.3, 0.7);
    
    //Set the Background Colour
    vec3 colourValue = mix(skyColour2, skyColour1, uv.y);
    
    //Draw the Sun
    sunColour.y = diskValue(uv, vec2(sunPosition.x, sunPosition.y - 0.15), 0.2, 0.8) * 0.4;
    colourValue *= hsv2rgb(sunColour);
    colourValue += diskValue(uv, vec2(sunPosition.x, sunPosition.y - 0.15), 0.1, 0.8) * 0.3;
    drawDisk(uv, sunPosition, 0.02, 0.005, vec3(1., 1., 1.), colourValue);
    
    //Draw the Hills && Fog
    drawHill(uv, hillColour1, 0.002, 0.1, 1., 6.8, 0.15, false, colourValue, 3., 6, 2., 0.5);
    drawFog(uv, vec2(0.35, 0.5), 0.12, 1., 0., 1.3, 6, 2., 0.5, colourValue);
    drawHill(uv, hillColour2, 0.002, 0.2, 0.8, 2.0, 0.05, false, colourValue, 2., 5, 2., 0.5);
    drawFog(uv, vec2(0.25, 0.3), 0.25, 0.6, 0., 1.4, 6, 2., 0.5, colourValue);
    drawHill(uv, hillColour3, 0.002, 0.5, 0.6, 4.0, - 0.05, true, colourValue, 0.9, 5, 1.9, 0.45);
    drawFog(uv, vec2(- 0.3, 0.2), 0.6, 0.4, 0., 1., 5, 2., 0.5, colourValue);
    
    //Find Out Wheter the Hills Are Overlaping the Sun
    float hillNoiseValue = perlinNoise(vec2(sunPosition.x + 6.8 + time * 0.1, 0.5), 3., 6, 2., 0.5);
    float sunIntensity = smoothstep(hillNoiseValue - 0.03, hillNoiseValue + 0.03, sunPosition.y - 0.15);
    
    //Draw the Sun Glow
    sunColour.y = diskValue(uv, sunPosition, 0.2, 0.8) * 0.3 * sunIntensity;
    colourValue *= hsv2rgb(sunColour);
    colourValue += diskValue(uv, sunPosition, 0.3, 0.8) * 0.1 * sunIntensity;
    colourValue += diskValue(uv, sunPosition, 0.05, 0.5) * 0.15 * sunIntensity;
    colourValue += diskValue(uv, sunPosition, 0.01, 0.3) * 0.2 * sunIntensity;
    colourValue += hsv2rgb(sunColour) * 0.1 * sunIntensity;
    float highlight = smoothstep(1., 0.7, (colourValue.r + colourValue.g + colourValue.b) / 3.);
    
    //Make the Scene Darker
    colourValue -= ((1. - sunIntensity) * 0.1) * highlight;
    colourValue -= (1. - diskValue(uv, vec2(0.89, 0.5), 0.4, 1.7)) * 0.3;
    
    //Set the glFragColor
    glFragColor = vec4(colourValue, 1.);
}
