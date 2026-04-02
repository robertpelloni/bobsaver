#version 420

// original https://www.shadertoy.com/view/td23DR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Returns the matrix that rotates a point by 'a' radians
mat2 mm2(in float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);
}

// Returns the clamped version of the input
float saturate(float t) {
    return clamp(t, 0.0, 1.0);
}

// ----------------------------
// ------ HASH FUNCTIONS ------
// ----------------------------

// Hash function by Dave Hoskins: https://www.shadertoy.com/view/4djSRW

float hash12(vec2 p) {
    
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
    
}

// -------------------------
// ------ VALUE NOISE ------
// -------------------------

// Standard value noise function (max. gradient is (15/16)^2)

float valueNoise(vec2 p) {
    
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    f = f*f*f*(f*(f*6.0-15.0)+10.0);
    
    vec2 add = vec2(1.0,0.0);
    float res = mix(
        mix(hash12(i + add.yy), hash12(i + add.xy), f.x),
        mix(hash12(i + add.yx), hash12(i + add.xx), f.x),
        f.y);
    return res;
        
}

float heightMap(vec2 p) {
    
    float hScale = 0.5;
    float vScale = 1.0;
    
    float height = valueNoise(p / hScale) * vScale;
    height = floor(height / 0.1) * 0.1;
    return height;
    
}

float raytrace(vec3 ro, vec3 rd) {
    
    // Parameters
    int maxSteps = 500;
    float maxStepDist = 0.05;
    float maxDist = 100.0;
    int maxIterations = 15;
    float eps = 0.001;
    
    // Initial Raymarching Steps
    bool didHit = false;
    float beforeDist = -1.0;
    float afterDist = 0.0;
    float t = 0.0;
    for (int i = 0; i < maxSteps && t < maxDist; i++) {
        
        beforeDist = afterDist;
        afterDist = t;
        vec3 p = ro + t * rd;
        float height = heightMap(p.xz);
        if (p.y - height < eps) {
            didHit = true;
            break;
        }
        
        t += min(p.y - height, maxStepDist);
        
    }
    if (!didHit) {
        return -1.0;
    }
    
    // Use the interval bisection method to find a closer point, as moving forward by a fixed step
    // size may have embedded the ray in a cliff
    for (int i = 0; i < maxIterations; i++) {
        float midVal = (beforeDist + afterDist) / 2.0;
        vec3 p = ro + midVal * rd;
        if (p.y < heightMap(p.xz)) {
            afterDist = midVal;
        }
        else {
            beforeDist = midVal;
        }
    }
    
    // Return the midpoint of the closest point before the terrain, and the closest point after it
    return (beforeDist + afterDist) / 2.0;
    

}

vec3 getNormal(vec3 p) {
    
    // Central differences method to generate a normal vector (doesn't work perfectly for this
    // non-continuous heightmap)
    vec2 eps = vec2(0.005, 0.00);
    vec3 normal = vec3(
        heightMap(p.xz + eps.xy) - heightMap(p.xz - eps.xy),
        2.0 * eps.x,
        heightMap(p.xz + eps.yx) - heightMap(p.xz - eps.yx)
    );
    normal = normalize(normal);
    return normal;
    
}

vec3 getDiffuse(vec3 p) {
    
    return vec3(0.772, 0.580, 0.176);
    
}

vec3 getColor(vec3 p) {
    
    // Directional light source
    vec3 lightDir = normalize(vec3(0.8, 1.0, -0.8));
    
    // The intensity/color of light (all three values are the same for white light)
    vec3 lightCol = vec3(1.0);
    
    // Applies the 'base color' of the light
    vec3 baseLightCol = vec3(1.0, 1.0, 1.0);
    lightCol *= baseLightCol;
    
    // Applies normal-based lighting
    vec3 normal = getNormal(p);
    float normalLight = max(0.05, saturate(dot(normal, lightDir)));
    lightCol *= normalLight;
    
    // Gets the diffuse lighting
    vec3 diffuse = getDiffuse(p);//vec3(0.368, 0.372, 0.901);
    
    // Get the final color
    vec3 col = lightCol * diffuse;
    return col;
    
}

vec3 render(vec3 ro, vec3 rd) {
    
    vec3 skyCol = vec3(0.9, 0.9, 0.9);
    float t = raytrace(ro, rd);
    
    vec3 col = vec3(0.0);
    
    if (t >= 0.0) {
        col = getColor(ro + t * rd);
    }
    
    else {
        col = skyCol;
    }
    
    return col;

}

void main(void) {
    
    // Normalises the gl_FragCoord
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = uv - 0.5;
    p.x *= resolution.x/resolution.y;
    
    // Gets the direction of the ray and the origin
    vec3 ro = vec3(0.0, 3.0, 0.0) + vec3(1.0, 0.0, 1.0) * time * 0.5;
    vec3 rd = normalize(vec3(p, 1.4));

    // Rotates the ray depending on the mouse position. I lifted this from
    // https://www.shadertoy.com/view/XtGGRt, but it seems to be the common approach
    vec2 mo = mouse*resolution.xy.xy / resolution.xy-.5;
    mo = (mo==vec2(-.5))?mo=vec2(0.0, -0.0):mo; // Default position of camera
    mo.x *= resolution.x/resolution.y;
    mo *= 3.0;
    rd.yz *= mm2(mo.y);
    rd.yz *= mm2(-3.14159 / 2.0 + 0.5);
    rd.xz *= mm2(mo.x);
    
    // Render and output the ray to screen
    vec3 col = render(ro, rd);
    float gamma = 2.2;
    col = pow(col, vec3(1.0 / gamma));
    glFragColor = vec4(col,1.0);
    
}
