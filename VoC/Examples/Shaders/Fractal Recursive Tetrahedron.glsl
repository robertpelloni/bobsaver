#version 420

// original https://www.shadertoy.com/view/MdyBDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CONSTANTS
//
const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.01;
int MAX_ITERATIONS = 10;
float SCALE = 2.0;

// HERE WE DEFINE CAMERA PROPERTIES
//
float camFOV = 45.0;
vec3 cameraPos = vec3(0.0, 0.0, -6.0);
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

// RECURSIVE TETRAHEDRON
//
float DistTetrahedron (vec3 p)
{
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
    
    vec3 v1 = rotMatrix * rotMatrix2 * vec3(1.0, 1.0, 1.0);
    vec3 v2 = rotMatrix * rotMatrix2 * vec3(-1.0, 1.0, -1.0);
    vec3 v3 = rotMatrix * rotMatrix2 * vec3(1.0, -1.0, -1.0);
    vec3 v4 = rotMatrix * rotMatrix2 * vec3(-1.0, -1.0, 1.0);
    
    vec3 c;
    int counter = 0;
    
    float distToVertex, d;
    while(counter < MAX_ITERATIONS)
    {
        c = v1;
        distToVertex = length(p - v1);
        
        d = length(p - v2); if(d < distToVertex) {c = v2; distToVertex = d;} 
        d = length(p - v3); if(d < distToVertex) {c = v3; distToVertex = d;} 
        d = length(p - v4); if(d < distToVertex) {c = v4; distToVertex = d;} 
        
        p = SCALE * p - c * (SCALE - 1.0);
        counter++;
    }
    
    return length(p) * pow(SCALE, float(-counter));
}

// SURFACE NORMAL
//
vec3 GetTetrahedronNormals(vec3 p)
{
    return normalize(vec3(
        DistTetrahedron(vec3(p.x + EPSILON, p.y, p.z)) - DistTetrahedron(vec3(p.x - EPSILON, p.y, p.z)),
        DistTetrahedron(vec3(p.x, p.y + EPSILON, p.z)) - DistTetrahedron(vec3(p.x, p.y - EPSILON, p.z)),
        DistTetrahedron(vec3(p.x, p.y, p.z + EPSILON)) - DistTetrahedron(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

// RETURNS THE DISTANCE FROM THE CAMERA OF THE CLOSEST POINT TO THE SURFACE
//
float RayMarchingClosestPoint(vec3 camPos, vec3 lookDir, float start, float end)
{
    float depth = start;
    for(int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float distToSurface = DistTetrahedron(camPos + lookDir * depth);
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
    float dotVN = max(0.0, dot(V, N));
    
    return 
        (lightIntensity * lightColor * 
            (dotLN * diffuseColor
             + (1.0 - mix(0.1, 1.0, dotVN * dotVN)) * specularColor * pow(dotRV, glossiness)
             + ambientColor)
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
        vec3 surfNormals = GetTetrahedronNormals(surfPos);
        
        col = LightContribution(
            vec3(0.1, 0.1, 0.03), //vec3 diffuseColor, 
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
        //col = vec3(1.0);
    }

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
