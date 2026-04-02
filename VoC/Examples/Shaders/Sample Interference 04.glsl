#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//const vec2 centre = vec2 (0.0);
const float pi = 3.14159265359;

vec2 getRadiusAndAngleForCentre (in vec2 pos, in vec2 centre)
{
    float x         = pos.x - centre.x;
    float y         = pos.y - centre.y;
    float addMultX  = float(x<0.0);
    float addMultY  = float(x>0.0)*float(y<0.0);
    float a         = (atan(y/x) + pi*addMultX + pi*2.0*addMultY) / (2.0*pi);
    float r         = sqrt( pow(abs(pos.x - centre.x), 2.0) + pow (abs(pos.y - centre.y), 2.0) );
    return vec2 (r, a);
}

float getColourForEmitter (vec2 emissionPoint, float growthSpeed, float frequency, float emissionSpeed, float fade)
{
    float waveDistance = mod(time, growthSpeed);
    float outerLim     = 1.0 - smoothstep (waveDistance, waveDistance + fade, emissionPoint.r);
    float colour       = sin (emissionPoint.r*100.0 - waveDistance * 10.0) * outerLim;
    return colour;
}

void main( void ) {

    vec2 pos        = ( gl_FragCoord.xy / min(resolution.x, resolution.y) ) * 2.0 - 1.0;
    vec2 ra1        = getRadiusAndAngleForCentre (pos, vec2(-0.5, 0.5));
    float colour1   = getColourForEmitter (ra1, 5.0, 200.0, 10.0, 0.06);
    
    vec2 ra2        = getRadiusAndAngleForCentre (pos, vec2(0.5, -0.5));
    float colour2   = getColourForEmitter (ra2, 5.0, 200.0, 10.0, 0.06);
    

    glFragColor = vec4( vec3(colour1 + colour2), 1.0 );

}
