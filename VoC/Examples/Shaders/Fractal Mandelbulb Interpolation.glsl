#version 420

// original https://www.shadertoy.com/view/4tdyDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CONSTANTS
//
const int MAX_MARCHING_STEPS = 400;
const float MIN_DIST = 0.0;
const float MAX_DIST = 50.0;
const float EPSILON = 0.005;
//const float Power = 4.0;
const float Bailout = 2.0;
int MAX_ITERATIONS = 10;
float SCALE = 2.0;

// HERE WE DEFINE CAMERA PROPERTIES
//
float camFOV = 45.0;
vec3 cameraPos = vec3(0.0, 0.0, -5.5);
mat3x3 camMatrix = mat3x3(
    vec3(1.0, 0.0, 0.0), // right vec
    vec3(0.0, 1.0, 0.0), // up vec
    vec3(0.0, 0.0, 1.0) // forward vec
);

// TRANSFORM A SCREEN PIXEL IN A VECTOR IN THE WORLD
//
vec3 ScreenPointToWorld (vec2 screenPoint) // Don't consider camera position, it needs to be added if needed
{
    vec2 xyWorld = screenPoint - resolution.xy / 2.0;
    float zWorld = abs(resolution.x / 2.0) / tan(radians(camFOV / 2.0));
    
    return normalize(camMatrix * vec3(xyWorld, zWorld));
}

// VOLUME DISTANCE FUNCTION
//
float Distance (vec3 pos)
{
    float Power = 8.0;// mix(6.0, 9.0, (sin(time) + 1.0) / 2.0);
    
    mat3x3 rotMatrix = mat3x3(
        vec3(cos(time * 0.5), -sin(time * 0.5), 0.0),
        vec3(sin(time * 0.5), cos(time * 0.5), 0.0),
        vec3(0.0, 0.0, 1.0)
    );
    
    mat3x3 rotMatrix2 = mat3x3(
        vec3(cos(time * 0.5), 0.0, -sin(time * 0.5)),
        vec3(0.0, 1.0, 0.0),
        vec3(sin(time * 0.5), 0.0, cos(time * 0.5))
    );
    
    mat3x3 rotMatrix3 = mat3x3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, cos(time * 0.5), -sin(time * 0.5)),
        vec3(0.0, sin(time * 0.5), cos(time * 0.5))
    );
    
    vec3 z = rotMatrix * rotMatrix2 * rotMatrix3 * (pos + vec3(0.0, 0.0, 1.0));
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < MAX_ITERATIONS ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}

// SURFACE NORMAL
//
vec3 Normals(vec3 p)
{
    return normalize(vec3(
        Distance(vec3(p.x + EPSILON, p.y, p.z)) - Distance(vec3(p.x - EPSILON, p.y, p.z)),
        Distance(vec3(p.x, p.y + EPSILON, p.z)) - Distance(vec3(p.x, p.y - EPSILON, p.z)),
        Distance(vec3(p.x, p.y, p.z + EPSILON)) - Distance(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

// RETURNS THE DISTANCE FROM THE CAMERA OF THE CLOSEST POINT TO THE SURFACE
//
float RayMarchingClosestPoint(vec3 camPos, vec3 lookDir, float start, float end)
{
    float depth = start;
    for(int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float distToSurface = Distance(camPos + lookDir * depth);
        if(distToSurface < EPSILON)
        {
            return depth;
        }
        depth += distToSurface;
        if(depth >= end)
        {
            return end;    
        }
    }
    return end;
}

// CONTRIBUTION FOR EACH LIGHT USING PHONG
//
vec3 LightContribution(
    vec3 diffuseColor, 
    vec3 specularColor, 
    vec3 ambientColor,
    float glossiness,
    vec3 normal,
    vec3 viewDir,
    vec3 surfacePos,
    vec3 lightColor,
    float lightIntensity,
    vec3 lightPos
)
{
    vec3 N = normal;
    vec3 V = -viewDir;
    vec3 L = normalize(lightPos - surfacePos);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = max(0.0, dot(L, N));
    float dotRV = max(0.0, dot(R, V));
    float dotVN = 1.0 - max(0.0, dot(V, N));
    
    return 
        (lightIntensity * lightColor *
            (dotLN * diffuseColor
             + (1.0 - mix(0.1, 1.0, dotVN * dotVN)) * specularColor * pow(dotRV, glossiness)
             //+ texture(iChannel0, R).rgb * dotVN * dotVN * 0.3)
             + vec3(1.0) * dotVN * dotVN * 0.3)
        );
}

// MAIN
//
void main(void)
{
    vec3 viewDir = ScreenPointToWorld (gl_FragCoord.xy);
    float dist = RayMarchingClosestPoint(cameraPos, viewDir, MIN_DIST, MAX_DIST);
    
    vec3 col = mix(vec3(0.02), vec3(0.2, 0.16, 0.1), pow(dot(viewDir, vec3(0.0, 0.0, 1.0)), 30.0));
    
    if(dist <= MAX_DIST - EPSILON)
    {
        vec3 surfPos = cameraPos + viewDir * dist;
        vec3 surfNormals = Normals(surfPos);
        
        col = LightContribution(
            vec3(0.05, 0.05, 0.015), //vec3 diffuseColor, 
            vec3(0.99, 0.65, 0.34), //vec3 specularColor, 
            vec3(0.05, 0.05, 0.05), //vec3 ambientColor,
            15.0, //float glossiness,
            surfNormals, //vec3 normal,
            viewDir, //vec3 viewDir,
            surfPos, //vec3 surfacePos,
            vec3(1.0, 1.0, 1.0), //vec3 lightColor,
            3.0, //float lightIntensity,
            vec3(5.0, 5.0, -5.0) //vec3 lightPos
        );
    }

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
