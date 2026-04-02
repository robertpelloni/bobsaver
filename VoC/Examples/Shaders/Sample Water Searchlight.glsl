#version 420

// original https://www.shadertoy.com/view/NsG3Dw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
         
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
}

/* const matrices for 3d rotation */
const mat3 rot1 = mat3(-0.37, 0.36, 0.85,-0.14,-0.93, 0.34,0.92, 0.01,0.4);
const mat3 rot2 = mat3(-0.55,-0.39, 0.74, 0.33,-0.91,-0.24,0.77, 0.12,0.63);
const mat3 rot3 = mat3(-0.71, 0.52,-0.47,-0.08,-0.72,-0.68,-0.7,-0.45,0.56);

/* directional artifacts can be reduced by rotating each octave */
float noise(vec3 m) {
    return   0.5333333*simplex3d(m*rot1)
            +0.2666667*simplex3d(2.0*m*rot2)
            +0.1333333*simplex3d(4.0*m*rot3)
            +0.0666667*simplex3d(8.0*m);
}

float planeSDF (vec3 position, vec3 start, vec3 normal ) {
    float distance = dot( position - start, normal );
    return distance;
}

float wave (float x, float y, float t) {
    float wave = 0.3 * noise(vec3(0.3 * x - 2.1 * t, 0.5 * y,  2.0 * t))
        ;
        
    return wave;
}

float waterSDF (vec3 position) {
    float x = position.x;
    float y = position.z;
    float w = wave(position.x, position.z, time / 10.0);
    vec3 pos = position + vec3(0, w, 0);
    float floor = planeSDF(pos, vec3(0, -5, 0), vec3(0, 1, 0));
    return floor;
}

float SDF (vec3 position) {
    float water = waterSDF(position);
    return water;
}

vec3 normal (vec3 position) {
    float dt = 0.0001;
    float dx = SDF(position + vec3(dt, 0, 0)) - SDF(position - vec3(dt, 0, 0));
    float dy = SDF(position + vec3(0, dt, 0)) - SDF(position - vec3(0, dt, 0));
    float dz = SDF(position + vec3(0, 0, dt)) - SDF(position - vec3(0, 0, dt));
    vec3 normal = normalize(vec3(dx, dy, dz));
    return normal;
}

float raymarch (vec3 start, vec3 direction) {
    #define maxSteps 100
    #define converged 0.0001
    vec3 position = start;
    float totalDistance = 0.0;
    for (int i = 0; i < maxSteps; i++ ) {
        // Step forward by the SDF distance
        float currentDistance = SDF(position);
        totalDistance += currentDistance;
        position += direction * currentDistance;
        
        // If we are close to a surface, stop iterating
        if ( currentDistance < converged ) break;
    }
    return totalDistance;
}

vec3 lighting ( vec3 surface ) {
    // Define the lighting parameters
    vec3 light = vec3(0, 2, 18) + 15.0 * vec3(cos(time), 0, sin(time));
    float strength = 0.3;
    vec3 specular = vec3(145, 228, 237) / 255.0;
    vec3 diffuse = vec3(11, 45, 77) / 255.0;
    
    // Calculate the sphere's brightness
    vec3 lightDelta = light - surface;
    vec3 N = normal(surface);
    vec3 L = normalize(lightDelta);
    float lightDistance = raymarch(surface + 0.2 * N, L);
    float brightness = strength * dot(N, L);
    
    // Add a reflection
    
    
    // Add a Shadow color
    float straightLightDistance = length(lightDelta);
    bool occluded = straightLightDistance < 300.0
        && straightLightDistance + 0.3 > lightDistance;
    vec3 shadow = occluded
        ? 1.0 * vec3(1, 1, 1)
        : vec3(1, 1, 1);
    
    // Calculate the color

    vec3 color = brightness * specular * shadow / pow(straightLightDistance, 2.0) * 300.0 + diffuse ;
    return color;
}

void main(void) {
    // Setup the camera and the pixel coordinates
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    vec3 start = vec3(uv, 0);
    vec3 camera = vec3(0, 0.4, -0.3);
    vec3 direction = normalize(start - camera);
   
    
    // Get the distance to the nearest object
    float distance = raymarch(start, direction);
    if ( distance > 100.0 ) {
        glFragColor = vec4(17, 45, 79, 0)/255.0;
        return;
    }
    
    // Find the surface point and the corresponding normal 
    vec3 surface = start + distance * direction;
    vec3 color = lighting(surface);
    glFragColor = vec4(color, 0.0);    
    
    // Output to screen
    glFragColor = vec4(color ,1.0);
}
