#version 420

// original https://www.shadertoy.com/view/wttXD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;
const float PI = 3.14159265359;
const float PHI = 1.6180339887498948482045868343656;

float heartShape(vec3 p, float rad) {
    // TODO 1: Change this to a heart SDF function
    
    //float result = length(p) - rad;

    //return result;
    
    
    float z = p.z * (2.0 - p.y / 15.0);
    float y = 1.3 * p.y - abs(p.x) * sqrt(1.0 - abs(p.x));
    vec3 p2 = vec3(p.x, y, p.z);
    return length(p2) - rad;
}

// TODO 2.1: Write function to call heartShape with animated radius

// SDF for the scene
float sceneSDF(vec3 samplePoint) {

    // we want to make the sphere bigger
    // we will do this by 
    //samplePoint *= vec3(sin(time), 1.0, cos(time));
    float result = heartShape(samplePoint, 0.2 * abs(sin(PI * time * 0.5 + samplePoint.y * 0.1)) + 0.6);
    return result;
}

// get shortest distance to surface using ray marching
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        // TODO 2.1: Call animated radius version of SDF instead of heartShape
        float dist = sceneSDF(eye + depth * marchingDirection);
        //float dist = heartShape(eye + depth * marchingDirection, 0.5);
        if (dist < EPSILON) {
            return depth;
        }

        // SPHERE CASTING! :D
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}           

/////// ******** SHADER STUFF ******** ///////
/////// don't worry about all of this! ///////
/////// this is all to make the heart  ///////
/////// shiny. if you want to know     ///////
/////// more about this, ask or pop me ///////
/////// an email!                       ///////

// estimate normal using SDF gradient
vec3 estimateNormal(vec3 pos) {
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy * heartShape(pos + e.xyy, 0.7 ) +
                      e.yyx * heartShape( pos + e.yyx, 0.7 ) + 
                      e.yxy * heartShape( pos + e.yxy, 0.7 ) + 
                      e.xxx * heartShape( pos + e.xxx, 0.7 ));
}

vec2 map( vec3 q )
{
    q *= 100.0;

    vec2 res = vec2( q.y, 2.0 );

    float r = 15.0;
    q.y -= r;
    float ani = pow( 0.5+0.5*sin(6.28318*time + q.y/25.0), 4.0 );
    q *= 1.0 - 0.2*vec3(1.0,0.5,1.0)*ani;
    q.y -= 1.5*ani;
    float x = abs(q.x);
    float y = q.y;
    float z = q.z;
    y = 4.0 + y*1.2 - x*sqrt(max((20.0-x)/15.0,0.0));
    z *= 2.0 - y/15.0;
    float d = sqrt(x*x+y*y+z*z) - r;
    d = d/3.0;
    if( d<res.x ) res = vec2( d, 1.0 );
    
    res.x /= 100.0;
    return res;
}

vec3 forwardSF( float i, float n) 
{
    float phi = 2.0*PI*fract(i/PHI);
    float zi = 1.0 - (2.0*i+1.0)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}

float hash1( float n )
{
    return fract(sin(n)*43758.5453123);
}

float calcAO( in vec3 pos, in vec3 nor ) {
    float ao = 0.0;
    for( int i=0; i<64; i++ )
    {
        vec3 kk;
        vec3 ap = forwardSF( float(i), 64.0 );
        ap *= sign( dot(ap,nor) ) * hash1(float(i));
        ao += clamp( map( pos + nor*0.01 + ap*0.2 ).x*20.0, 0.0, 1.0 );
    }
    ao /= 64.0;
    
    return clamp( ao, 0.0, 1.0 );
}

/////////////////////////////////////////////////
//////////////// end of shader ! ////////////////
/////////////////////////////////////////////////

/////////////// main function ///////////////////
void main(void) {
    vec3 eye = vec3(0, 0, 5.0);
    vec3 up = vec3(0, 1, 0);
    vec3 right = vec3(1, 0, 0);

    float an = 0.2*(time+2.0);
    float u = gl_FragCoord.xy.x * 2.0 / resolution.x - 1.0;
    float v = gl_FragCoord.xy.y * 2.0 / resolution.y - 1.0;
    float aspect = resolution.x / resolution.y;
    vec3 rayOrigin = (right * u * aspect + up * v - eye);
    vec3 rayDirection = normalize(cross(right, up));

    float dist = shortestDistanceToSurface(rayOrigin, rayDirection, MIN_DIST, MAX_DIST);
    
    // if our ray didn't hit anything, 
    if (dist >= MAX_DIST - 2.0 * EPSILON) {
        // TODO 3: Change background from white to color gradiant
        //glFragColor = vec4(1.0);
        //return;
        
        // blue
        vec4 col1 = vec4(0.25, 0.3, 0.8, 1.0);

        // yellow
        vec4 col2 = vec4(1.2, 0.77, 0.5, 1.0);

        glFragColor = mix(col2, col1, v * 0.5);
        return;
    }
    
    vec3 position = rayOrigin + dist * rayDirection;
    vec3 normal = estimateNormal(position);
    vec3 ref = reflect(rayDirection, normal);
    float fre = clamp(1.0 + dot(normal, rayDirection), 0.0, 1.0);
    float occ = calcAO(position, normal); 
    occ = occ*occ;
    // OPTIONAL TODO: change object color 
    vec3 col = vec3(0.9,0.05,0.01);
    col = col*0.72 + 0.2*fre*vec3(1.0,0.8,0.2);
            
    vec3 lin  = 4.0*vec3(0.7,0.80,1.00)*(0.5+0.5*normal.y)*occ;
    lin += 0.5*fre*vec3(1.0,1.0,1.00)*(0.6+0.4*occ);
    //col = col * lin;
    col += smoothstep(0.0,0.4,ref.y)*(0.06+0.94*pow(fre,5.0))*occ;

    col = pow(col,vec3(0.4545));
    col = clamp(col,0.0,1.0);
    //col -= 0.5; //+ 0.8*pow(16.0*u*v*(1.0-u)*(1.0-v),0.2);
    
    glFragColor = vec4(col, 1.0);

}
