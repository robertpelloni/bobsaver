#version 420

// Ray-casting with texture by Omar El Sayyed (http://nomone.com). This is far from optimal. It's written to be overly verbose and self-explanatory.
// Borrowed the smily face from here: http://glsl.heroku.com/e#201.0  (By @mnstrmnch).

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define PI 3.14159265

vec3 eyePosition = vec3(0.0, 0.0, -2.0);
vec3 lightPosition = vec3(0.0, 0.0, -1.0);

vec3 faceTexture(vec2 position) {

  vec3 color = vec3(0.0, 0.0, 0.5);
    
  // Transform input position from (0.0, 0.0)-(1.0, 1.0) to (-1.0, 1.0)-(1.0, -1.0),
  position = (position * 2.0) - 1.0;
  position.y = -position.y;

  // Simple face texture. Bottom left at (-1.0, -1.0) and top right at (1.0, 1.0),
  if(length(position) < 1.0) {
    if(length(position) < 0.9) {
      color = vec3(1.0) - color;
      if (length(position * vec2(1.0, 1.0)) < 0.7 && length(position) > 0.6 && position.y < -0.125) color = vec3(0.0); // smile
      if (length((position - vec2(-0.35, 0.35)) * vec2(1.0, 0.5)) < 0.125) color = vec3(0.0); // left eye
      if (length((position - vec2(+0.35, 0.35)) * vec2(1.0, 0.5)) < 0.125) color = vec3(0.0); // right eye
    } else {
      color = vec3(0.0);
    }
  } 

  return color;
}

float intersectCube(vec3 rayVector, vec3 pointOnRay, vec3 cubeMin, vec3 cubeMax) {
  
  vec3 tMin = (cubeMin - pointOnRay) / rayVector;
  vec3 tMax = (cubeMax - pointOnRay) / rayVector;
  
  vec3 tNear = min(tMin, tMax);
  vec3 tFar  = max(tMin, tMax);
  
  float tNearMax = max(max(tNear.x, tNear.y), tNear.z);
  float tFarMin  = min(min(tFar .x, tFar .y), tFar .z);
  
  if (tNearMax > tFarMin) return 1000.0;
  
  return max(max(tNear.x, tNear.y), tNear.z);  
}

vec3 getPointOnCubeNormal(vec3 point, vec3 cubeMin, vec3 cubeMax) {
  if (abs(point.x-cubeMin.x) < 0.001) return vec3(-1.0,  0.0,  0.0);
  else if (abs(point.x-cubeMax.x) < 0.001) return vec3( 1.0,  0.0,  0.0);
  else if (abs(point.y-cubeMin.y) < 0.001) return vec3( 0.0, -1.0,  0.0);
  else if (abs(point.y-cubeMax.y) < 0.001) return vec3( 0.0,  1.0,  0.0);
  else if (abs(point.z-cubeMin.z) < 0.001) return vec3( 0.0,  0.0, -1.0);
  else if (abs(point.z-cubeMax.z) < 0.001) return vec3( 0.0,  0.0,  1.0);
  else return vec3(0.0);
}

vec3 getPointOnCubeTextureColor(vec3 point, vec3 cubeMin, vec3 cubeMax) {
  if (abs(point.x-cubeMin.x) < 0.001) {
    return faceTexture(vec2(
        (cubeMax.z - point.z) / (cubeMax.z - cubeMin.z),
        (cubeMax.y - point.y) / (cubeMax.y - cubeMin.y)));
  } else if (abs(point.x-cubeMax.x) < 0.001) {
    return faceTexture(vec2(
        (point.z - cubeMin.z) / (cubeMax.z - cubeMin.z),
        (cubeMax.y - point.y) / (cubeMax.y - cubeMin.y)));
  } else if (abs(point.y-cubeMin.y) < 0.001) {
    return faceTexture(vec2(
        (point.x - cubeMin.x) / (cubeMax.x - cubeMin.x),
        (point.z - cubeMin.z) / (cubeMax.z - cubeMin.z)));
  } else if (abs(point.y-cubeMax.y) < 0.001) {
    return faceTexture(vec2(
        (point.x - cubeMin.x) / (cubeMax.x - cubeMin.x),
        (cubeMax.z - point.z) / (cubeMax.z - cubeMin.z)));
  } else if (abs(point.z-cubeMin.z) < 0.001) {
    return faceTexture(vec2(
        (point.x - cubeMin.x) / (cubeMax.x - cubeMin.x),
        (cubeMax.y - point.y) / (cubeMax.y - cubeMin.y)));
  } else if (abs(point.z-cubeMax.z) < 0.001) {
      return faceTexture(vec2(
        (cubeMax.x - point.x) / (cubeMax.x - cubeMin.x),
        (cubeMax.y - point.y) / (cubeMax.y - cubeMin.y)));
  } else return vec3(0.0);
}

vec4 light(vec3 pointPosition, vec3 pointNormal, vec3 lightPostiion, vec4 ambientColor, vec4 diffuseColor, vec4 specularColor, float shininess) {  
  
  vec3 L = normalize(lightPostiion - pointPosition);   
  vec3 E = normalize(eyePosition - pointPosition); 
  vec3 R = normalize(-reflect(L, pointNormal));  
 
  // Calculate ambient term,
  vec4 ambient = ambientColor;

  // Calculate diffuse term,
  vec4 diffuse = diffuseColor * max(dot(pointNormal,L), 0.0);
  diffuse = clamp(diffuse, 0.0, 1.0);     

  // Calculate specular term,
  vec4 specular = specularColor * pow(max(dot(R,E),0.0),0.3*shininess);
  specular = clamp(specular, 0.0, 1.0); 

  return ambient + diffuse + specular;
}

void main() {
  
  // Normalize coordinates,
  vec3 pointPosition = vec3((gl_FragCoord.xy / resolution) * 2.0 - 1.0, 0.0);
  pointPosition.x *= resolution.x / resolution.y;
  
  vec3 cubeMin = vec3(-0.5, -0.5, -0.5);
  vec3 cubeMax = vec3( 0.5,  0.5,  0.5);

  // Transform point, eye and light positions to rotate the cube,
  vec3 cubeCenter = (cubeMin + cubeMax) * 0.5;

  // Rotate around x-axis,
  vec3 tempPoint = pointPosition - cubeCenter;
  vec3 tempEye   =   eyePosition - cubeCenter;
  vec3 tempLight = lightPosition - cubeCenter;
  float aboutXAngle = 0.3123 * time;
  float cosAngle = cos(aboutXAngle);
  float sinAngle = sin(aboutXAngle);
  pointPosition.z = (tempPoint.z * cosAngle) - (tempPoint.y * sinAngle);
  pointPosition.y = (tempPoint.y * cosAngle) + (tempPoint.z * sinAngle);
  eyePosition.z   = (tempEye.z   * cosAngle) - (tempEye.y   * sinAngle);
  eyePosition.y   = (tempEye.y   * cosAngle) + (tempEye.z   * sinAngle);
  lightPosition.z = (tempLight.z * cosAngle) - (tempLight.y * sinAngle);
  lightPosition.y = (tempLight.y * cosAngle) + (tempLight.z * sinAngle);

  // Rotate around z-axis,
  tempPoint = pointPosition;
  tempEye   =   eyePosition;
  tempLight = lightPosition;
  float aboutZAngle = time;
  cosAngle = cos(aboutZAngle);
  sinAngle = sin(aboutZAngle);
  pointPosition.x = (tempPoint.x * cosAngle) - (tempPoint.y * sinAngle);
  pointPosition.y = (tempPoint.y * cosAngle) + (tempPoint.x * sinAngle);
  eyePosition.x   = (tempEye.x   * cosAngle) - (tempEye.y   * sinAngle);
  eyePosition.y   = (tempEye.y   * cosAngle) + (tempEye.x   * sinAngle);
  lightPosition.x = (tempLight.x * cosAngle) - (tempLight.y * sinAngle);
  lightPosition.y = (tempLight.y * cosAngle) + (tempLight.x * sinAngle);
  
  pointPosition += cubeCenter;
  eyePosition   += cubeCenter;
  lightPosition += cubeCenter;
  
  // Ray cast,
  vec3 rayVector = pointPosition - eyePosition;
  float t = intersectCube(rayVector, eyePosition, cubeMin, cubeMax);
  
  if (t == 1000.0) {
    glFragColor = vec4(0.0);
    return ;
  }
  
  vec3 intersectionPoint = eyePosition + (t * rayVector);
  vec3 normal;
  normal = getPointOnCubeNormal(intersectionPoint, cubeMin, cubeMax);
  
  // Texture,
  vec4 textureColor = vec4(getPointOnCubeTextureColor(intersectionPoint, cubeMin, cubeMax), 1.0);
  
  // Light,
  vec4 lightColor = light(
    intersectionPoint, normal, 
    lightPosition, 
    vec4(0.15, 0.15, 0.15, 1.0), 
    vec4(1.0, 1.0, 1.0, 1.0), 
    vec4(0.8, 0.8, 0.8, 1.0),
    40.0);
    
  glFragColor = textureColor * lightColor;
}
