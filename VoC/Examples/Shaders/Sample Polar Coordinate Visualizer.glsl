#version 420

// original https://www.shadertoy.com/view/Xtfczr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float     PI = 3.1415;
const float     ROT = 6.2830; // Double PI
const float     LINE_WIDTH = 0.01;
const float     FALLOFF = 0.8;

// Polar Coordinates stored as vec2(radius, angle)

//-----------------------------------------------------------
//    Helper functions
//-------------------------

// Convert a cartesian coord to a polar coord
vec2 CartesianToPolar(vec2 cart)
{
    return vec2(length(cart), atan(cart.y, cart.x));
}

// Convert RGB values into their float representation
vec3 RGB(float r, float g, float b)
{
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}

//-----------------------------------------------------------
//    Polar equation functions
//-------------------------

const int numEquations = 4;
const float lifeCycleSum = 29.0;
float solveEquation(int polarIndex, float angle)
{   
    if(mod(float(polarIndex), 2.0) == 1.0)
        angle += mod(time, lifeCycleSum) * 0.5;
    else
        angle -= mod(time, lifeCycleSum) * 0.5;
    
    if(polarIndex == 1)
        return (2.0 + pow(sin(2.4 * angle), 3.0)) / 3.0;
    if(polarIndex == 2)
        return sin(8.0 * angle / 5.0);
    if(polarIndex == 3)
        return pow(sin(2.5 * angle), 3.0) + pow(cos(2.5 * angle), 3.0);
    if(polarIndex == 4)
        return (1.0 - cos(4.0 * angle / 5.0) * sin(7.0 * angle / 5.0)) / 2.0;      
}
// Each equation takes lifeCycle + 3 seconds
// 1 for pausing after drawing
// 1 for fading into the background
// 1 for pausing before the next equation starts drawing
float getLifeCycle(int polarIndex)
{
    if(polarIndex == 1)
        return 5.0;
    if(polarIndex == 2)
        return 5.0;
    if(polarIndex == 3)
        return 2.0;
    if(polarIndex == 4)
        return 5.0;
}
float getEquationStart(int polarIndex)
{
    if(polarIndex == 1)
        return 0.0;
    if(polarIndex == 2)
        return 8.0;
    if(polarIndex == 3)
        return 16.0;
    if(polarIndex == 4)
        return 21.0;
}
int getCurrentEquation(float time)
{
    if(time < 8.0)
        return 1;
    if(time < 16.0)
        return 2;
    if(time < 21.0)
        return 3;
    if(time < 29.0)
        return 4;
}
bool useExponentialWidth(int polarIndex)
{
    if(polarIndex == 1)
        return false;
    if(polarIndex == 2)
        return true;
    if(polarIndex == 3)
        return true;
    if(polarIndex == 4)
        return false;
}

vec4 getEquationColor(int polarIndex)
{
    if(mod(float(polarIndex), 2.0) == 0.0)
    {
        return vec4(0.0 ,0.0, 0.0, 1.0);
    }
    else
    {
        return vec4(1.0 ,1.0, 1.0, 1.0);
    }
}

vec4 liesOnCurrentPolar(int polarIndex, vec2 point, float drawTime)
{
    float fillTime = 0.0;
    if(drawTime > getLifeCycle(polarIndex) + 1.0)
    {
        fillTime = drawTime - (getLifeCycle(polarIndex) + 1.0);
    }

    float dist = 99999.0;
    float angle = point.y;
    float angleCap;
    float angleFloor = -PI;
        
    for (int i = 0; i <= int(getLifeCycle(polarIndex)); i++) 
    {
        // Determine how many rotations we've already drawn
        angleCap = ROT * float(int(drawTime)) - PI;
        
        // Determine how much to draw in our current rotation
        angleCap += mod(drawTime, 1.0) * ROT;
        
        // Polar coordinates can be represented in two different ways, 
        // At an angle with a positive radius, or the 180 degress away with a negative radius.
        // This section accounts for both scenarios.
        angle -= PI;
        if(i == 0 && angle > angleFloor && angle < angleCap)
        {
            dist = min(dist, abs(point.x - (-1.0 * solveEquation(polarIndex, angle))));
        }
        angle += PI;
        if(angle < angleCap)
        {
            dist = min(dist, abs(point.x - solveEquation(polarIndex, angle)));
            if(angle < angleFloor + 0.1)
            {
                dist *= pow(0.1 / (angle - angleFloor), 0.5);
            }
        }
        angle += PI;
        if(angle < angleCap)
        {
            dist = min(dist, abs(point.x - (-1.0 * solveEquation(polarIndex, angle))));
        }
        angle += PI;
        angleCap += ROT;
    }
    
    float mult = (point.x > 1.0 || !useExponentialWidth(polarIndex)) ? 1.0 : 1.0 / point.x;
    float lineDist = (LINE_WIDTH + fillTime) * mult;

    if(dist < lineDist)
    {
        return getEquationColor(polarIndex);
    }
    else
    {
        vec4 outline = getEquationColor(polarIndex);
        outline.a = pow((lineDist / dist), FALLOFF);
        return outline;
    }
}

vec4 getBackground(int polarIndex)
{
    if(polarIndex == 1)
    {
        return getEquationColor(numEquations);
    }
    else
    {
        return getEquationColor(polarIndex - 1);
    }
}

void main(void)
{
    float x = 2.0 * (gl_FragCoord.x - resolution.x / 2.0) / resolution.y;
    float y = 2.0 * (gl_FragCoord.y - resolution.y / 2.0) / resolution.y;
    vec2 uv = vec2(x, y);
    
    int equation = getCurrentEquation(mod(time, lifeCycleSum));
    float lifeCycle = mod(time, lifeCycleSum) - getEquationStart(equation);

    // Background layer
    vec4 layer1 = getBackground(equation);
    vec4 layer2 = liesOnCurrentPolar(equation, CartesianToPolar(uv), lifeCycle);
    
    // Blend the two
    glFragColor = mix(layer1, layer2, layer2.a);
}
