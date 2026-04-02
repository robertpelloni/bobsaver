#version 420

// original https://www.shadertoy.com/view/tdsyzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_RAY_STEPS 100
#define RAY_HIT_DIST 0.001

vec3 lightDir = normalize(vec3(-1.0, -1.0, -0.6));

vec3 greenBodyColor = vec3(0.0, 0.55, 0.0);
vec3 brightGreenBodyColor = vec3(0.0, 0.65, 0.0);
vec3 darkGreenSpotColor = vec3(0.0, 0.45, 0.0);
vec3 yellowEyesColor = vec3(0.95, 0.95, 0.85);
vec3 yellowTeethColor = vec3(0.95, 0.95, 0.85)*0.9;
vec3 whiteBlueEyebrowColor = vec3(0.90, 0.99, 0.90);
vec3 blackMouthColor = vec3(0.2, 0.2, 0.2);

// valuateType = 0: min(d1, d2)        "normal" sdf
// valuateType = 1: max(-d1, d2)    "carve" out shapes
void ValuateSDF(inout vec4 currDist, float sdf, vec3 color, int valuateType)
{
    float tempDist;
    
    if(valuateType == 0)
        tempDist = min(sdf, currDist.x);
    else if(valuateType == 1)
        tempDist = max(-sdf, currDist.x);
    
    // TempDist is a better sdf
    if(tempDist != currDist.x)
        currDist = vec4(tempDist, color);
}

void SDFDeformedCapsule(inout vec4 currDist, vec3 p, vec3 p1, vec3 p2, float radius, vec3 color, int valuateType)
{
    // Curve the "spine" a bit
    p.z += (0.6 - p.y*p.y)*0.1;
    
    vec3 line = p1 - p2;
    vec3 pointDir = p - p2;
    
    // Project p onto the line
    float t = dot(pointDir, line) / dot(line, line);
    t = clamp(t, 0.0, 1.0);
    
    vec3 tempPoint = p2 + line*t;
    
    // Distort the sdf, based on the current point's y-position
    float sdf = (length(p - tempPoint) - radius) + 
        sin(p.y*7.0) * 0.005 + 
        cos(p.y*20.0 + 63.01) * 0.001;
    
    ValuateSDF(currDist, sdf, color, valuateType);
}

void SDFCapsule(inout vec4 currDist, vec3 p, vec3 p1, vec3 p2, float radius, vec3 color, int valuateType)
{
    vec3 line = p1 - p2;
    vec3 pointDir = p - p2;
    
    // Project p onto the line
    float t = dot(pointDir, line) / dot(line, line);
    t = clamp(t, 0.0, 1.0);
    
    vec3 tempPoint = p2 + line*t;
    
    float sdf = (length(p - tempPoint) - radius);
    
    ValuateSDF(currDist, sdf, color, valuateType);
}

void SDFSphere(inout vec4 currDist, vec3 p, vec3 pos, float radius, vec3 color, int valuateType)
{
    float sdf = length(p - pos) - radius;
    
    ValuateSDF(currDist, sdf, color, valuateType);
}

vec4 Map(vec3 p)
{
    // currDist.x = sdf
    // currDist.yzw = color
    vec4 currDist = vec4(999.0, vec3(0.0));
    
    vec3 originalP = p;
    
    // Body
    SDFDeformedCapsule(currDist, p, vec3(0.0, 0.45, 0.0), vec3(0.0, -0.65, 0.0), 0.3, greenBodyColor, 0);
    
    // Eyes
    p.x = abs(p.x);
    float r = 0.08;
    SDFSphere(currDist, p, vec3(r+0.007, 0.4, 0.26), r, yellowEyesColor, 0);
    
    // Pupils
    SDFSphere(currDist, p, vec3(r+0.02, 0.4, 0.34), 0.01, blackMouthColor, 0);
    
    // Eyebrow
    p.y += p.x*p.x*1.5;
    float partY = 0.55;
    SDFCapsule(currDist, p, vec3(-0.12, partY, 0.27), vec3(0.12, partY, 0.27), 0.01, whiteBlueEyebrowColor, 0);
    
    // Mouth
    p.y = originalP.y;
    p.y -= p.x * p.x * 9.0 * p.y;
    partY = 0.18;
    SDFCapsule(currDist, p, vec3(-0.15, partY, 0.24), vec3(0.15, partY, 0.24), 0.06, blackMouthColor, 1);
    
    // Nose
    p = originalP;
    p.x = abs(p.x);
    SDFCapsule(currDist, p, vec3(0.0, 0.4, 0.2), vec3(0.0, 0.3, 0.3), 0.02, greenBodyColor, 0);
    
    // Teeth
    float allTeethZ = 0.23;
    float teethX1 = 0.03;
    float teethY1 = 0.01;
    float teethZ1 = 0.01;
    
    // Upper teeth
    for(float i = 0.0; i < 3.0; i += 1.0)
        SDFCapsule(
            currDist, 
            p, 
            vec3(teethX1*i, partY+0.06+teethY1*i, allTeethZ - teethZ1*i), 
            vec3(teethX1*i, partY+0.04+teethY1*i, allTeethZ - teethZ1*i), 
            0.01, 
            yellowTeethColor, 
            0
        );
    
    // Lower teeth
    for(float i = 0.0; i < 4.0; i += 1.0)
        SDFCapsule(
            currDist, 
            p, 
            vec3(teethX1*i, partY-0.04, allTeethZ - teethZ1*i*-0.8), 
            vec3(teethX1*i, partY-0.05, allTeethZ - teethZ1*i*-0.8), 
            0.01, 
            yellowTeethColor, 
            0
        );
    
    // "Weird pickle spots"
    // This can probably be done on a better way.
    // Possibly by rounding the current point to a sector on the main body capsule and assigning
    // each sector to a random point and sphere size on the capsule.
    p = originalP;
    SDFSphere(currDist, p, vec3(0.28, -0.3, 0.05), 0.03, darkGreenSpotColor, 0);
    SDFSphere(currDist, p, vec3(0.27, -0.35, 0.05), 0.03, darkGreenSpotColor, 0);
    SDFSphere(currDist, p, vec3(0.26, -0.6, 0.08), 0.03, darkGreenSpotColor, 0);
    SDFSphere(currDist, p, vec3(0.24, 0.1, 0.08), 0.03, darkGreenSpotColor, 0);
    SDFSphere(currDist, p, vec3(-0.26, -0.4, 0.08), 0.027, darkGreenSpotColor, 0);
    SDFSphere(currDist, p, vec3(-0.24, -0.5, 0.12), 0.027, darkGreenSpotColor, 0);
    SDFSphere(currDist, p, vec3(-0.24, -0.1, 0.12), 0.027, darkGreenSpotColor, 0);
    
    return currDist;
}

vec3 GetNormal(vec3 p)
{
    vec2 offset = vec2(0.0, 0.0001);
    
    vec3 n = vec3(Map(p).x) - 
        vec3(
            Map(p + offset.yxx).x,
            Map(p + offset.xyx).x,
            Map(p + offset.xxy).x
        );
    
    return normalize(n);
}

float GetSpecularLight(vec3 cameraPos, vec3 p, vec3 normal)
{
    vec3 reflectedLightDir = normalize(reflect(lightDir, normal));
    vec3 pointToCam = normalize(cameraPos - p);
    
    float spec = clamp(dot(reflectedLightDir, pointToCam), 0.0, 1.0);
    spec = pow(spec, 3.0);
    
    spec = smoothstep(0.35, 0.55, spec);
    
    return spec * 0.2;
}

vec3 RayMarch(vec2 uv)
{
    // Camera orientation
    vec3 camLookAt = vec3(0.0);
    vec3 camPos = vec3(1.0 * cos(time*0.5), 0.0, 2.3);
    
    vec3 camForward = normalize(camLookAt - camPos);
    vec3 camRight = normalize(cross(camForward, vec3(0.0, 1.0, 0.0)));
    vec3 camUp = normalize(cross(camRight, camForward));
    
    float zoom = 1.0;
    
    // Create point and direction
    vec3 currentPos = camPos + zoom * camForward + uv.x * camRight + uv.y * camUp;
    vec3 rayDir = normalize(currentPos - camPos);
    
    vec3 col = vec3(0.0);
    
    // Ray march loop
    for(int i = 0; i < MAX_RAY_STEPS; i++)
    {
        vec4 currDist = Map(currentPos);
        
        // Hit!
        if(currDist.x <= RAY_HIT_DIST)
        {
            vec3 normal = GetNormal(currentPos);
            vec3 bodyNormal = normal;
            bodyNormal.z += pow(sin(currentPos.y*abs(currentPos.x-0.5)*10.0)*0.5, 2.0) * 0.2;
            
            // Middle of the body
            if(currDist.yzw == greenBodyColor)
            {
                currDist.yzw = mix(greenBodyColor, brightGreenBodyColor, smoothstep(0.90, 0.95, dot(bodyNormal, vec3(0.0, 0.0, -1.0))));
            }
            
            // Ignore shading the teeth
            if(currDist.yzw == yellowTeethColor)
            {
                col = currDist.yzw;
                
                break;
            }
            
            float diffuseShadow = smoothstep(
                0.60, 
                0.40,
                clamp( dot(normal, -lightDir), 0.0, 1.0 )
            );
            float specularLight = GetSpecularLight(camPos, currentPos, normal);
            
            col = currDist.yzw * (max(0.7, diffuseShadow) + specularLight);
            
            break;
        }
        
        currentPos += rayDir * currDist.x;
    }
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;

       vec3 col = RayMarch(uv);
    
    // Output to screen
    glFragColor = vec4(col, 1.0);
}
