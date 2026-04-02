#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926535897932384626433832795

const int maxSteps = 1000;
const int freezeStepThreshold = 10;
const float freezeDistanceThreshold = 15.;
const float pendulumWeight = 1.;
const float gravityConstant = 1.;
const float stepLength = 0.5;

vec2 getAttractionForce(vec3 ball, vec2 pendulum)
{
    float magnitude = gravityConstant * ball.z * pendulumWeight / distance(ball.xy, pendulum);
    
    return normalize(ball.xy - pendulum.xy) * magnitude;
}

void main( void ) {
    
    vec4 color;
    
    vec2 pos = gl_FragCoord.xy;
    
    pos /= resolution;
    pos.x -= 0.25;
    
    pos.x *= (resolution.x / resolution.y);
    
    pos *= 5.;
    
    pos -= 2.;
    
    float redBallArc = 2. * M_PI / 3.;
    float blueBallArc = 4. * M_PI / 3.;
    float yellowBallArc = 2. * M_PI;

    vec3 redBall = vec3(sin(redBallArc), cos(redBallArc), sin(time));
    
    vec3 blueBall = vec3(sin(blueBallArc), cos(blueBallArc), cos(time));
    
    vec3 yellowBall = vec3(sin(yellowBallArc), cos(yellowBallArc), cos(time) + sin(time));
    
    int freezeStepCount = 0;
    
    vec2 currentPosition = pos;
    
    for (int i = 0; i < maxSteps; i++) {
        vec2 direction = vec2(0,0);
        
        direction += getAttractionForce(redBall, currentPosition);
        direction += getAttractionForce(blueBall, currentPosition);
        direction += getAttractionForce(yellowBall, currentPosition);
        
        currentPosition += direction;
        
        if (length(direction) < freezeDistanceThreshold) {
            freezeStepCount++;
        } else {
            freezeStepCount = 0;
        }
        
        if (freezeStepCount == freezeStepThreshold) {
            float redBallDistance = distance(redBall.xy, currentPosition);
            float blueBallDistance = distance(blueBall.xy, currentPosition);
            float yellowBallDistance = distance(yellowBall.xy, currentPosition);
            
            float brightness = 1. / (float(i) / float(maxSteps));
            
            if (redBallDistance <= blueBallDistance && redBallDistance <= yellowBallDistance) {
                color.x = brightness;
            } else if (blueBallDistance <= redBallDistance && blueBallDistance <= yellowBallDistance) {
                color.z = brightness;
            } else if (yellowBallDistance <= redBallDistance && yellowBallDistance <= blueBallDistance) {
                color.x = color.y = brightness;
            }
            break;
        }
    }
    
    if (distance(redBall.xy, pos) < 0.1) {
        
        color = vec4(vec3(1, 0, 0), 1);
    }
    
    if (distance(yellowBall.xy, pos) < 0.1) {
        
        color = vec4(vec3(1, 1, 0), 1);
    }
    
    if (distance(blueBall.xy, pos) < 0.1) {
        
        color = vec4(vec3(0, 0, 1), 1);
    }
    
    glFragColor = color;

//    glFragColor = vec4( vec3( color, color * 0.5, sin( color + time / 3.0 ) * 0.75 ), 1.0 );

}
