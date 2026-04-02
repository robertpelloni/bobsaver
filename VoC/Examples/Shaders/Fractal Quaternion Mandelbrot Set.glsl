#version 420

// original https://www.shadertoy.com/view/7tdyz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ITERATIONS = 30.0;
float THRESHOLD = 10.0;

float MAX_DIST = 10.0;
int MAX_STEPS = 1500;

float SURF_THRESHOLD = 0.001;

float ROT_SPEED = 0.1;

vec4 quatsqr(vec4 z){
    float a = z.r;
    float b = z.g;
    float c = z.b;
    float d = z.a;
    
    float r = a*a - b*b - c*c - d*d;
    float i = 2.0*a*b + 2.0*d*c;
    float j = 2.0*a*c - 2.0*b*d;
    float k = 2.0*a*d + 2.0*b*c;
    
    return vec4(r, i, j, k);
}

float fractal(vec4 c){
    vec4 z = vec4(0);
    float l = 0.0;
    for(int i=0;i<int(ITERATIONS);i++){
        z = quatsqr(z)+c;
        if(dot(z,z) > THRESHOLD) break;
        l += 1.0;
    }

    if(l> ITERATIONS-1.0)return 0.0;
    
    float sl = l - log2(log2(dot(z,z)))+4.0;
    
    l = 1.0-sl/ITERATIONS;
    
    return l;
}

vec3 raymarch(vec3 rayOrigin, vec3 rayDirection){
    vec4 pointer = vec4(rayOrigin, 0.0);
    vec4 direction = vec4(rayDirection, 0.0);
    
    float dist = fractal(pointer);
    float steps = 0.0;
    
    float minDist = dist;
    
    for(int i = 0; i < MAX_STEPS; i++){
        if(dist <= SURF_THRESHOLD) break;
        if(dist >= MAX_DIST) break;
        pointer += direction*dist*0.03;
        dist = fractal(pointer);
        minDist = (dist < minDist)?dist:minDist;
        steps += 1.0;
    }
    
    
    
    return vec3(minDist, steps, length(pointer.xyz-rayOrigin));
}

vec3 getNormal(vec3 point, mat3 worldMat){
    float d = 0.02;
    
    vec4 p = vec4(point, 0.0);
    vec4 dx = vec4(vec3(d, 0, 0)*worldMat, 0.0);
    vec4 dy = vec4(vec3(0, d, 0)*worldMat, 0.0);
    vec4 dz= vec4(vec3(0, 0, d)*worldMat, 0.0);
    
    float dist = fractal(p);
    float DX = dist - fractal(p+dx);
    float DY = dist - fractal(p+dy);
    float DZ = dist - fractal(p+dz);
    
    return normalize(vec3(DX,DY,DZ));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 plane = (uv - vec2(0.5))*vec2(19.0/9.0, 1.0) * 2.0;
    
    float a = time*ROT_SPEED;
    
    mat3 rotY = mat3(cos(a), 0, sin(a), 0, 1.0, 0, -sin(a), 0, cos(a));
    mat3 rotX = mat3(1.0,0,0,0,cos(a),-sin(a),0,sin(a),cos(a));
    mat3 worldRot = rotY*rotX;
    
    vec3 rayOrigin = vec3(plane, 10.0)*rotY*rotX;
    vec3 rayDirection = vec3(0,0,-1.0)*rotY*rotX;
    
    vec3 col = vec3(0.0);
    
    vec3 march = raymarch(rayOrigin, rayDirection);
    float l = march.x;
    float steps = march.y;
    float depth = march.z;
    
    if(l < SURF_THRESHOLD) {
        vec3 normal = getNormal(rayOrigin + rayDirection*depth, worldRot);//*inverse(worldRot);
        col = vec3(1.0);
        //col *= 200.0/(steps);
        //col *= pow(length(col),2.0);
        vec3 shadowCol = col * dot(normal,-normalize(vec3(1.0,1.0,0.0)));
        col = mix(col, shadowCol, 0.9);
        col = mix(col, abs(normal), 0.5);
    }else{
        col += vec3(0.2)/l;
        col *= col;
    }
    
    glFragColor = vec4(col,1.0);
}
