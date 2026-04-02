#version 420

// original https://www.shadertoy.com/view/MtjfDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float EPSILON = 0.01;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
int MAX_MARCHING_STEPS = 128;

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(radians(angle));
    float c = cos(radians(angle));
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

mat4 translationMatrix(vec3 translation)
{
  return mat4(1,0,0,0,
              0,1,0,0,
              0,0,1,0,
              translation.x, translation.y, translation.z, 1);
}

float length2( vec2 p )
{
    return sqrt( p.x*p.x + p.y*p.y );
}

float length6( vec2 p )
{
    p = p*p*p; p = p*p;
    return pow( p.x + p.y, 1.0/6.0 );
}

float length8( vec2 p )
{
    p = p*p; p = p*p; p = p*p;
    return pow( p.x + p.y, 1.0/8.0 );
}

struct SDFData {
    float SDV;
    float id;
};

float SDFCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float SDFSphere( vec3 p ) {
    return length(p) - 1.0;
}

float SDFBox( vec3 p, vec3 b ) {
  return length(max(abs(p)-b,0.0));
}

float SDFTorus82( vec3 p, vec2 t )
{
  vec2 q = vec2(length2(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float SDFCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 opCheapBend( vec3 p, float n )
{
    float c = cos(n*p.y);
    float s = sin(n*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float TIMESPEED = 2.0;

SDFData objBall(vec3 p) {
    float n = sin(TIMESPEED * time);
    float smoothValue = smoothstep(-1.00f, 1.0f, n) * 2.0 - 1.0;
    smoothValue = (smoothValue + n) / 2.0f;
    mat4 trans =  translationMatrix(vec3(0, 0.2, -4.5 * smoothValue)) * translationMatrix(vec3(0,3,0)) * translationMatrix(vec3(0,10,0)) *
        rotationMatrix(vec3(1,0,0), 57.0 * smoothValue) * translationMatrix(vec3(0,-10,0));
    
    vec3 q = vec3(inverse(trans)*vec4(p,1));
    float scale = 0.64;
    return SDFData(scale*SDFSphere(q/scale), 1.0f);
}

SDFData objBackFloor(vec3 p) {
    mat4 trans = translationMatrix(vec3(-1007,0.75,1));
    vec3 q = vec3(inverse(trans)*vec4(p,1));
    return SDFData(SDFBox(q, vec3(1000,0.5,1000)), 2.0f);
}

SDFData objFrontFloor(vec3 p) {
    mat4 trans = translationMatrix(vec3(-10,0,1));
    vec3 q = vec3(inverse(trans)*vec4(p,1));
    return SDFData(SDFBox(q, vec3(25,0.5,60)), 3.0f);
}

float objWoodHelper(vec3 p, float rot) {
    float globalZTrans = 3.5;
    mat4 trans1 = rotationMatrix(vec3(0,1,0), rot) * 
                  translationMatrix(vec3(0,3.8,globalZTrans)) *
                  rotationMatrix(vec3(0,1,0), 90.0) *
                  rotationMatrix(vec3(0,0,1), 45.0);
    vec3 q1 = vec3(inverse(trans1)*vec4(p,1));
    q1 = opCheapBend(q1/5.0, 0.7);
    float s1 = 0.4*SDFBox(q1, vec3(0.04,0.6,0.55));
    s1 = s1 * 10.0;
    
    mat4 trans2 = rotationMatrix(vec3(0,1,0), rot) * 
                  translationMatrix(vec3(0,1.22,-2.40 + globalZTrans)) *
                  rotationMatrix(vec3(0,1,0), 90.0) *
                  rotationMatrix(vec3(0,0,1), 142.0);
    vec3 q2 = vec3(inverse(trans2)*vec4(p,1));
    q2 = opCheapBend(q2/4.9, 2.6);
    float s2 = 0.4*SDFBox(q2, vec3(0.07,0.3,0.55));
    s2 = s2 * 10.0;
    
    mat4 trans3 =  rotationMatrix(vec3(0,1,0), rot) * 
                   translationMatrix(vec3(0,0.8,29.0f + globalZTrans));
    vec3 q3 = vec3(inverse(trans3)*vec4(p,1));
    float s3 = SDFBox(q3, vec3(2.68,0.25,30.0));
    
    return min(s3, min(s1, s2));
}

SDFData objWood(vec3 p) {
    float first = objWoodHelper(p, 0.0f);
    float second = objWoodHelper(p, 180.0f);
    return SDFData(min(first, second), 4.0f);
}

SDFData objWasher(vec3 p) {
    float n = sin(TIMESPEED * time);
    float smoothValue = smoothstep(-1.00f, 1.0f, n) * 2.0 - 1.0;
    smoothValue = (smoothValue + n) / 2.0f;
    mat4 trans = translationMatrix(vec3(0,3.5,0)) * translationMatrix(vec3(0,10,0)) * rotationMatrix(vec3(0,0,1), 37.0 * smoothValue) *
                translationMatrix(vec3(0,-10,0)) * rotationMatrix(vec3(1,0,0), 90.0);
        
    vec3 q = vec3(inverse(trans)*vec4(p,1));
    float scale = 0.57;
    return SDFData(scale*SDFTorus82(q/scale, vec2(2.5,0.9)), 5.0f);
}

SDFData objString(vec3 p) {
    float n = sin(TIMESPEED * time);
    float smoothValue = smoothstep(-1.00f, 1.0f, n) * 2.0 - 1.0;
    smoothValue = (smoothValue + n) / 2.0f;
    mat4 trans = translationMatrix(vec3(0,3.5,0)) * translationMatrix(vec3(0,10,0)) * rotationMatrix(vec3(0,0,1), 37.0 * smoothValue) *
                translationMatrix(vec3(0,-10,0)) * rotationMatrix(vec3(0,1,0), 90.0) *
        translationMatrix(vec3(0,8,0));

    vec3 q = vec3(inverse(trans)*vec4(p,1));
    float scale = 0.7;
    return SDFData(scale*SDFCappedCylinder(q/scale, vec2(0.01,9.0)), 6.0f);
}

SDFData SDFScene(vec3 p) {
    const int size = 6;
    SDFData objects[size] = SDFData[](
                                    objBall(p),
                                    objBackFloor(p),
                                    objFrontFloor(p),
                                    objWood(p),
                                    objWasher(p),
                                    objString(p)
                                  );
    
    SDFData bestData = SDFData(100000000.0f,0.0f);
    for(int i = 0; i < size; i++) {
        if(objects[i].SDV < bestData.SDV) {
            bestData = objects[i];
        }
    }
    
    return bestData;
}

SDFData raymarch(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        SDFData data = SDFScene(eye + depth * marchingDirection);
        float dist = data.SDV;
        if (dist < EPSILON) {
            return SDFData(depth, data.id);
        }
        depth += dist;
        if (depth >= end) {
            return SDFData(end, 0.0f);
        }
    }
    return SDFData(end, 0.0f);
}

vec3 estimateNormal(vec3 p) {
    float epsilon = 0.01;
    return normalize(vec3(
        SDFScene(vec3(p.x + epsilon, p.y, p.z)).SDV - SDFScene(vec3(p.x - epsilon, p.y, p.z)).SDV,
        SDFScene(vec3(p.x, p.y + epsilon, p.z)).SDV - SDFScene(vec3(p.x, p.y - epsilon, p.z)).SDV,
        SDFScene(vec3(p.x, p.y, p.z  + epsilon)).SDV - SDFScene(vec3(p.x, p.y, p.z - epsilon)).SDV
    ));
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 gl_FragCoord) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
  vec3 f = normalize(center - eye);
  vec3 s = normalize(cross(f, up));
  vec3 u = cross(s, f);
  return mat4(vec4(s, 0.0), vec4(u, 0.0), vec4(-f, 0.0), vec4(0.0, 0.0, 0.0, 1));
}

float lambert(vec3 N, vec3 L)
{
    vec3 nrmN = normalize(N);
    vec3 nrmL = normalize(L);
    float result = dot(nrmN, nrmL);
    return max(result, 0.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    if(uv.x < 0.15 || uv.x > 0.85) {
        glFragColor = vec4(0,0,0,1);
        return;
    }

    vec3 dir = rayDirection(55.0, vec2(resolution.x,resolution.y), vec2(gl_FragCoord.x, gl_FragCoord.y));
    vec3 eye = vec3(17.0, 14.0, 18.5);
    vec3 lightPosition = vec3(1,1,1);

    mat4 viewToWorld = viewMatrix(eye, vec3(-3.0, 2.0, -3.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(dir, 0.0)).xyz;
    
    SDFData data = raymarch(eye, worldDir, MIN_DIST, MAX_DIST);
    float dist = data.SDV;
    
    if (dist > MAX_DIST - EPSILON) {
        glFragColor = vec4(0,0,0,1);
        return;
    }
    
    vec3 p = eye + dist * worldDir;
    vec3 normal = estimateNormal(p);

    vec3 color;
    if(data.id == 1.0f) {
        color = vec3(1,0,0);
    } else if(data.id == 2.0f) {
        color = vec3(48, 101, 186) / 255.0f;
    } else if(data.id == 3.0f) {
        color = vec3(74, 105, 155) / 255.0f;
    } else if(data.id == 4.0f) {
        color = vec3(0,1,0);
    } else if(data.id == 5.0f) {
        color = vec3(1,1,0);
    } else if(data.id == 6.0f) {
        color = vec3(1,0,1);
    }
    vec3 col = color * lambert(normal, eye - lightPosition);
    glFragColor = vec4(col, 1.0);
}
