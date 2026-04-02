#version 420

// original https://www.shadertoy.com/view/wtfBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/// Simple tool for creating noise textures (in need of some optimization I guess :)).
/// You can modify the noise in the section below.

//CUSTOMIZE THE NOISE//
//Main Options
int noiseType = 2;    //0 - value noise; 1 - perlin noise; 2 - spaghetti noise; 3 - worley (voronoi) noise
int dimension = 1;    //0 - 2D noise; 1 - 3D noise (a bit slower than 2D)
float frequency = 10.;
bool combineNoises = true;    //specific noise values && their contribution to the main noise

//Properties
int octaves = 1;
float lacunarity = 2.;
float persistence = 0.5;
int vectorSet = 2;    //0 - normalized vector; 1 - horizontal-vertical vector; 2 - diagonal vector; 3 - 8-directional vector; 2D noises only
int nNearest = 1;    //worley noise only

//Motion
float noiseSpeed = 0.05;    //3D noise only
bool motion = true;    //worley noise only

//Mapping
float mapMin = - 0.4;
float mapMax = 0.85;
bool mapChange = false;

//Colour
/*vec3 colourMin = vec3(0.);    //value
vec3 colourMax = vec3(1.);*/
/*vec3 colourMin = vec3(0.63, 0.22, 0.13);    //spaghetti
vec3 colourMax = vec3(0.91, 0.77, 0.39);*/
vec3 colourMin = vec3(0.41, 0.84, 0.94) - 0.5;    //blue
vec3 colourMax = vec3(1.);

//USEFUL FUNCTIONS//
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

//RNG Returning a Direction Limited Vec2 (- 1. to 1.)
vec2 randomLimitedVector(vec2 uv, int type)
{
    vec2 randomVector = randomVector(uv);
    
    switch (type)
    {
        //Normalized Vector (Any Direction with Length 1)
        case 0:
        {
            return normalize(randomVector + 0.0001) * 2. - 1.;
        }
        break;
        
        //Horizontal-Vertical Vector (Right, Down, Left, Up)
        case 1:
        {
            
            return vec2(float(randomVector.x > 0.333) - 2. * float(randomVector.x > 0.666),
                        sign(randomVector.y * 2. - 1.) * float(randomVector.x < 0.333));
        }
        break;
        
        //Diagonal Vector (Right Down, Left Down, Left Up, Right Up)
        case 2:
        {
            return vec2(float(randomVector.x > 0.5) * 2. - 1.,
                        float(randomVector.y > 0.5) * 2. - 1.);
        }
        break;
        
        //8-Directional Vector (Rigth, Right Down, Down, Left Down, Left, Left Up, Up, Right Up)
        case 3:
        {
            return vec2(float(randomVector.x > 0.333) - 2. * float(randomVector.x > 0.666),
                        sign(randomVector.y * 2. - 1.) * float(randomVector.y < 0.666 || randomVector.x < 0.333));
        }
        break;
    }
}

//Vector Lookup Table for 3D Noises
vec3 vectorTable3D[] = vec3[] (vec3(1., 1., 0.), vec3(- 1., 1., 0.), vec3(1., - 1., 0.), vec3(- 1., - 1., 0.), 
                               vec3(1., 0., 1.), vec3(- 1., 0., 1.), vec3(1., 0., - 1.), vec3(- 1., 0., - 1.),
                               vec3(0., 1., 1.), vec3(0., - 1., 1.), vec3(0., 1., - 1.), vec3(0., - 1., - 1.));

//NOISES//
//Value Noise
float valueNoise(vec2 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec2 pixelPosition = fract(uv * frequency);
        vec2 cellPosition = floor(uv * frequency);

        //Get the Value of the 4 Nearest Grid Points
        float point1 = randomValue(cellPosition) * 2. - 1.0;
        float point2 = randomValue(vec2(cellPosition.x + 1., cellPosition.y)) * 2. - 1.0;
        float point3 = randomValue(vec2(cellPosition.x, cellPosition.y + 1.)) * 2. - 1.0;
        float point4 = randomValue(vec2(cellPosition.x + 1., cellPosition.y + 1.)) * 2. - 1.0;

        //Smooth the Pixel's Coordinates for the Interpolation Using the Smootherstep Function
        vec2 pixelPositionSmoothed = vec2(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y));

        //Interpolate Between the Grid Point Values
        float interpolation1 = mix(point1, point2, pixelPositionSmoothed.x);
        float interpolation2 = mix(point3, point4, pixelPositionSmoothed.x);
        float interpolation3 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        
        //Add the Current Octave's Value to the Final Value
        pixelValue += ((interpolation3 + 1.) / 2.) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//3D Value Noise
float valueNoise3D(vec3 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec3 pixelPosition = fract(uv * frequency);
        vec3 cellPosition = floor(uv * frequency);

        //Get the Value of the 8 Nearest Grid Points
        float point1 = randomValue(cellPosition.xy * randomValue(vec2(cellPosition.z))) * 2. - 1.0;
        float point2 = randomValue(vec2(cellPosition.x + 1., cellPosition.y) * randomValue(vec2(cellPosition.z))) * 2. - 1.0;
        float point3 = randomValue(vec2(cellPosition.x, cellPosition.y + 1.) * randomValue(vec2(cellPosition.z))) * 2. - 1.0;
        float point4 = randomValue(vec2(cellPosition.x + 1., cellPosition.y + 1.) * randomValue(vec2(cellPosition.z))) * 2. - 1.0;
        float point5 = randomValue(cellPosition.xy * randomValue(vec2(cellPosition.z + 1.))) * 2. - 1.0;
        float point6 = randomValue(vec2(cellPosition.x + 1., cellPosition.y) * randomValue(vec2(cellPosition.z + 1.))) * 2. - 1.0;
        float point7 = randomValue(vec2(cellPosition.x, cellPosition.y + 1.) * randomValue(vec2(cellPosition.z + 1.))) * 2. - 1.0;
        float point8 = randomValue(vec2(cellPosition.x + 1., cellPosition.y + 1.) * randomValue(vec2(cellPosition.z + 1.))) * 2. - 1.0;
        
        //Smooth the Pixel's Coordinates for the Interpolation Using the Smootherstep Function
        vec3 pixelPositionSmoothed = vec3(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y), smootherstep(pixelPosition.z));

        //Interpolate Between the Grid Point Values
        float interpolation1 = mix(point1, point2, pixelPositionSmoothed.x);
        float interpolation2 = mix(point3, point4, pixelPositionSmoothed.x);
        float interpolation3 = mix(point5, point6, pixelPositionSmoothed.x);
        float interpolation4 = mix(point7, point8, pixelPositionSmoothed.x);
        
        float interpolation5 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        float interpolation6 = mix(interpolation3, interpolation4, pixelPositionSmoothed.y);
        
        float interpolation7 = mix(interpolation5, interpolation6, pixelPositionSmoothed.z);
        
        //Add the Current Octave's Value to the Final Value
        pixelValue += ((interpolation7 + 1.) / 2.) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//Perlin Noise
float perlinNoise(vec2 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec2 pixelPosition = fract(uv * frequency);
        vec2 cellPosition = floor(uv * frequency);
        
        //Get the Gradient Vector of the 4 Nearest Grid Points
        vec2 gradientVector1 = randomLimitedVector(cellPosition, vectorSet);
        vec2 gradientVector2 = randomLimitedVector(vec2(cellPosition.x + 1., cellPosition.y), vectorSet);
        vec2 gradientVector3 = randomLimitedVector(vec2(cellPosition.x, cellPosition.y + 1.), vectorSet);
        vec2 gradientVector4 = randomLimitedVector(vec2(cellPosition.x + 1., cellPosition.y + 1.), vectorSet);
        
        //Calculate the Distance Vector from the Pixel to the Grid Points
        vec2 distanceVector1 = vec2(pixelPosition.x, - pixelPosition.y);
        vec2 distanceVector2 = vec2(- (1. - pixelPosition.x), - pixelPosition.y);
        vec2 distanceVector3 = vec2(pixelPosition.x, 1. - pixelPosition.y);
        vec2 distanceVector4 = vec2(- (1. - pixelPosition.x), 1. - pixelPosition.y);
        
        //Calculate the Dot Products of the Gradient && Distance Vectors
        float dotProduct1 = dot(gradientVector1, distanceVector1);
        float dotProduct2 = dot(gradientVector2, distanceVector2);
        float dotProduct3 = dot(gradientVector3, distanceVector3);
        float dotProduct4 = dot(gradientVector4, distanceVector4);
        
        //Smooth the Pixel's Coordinates for the Interpolation Using the Smootherstep Function
        vec2 pixelPositionSmoothed = vec2(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y));
        
        //Interpolate Between the Grid Point Values
        float interpolation1 = mix(dotProduct1, dotProduct2, pixelPositionSmoothed.x);
        float interpolation2 = mix(dotProduct3, dotProduct4, pixelPositionSmoothed.x);
        float interpolation3 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        
        //Add the Current Octave's Value to the Final Value
        pixelValue += ((interpolation3 + 1.) / 2.) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//3D Perlin Noise
float perlinNoise3D(vec3 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec3 pixelPosition = fract(uv * frequency);
        vec3 cellPosition = floor(uv * frequency);
        
        //Get the Gradient Vector of the 8 Nearest Grid Points
        vec3 gradientVector1 = vectorTable3D[int(ceil(randomVector(cellPosition.xy * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector2 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y) * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector3 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x, cellPosition.y + 1.) * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector4 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y + 1.) * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector5 = vectorTable3D[int(ceil(randomVector(cellPosition.xy * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        vec3 gradientVector6 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y) * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        vec3 gradientVector7 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x, cellPosition.y + 1.) * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        vec3 gradientVector8 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y + 1.) * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        
        //Calculate the Distance Vector from the Pixel to the Grid Points
        vec3 distanceVector1 = vec3(pixelPosition.x, - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector2 = vec3(- (1. - pixelPosition.x), - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector3 = vec3(pixelPosition.x, 1. - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector4 = vec3(- (1. - pixelPosition.x), 1. - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector5 = vec3(pixelPosition.x, - pixelPosition.y, - (1. - pixelPosition.z));
        vec3 distanceVector6 = vec3(- (1. - pixelPosition.x), - pixelPosition.y, - (1. - pixelPosition.z));
        vec3 distanceVector7 = vec3(pixelPosition.x, 1. - pixelPosition.y, - (1. - pixelPosition.z));
        vec3 distanceVector8 = vec3(- (1. - pixelPosition.x), 1. - pixelPosition.y, - (1. - pixelPosition.z));
        
        //Calculate the Dot Products of the Gradient && Distance Vectors
        float dotProduct1 = dot(gradientVector1, distanceVector1);
        float dotProduct2 = dot(gradientVector2, distanceVector2);
        float dotProduct3 = dot(gradientVector3, distanceVector3);
        float dotProduct4 = dot(gradientVector4, distanceVector4);
        float dotProduct5 = dot(gradientVector5, distanceVector5);
        float dotProduct6 = dot(gradientVector6, distanceVector6);
        float dotProduct7 = dot(gradientVector7, distanceVector7);
        float dotProduct8 = dot(gradientVector8, distanceVector8);
        
        //Smooth the Pixel's Coordinates for the Interpolation Using the Smootherstep Function
        vec3 pixelPositionSmoothed = vec3(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y), smootherstep(pixelPosition.z));
        
        //Interpolate Between the Grid Point Values
        float interpolation1 = mix(dotProduct1, dotProduct2, pixelPositionSmoothed.x);
        float interpolation2 = mix(dotProduct3, dotProduct4, pixelPositionSmoothed.x);
        float interpolation3 = mix(dotProduct5, dotProduct6, pixelPositionSmoothed.x);
        float interpolation4 = mix(dotProduct7, dotProduct8, pixelPositionSmoothed.x);
        
        float interpolation5 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        float interpolation6 = mix(interpolation3, interpolation4, pixelPositionSmoothed.y);
        
        float interpolation7 = mix(interpolation5, interpolation6, pixelPositionSmoothed.z);
        
        //Add the Current Octave's Value to the Final Value
        pixelValue += ((interpolation7 + 1.) / 2.) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//Spaghetti Noise
float spaghettiNoise(vec2 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec2 pixelPosition = fract(uv * frequency);
        vec2 cellPosition = floor(uv * frequency);

        //Get the Gradient Vector of the 4 Nearest Grid Points
        vec2 gradientVector1 = randomLimitedVector(cellPosition, vectorSet);
        vec2 gradientVector2 = randomLimitedVector(vec2(cellPosition.x + 1., cellPosition.y), vectorSet);
        vec2 gradientVector3 = randomLimitedVector(vec2(cellPosition.x, cellPosition.y + 1.), vectorSet);
        vec2 gradientVector4 = randomLimitedVector(vec2(cellPosition.x + 1., cellPosition.y + 1.), vectorSet);
        
        //Calculate the Distance Vector from the Pixel to the Grid Points
        vec2 distanceVector1 = vec2(pixelPosition.x, - pixelPosition.y);
        vec2 distanceVector2 = vec2(- (1. - pixelPosition.x), - pixelPosition.y);
        vec2 distanceVector3 = vec2(pixelPosition.x, 1. - pixelPosition.y);
        vec2 distanceVector4 = vec2(- (1. - pixelPosition.x), 1. - pixelPosition.y);
        
        //Calculate the Dot Products of the Gradient && Distance Vectors
        float dotProduct1 = dot(gradientVector1, distanceVector1);
        float dotProduct2 = dot(gradientVector2, distanceVector2);
        float dotProduct3 = dot(gradientVector3, distanceVector3);
        float dotProduct4 = dot(gradientVector4, distanceVector4);

        //Smooth the Pixel's Coordinates for the Interpolation Using the Smootherstep Function
        vec2 pixelPositionSmoothed = vec2(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y));

        //Interpolate Between the Grid Point Values
        float interpolation1 = mix(dotProduct1, dotProduct2, pixelPositionSmoothed.x);
        float interpolation2 = mix(dotProduct3, dotProduct4, pixelPositionSmoothed.x);
        float interpolation3 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        
        //Add the Current Octave's Value to the Final Value
        pixelValue += abs(interpolation3) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//3D Spaghetti Noise
float spaghettiNoise3D(vec3 uv, float frequency, int octaves, float lacunarity, float persistence)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec3 pixelPosition = fract(uv * frequency);
        vec3 cellPosition = floor(uv * frequency);
        
        //Get the Gradient Vector of the 8 Nearest Grid Points
        vec3 gradientVector1 = vectorTable3D[int(ceil(randomVector(cellPosition.xy * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector2 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y) * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector3 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x, cellPosition.y + 1.) * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector4 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y + 1.) * randomValue(vec2(cellPosition.z))) * 11.))];
        vec3 gradientVector5 = vectorTable3D[int(ceil(randomVector(cellPosition.xy * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        vec3 gradientVector6 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y) * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        vec3 gradientVector7 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x, cellPosition.y + 1.) * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        vec3 gradientVector8 = vectorTable3D[int(ceil(randomVector(vec2(cellPosition.x + 1., cellPosition.y + 1.) * randomValue(vec2(cellPosition.z + 1.))) * 11.))];
        
        //Calculate the Distance Vector from the Pixel to the Grid Points
        vec3 distanceVector1 = vec3(pixelPosition.x, - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector2 = vec3(- (1. - pixelPosition.x), - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector3 = vec3(pixelPosition.x, 1. - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector4 = vec3(- (1. - pixelPosition.x), 1. - pixelPosition.y, pixelPosition.z);
        vec3 distanceVector5 = vec3(pixelPosition.x, - pixelPosition.y, - (1. - pixelPosition.z));
        vec3 distanceVector6 = vec3(- (1. - pixelPosition.x), - pixelPosition.y, - (1. - pixelPosition.z));
        vec3 distanceVector7 = vec3(pixelPosition.x, 1. - pixelPosition.y, - (1. - pixelPosition.z));
        vec3 distanceVector8 = vec3(- (1. - pixelPosition.x), 1. - pixelPosition.y, - (1. - pixelPosition.z));
        
        //Calculate the Dot Products of the Gradient && Distance Vectors
        float dotProduct1 = dot(gradientVector1, distanceVector1);
        float dotProduct2 = dot(gradientVector2, distanceVector2);
        float dotProduct3 = dot(gradientVector3, distanceVector3);
        float dotProduct4 = dot(gradientVector4, distanceVector4);
        float dotProduct5 = dot(gradientVector5, distanceVector5);
        float dotProduct6 = dot(gradientVector6, distanceVector6);
        float dotProduct7 = dot(gradientVector7, distanceVector7);
        float dotProduct8 = dot(gradientVector8, distanceVector8);
        
        //Smooth the Pixel's Coordinates for the Interpolation Using the Smootherstep Function
        vec3 pixelPositionSmoothed = vec3(smootherstep(pixelPosition.x), smootherstep(pixelPosition.y), smootherstep(pixelPosition.z));
        
        //Interpolate Between the Grid Point Values
        float interpolation1 = mix(dotProduct1, dotProduct2, pixelPositionSmoothed.x);
        float interpolation2 = mix(dotProduct3, dotProduct4, pixelPositionSmoothed.x);
        float interpolation3 = mix(dotProduct5, dotProduct6, pixelPositionSmoothed.x);
        float interpolation4 = mix(dotProduct7, dotProduct8, pixelPositionSmoothed.x);
        
        float interpolation5 = mix(interpolation1, interpolation2, pixelPositionSmoothed.y);
        float interpolation6 = mix(interpolation3, interpolation4, pixelPositionSmoothed.y);
        
        float interpolation7 = mix(interpolation5, interpolation6, pixelPositionSmoothed.z);
        
        //Add the Current Octave's Value to the Final Value
        pixelValue += abs(interpolation7) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

//Worley Noise
float worleyNoise(vec2 uv, float frequency, int octaves, float lacunarity, float persistence, int nNearest)
{
    float pixelValue = 0.;
    float maxValue = 0.;    //used to normalize the final value
    float amplitude = 1.;
    for (int octave = 0; octave < octaves; octave ++)
    {
        //Get the Pixel's Position Within Its Grid Cell && the Cell's Position 
        vec2 pixelPosition = fract(uv * frequency);
        vec2 cellPosition = floor(uv * frequency);

        //Get the n-Nearest Cell Point Position
        float distances[9] = float[] (5., 5., 5., 5., 5., 5., 5., 5., 5.);
        for (int i = - 1; i < 2; i ++)
        {
            for (int j = - 1; j < 2; j ++)
            {
                //Get the Point Position Within Its Grid Cell
                vec2 pointPosition = randomVector(vec2(cellPosition.x + float(j), cellPosition.y + float(i)));
                pointPosition *= (sin(time * noiseSpeed * 5. + pointPosition.x * 20.) + 1.) * 0.5 * float(motion) + float(!motion);    //noise motion
                pointPosition += vec2(j, i);
                
                //Compare the Distance Between the Pixel && the Point with the Previous Distances
                float distanceToCompare = distance(pixelPosition, pointPosition);
                for (int k = 0; k < distances.length(); k ++)
                {
                    if (distanceToCompare < distances[k])
                    {
                        float tempDistance = distances[k];
                        distances[k] = distanceToCompare;
                        distanceToCompare = tempDistance;
                    }
                }
            }
        }
        pixelValue += distances[nNearest - 1] * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return pixelValue / maxValue;
}

void main(void)
{
    //Remap the Fragcoord
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float aspectRatio = resolution.y / resolution.x;
    uv.x /= aspectRatio;
    
    //Set the Time for Changing the z Noise Component
    float time2 = mod(time, 200.) + 1.;    //the RNGs aren't functioning well on higher numbers ¯\_(ツ)_/¯
    
    //Get the Noise Value && Set the Fragcolor
    float noiseValue;
    switch (noiseType)
    {
        case 0:
        {
            if (dimension == 0) noiseValue = valueNoise(uv, frequency, octaves, lacunarity, persistence);
            if (dimension == 1) noiseValue = valueNoise3D(vec3(uv, noiseSpeed * time2), frequency, octaves, lacunarity, persistence);
        }
        break;
        
        case 1:
        {
            if (dimension == 0) noiseValue = perlinNoise(uv, frequency, octaves, lacunarity, persistence);
            if (dimension == 1) noiseValue = perlinNoise3D(vec3(uv, noiseSpeed * time2), frequency, octaves, lacunarity, persistence);
        }
        break;
        
        case 2:
        {
            if (dimension == 0) noiseValue = spaghettiNoise(uv, frequency, octaves, lacunarity, persistence);
            if (dimension == 1) noiseValue = spaghettiNoise3D(vec3(uv, noiseSpeed * time2), frequency, octaves, lacunarity, persistence);
        }
        break;
        
        case 3:
        {
            noiseValue = worleyNoise(uv, frequency, octaves, lacunarity, persistence, nNearest);
        }
        break;
    }
    
    if (combineNoises)
    {
        noiseValue *= perlinNoise3D(vec3(uv, noiseSpeed * time2), 20., 6, lacunarity, persistence) * 1.;    //combine multiple noises
        noiseValue += worleyNoise(uv, 5., 1, lacunarity, persistence, 1) * 1.;
    }
    
    noiseValue = map(noiseValue, 0., 1., mapMin, mapMax) * float(!mapChange) +    //normal
                 map(noiseValue, 0., 1., (sin(time2) + 1.) * 0.5, 1. - (sin(time2) + 1.) * 0.5) * float(mapChange);    //changing
    
    glFragColor = vec4(mix(colourMin, colourMax, clamp(noiseValue, - 0.5, 1.)), 2.);
}
