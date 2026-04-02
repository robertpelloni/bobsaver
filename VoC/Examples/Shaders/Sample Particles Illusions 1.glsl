#version 420

// original https://www.shadertoy.com/view/ltdfWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi (3.14159265359)
#define twopi (6.28318530718)

// thank you CPU
vec2 cartToPol(vec2 coordCart) { return vec2( length(coordCart), atan(coordCart.y,coordCart.x)); }

vec3 colorCircle(vec2 center, float radius, vec3 color, vec2 pos)
{
    
    float d = distance(center, pos);
    float dmr = d - radius;
    if (dmr < 0.) {
        return color;
    }
    return vec3(0.);
}

vec3 colorEmitterCircles(vec2 center, float emittRadius, float circleRadius, vec3 color, float angleRot, float nbrPieces, vec2 pos)
{
    float circleSpeed = 0.8;
    // period T between two pop must be > 2.*circleRadius/circleSpeed
    float T = 4.*circleRadius/circleSpeed;
    vec2 coordPol = cartToPol(pos - center);
    float r = coordPol.x;
    float th = coordPol.y;
    if (r < emittRadius + circleRadius) {
        // on each piece : 
        float numPiece = floor((th - angleRot)/twopi*nbrPieces);
        float anglePath = twopi*(numPiece+0.5)/nbrPieces + angleRot;
        float nT = nbrPieces*T;
        vec2 centerCircle = center + mod(time - numPiece*T, nT)/nT*emittRadius*vec2(cos(anglePath), sin(anglePath));
        return colorCircle(centerCircle, circleRadius, color, pos);
    } else {
        return vec3(0.);
    }
}

void main(void)
{
    // Normalized pixel coordinates (uv.x from -1.0 to 1.0)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.y *= resolution.y/resolution.x; 

    vec3 col = vec3(0.);
    
    vec2 center = vec2(-0.5, 0.);
    float emittRadius = .5; 
    float radiusCircles = 0.01;
    vec3 color1 = vec3(.4, .4, .6);
    float angleRot = 0.;
    float nbrPieces = 10.;
    for (int i=0; i<40; i++) {
        col += colorEmitterCircles(center, emittRadius, radiusCircles, color1, angleRot, nbrPieces, uv);
        angleRot += 0.1*time/2.;
    }
    
    center = vec2(0.5, 0.);
    radiusCircles = 0.01;
    angleRot = 0.;
    nbrPieces = 100.;
    for (int i=0; i<30; i++) {
        col += colorEmitterCircles(center, emittRadius, radiusCircles, color1, angleRot, nbrPieces, uv);
        angleRot += 0.1*time/2.;
    }
    
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
