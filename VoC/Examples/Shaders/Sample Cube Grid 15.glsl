#version 420

// original https://www.shadertoy.com/view/WstXDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0001

/**
 * Rotation matrix around the X axis.
 */
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

/**
 * Rotation matrix around the Y axis.
 */
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

/**
 * Rotation matrix around the Z axis.
 */
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float sdBox( vec3 p, vec3 b )
{
      vec3 q = abs(p) - b;
      float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
      return d;
}

float GetDist(vec3 p) {
    vec3 boxOrigin = vec3(0, 0, 6);
    p = p - boxOrigin;
    p = rotateY(time / 6.) * rotateX(time / 4.) * p;
    
    vec3 c = vec3(5,5,5);
    p = mod(p+0.5*c,c)-0.5*c;
    
    return sdBox(p, vec3(.2,1,1));
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(SURF_DIST, 0);
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}   

float RayMarch(vec3 ro, vec3 rd) {    
    float dO = 0.;
    
    for (int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if (dO > MAX_DIST || dS < SURF_DIST) break;
    }
    
    return dO;
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(1, 1, 1);
    vec3 lightV = normalize(lightPos - p);
    vec3 normal = GetNormal(p);
    
    float dif = clamp(dot(normal, lightV), 0., 1.);    
    
    float d = RayMarch(p+normal*SURF_DIST*2., lightV);
    if (d < length(lightPos - p)) dif *= .5;

    return dif;
}

    

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 3, 0);
    vec3 rd = normalize(vec3(uv.x, uv.y - .5, 1));
    
    float d = RayMarch(ro, rd);
    vec3 p = ro + rd * d;
    
    float diffuseL = GetLight(p);
    
    col = vec3(diffuseL);
    
    glFragColor = vec4(col,1.0);
}
