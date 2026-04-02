#version 420

// original https://www.shadertoy.com/view/3sSczR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float EPSILON = 0.001;
const float PI = 3.141592;
const float MAX_DIST = 256.0;
const int MAX_STEPS = 256;
const int it = 10;

vec3 makeRay(vec2 origin)
{
    //Making a ray by pixel coords
    float x = origin.x - resolution.x * 0.5;
    x = x * (resolution.x / resolution.y) / resolution.x;
    float y = origin.y - resolution.y * 0.5;
    y = y / resolution.y;
    
    return normalize(vec3(x, y, 1));
}

mat2 rot(float ang)
{
    //Rotation matrix
    float s = sin(ang);
    float c = cos(ang);
    return mat2(c, -s, s, c);
}

vec3 rotVec(vec3 p, vec3 r)
{
    //Rotating a vector
    p.yz *= rot(r.x);
    p.xz *= rot(r.y);
    p.xy *= rot(r.z);
    return p;
}

float mandelBulb(vec3 p, vec3 fp, float power, vec3 ang)
{
    //Translation and rotation of fractal
    p -= fp;
    p = rotVec(p, ang);
    
    //I don't want to comment it
    vec3 z = p;
    float r, theta, phi;
    float dr = 1.0;
    
    for(int i = 0; i < it; ++i)
    {
        r = length(z);
        
        if(r > 2.0)
            continue;
        
        theta = atan(z.y / z.x);
        phi = asin(z.z / r) + time;
        
        dr = pow(r, power - 1.0) * dr * power + 1.0;
        r = pow(r, power);
        
        theta = theta * power;
        phi = phi * power;
        
        z = r * vec3(cos(theta) * cos(phi),
                     sin(theta) * cos(phi), 
                     sin(phi)) + p;
    }
    
    return 0.5 * log(r) * r / dr;
}

float getDist(vec3 origin)
{
    //Setup position rotation and power of fractal
    vec3 fp = vec3(0);
    vec3 fr = vec3(0, PI + PI / 4.0, 0);
    float power = 8.0;
    
    return mandelBulb(origin, fp, power, fr);
}

vec2 rayMarch(vec3 origin, vec3 direct)
{
    //Raymarching function
    float res = 0.0;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        vec3 tmp = origin + direct * res;
        float d = getDist(tmp);
        res += d;
        
        if (res >= MAX_DIST || abs(d) < EPSILON)
            return vec2(res, float(i));
    }

    return vec2(res, float(MAX_STEPS));
}

void main(void)
{
    //Setupt the camera
    vec3 origin = vec3(0, 0, -3);
    vec3 dir = makeRay(gl_FragCoord.xy);
    
    //Raymarching
    vec2 res = rayMarch(origin, dir);
    float d = res.x;
    vec3 col = vec3(0);
    
    //Check if the ray hits the fractal
    if (d < MAX_DIST)
    {
        //Calculating the point of gradient
        vec3 p = origin + d * dir;
        float delta = length(p) / 2.0;
        
        //Making gradient and dynamic colors
        vec3 startCol = vec3(cos(time) * 0.25 + 0.75, 0, 0);
        vec3 finCol = vec3(0, 0, sin(time) * 0.25 + 0.75);
        col = mix(startCol, finCol, delta);
        
        //Glow eefect
        //It works like ambient occlusion but backwards
        col *= res.y / float(MAX_STEPS) * 5.0;
    }
    
    glFragColor = vec4(col, 1);
}
