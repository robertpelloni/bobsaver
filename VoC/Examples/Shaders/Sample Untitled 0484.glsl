#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

const int nParticles = 500;
const int nExplosions = 1;
const float particleMaxLife = 2.0;
const float maxTime = 2.5;
const float particleSize = 0.01;

vec3 particles (vec2 p, float t) {
    vec3 result = vec3(0.0);
    int round = int(time / maxTime);
    for (int j = 0; j < nExplosions; j++) {
        
        vec2 particleStart = vec2(
            0.5 + 0.1 * sin (8.0 * 3.141592 * rand(vec2(float(round + j), 0.0))),
            0.5 + 0.1 * sin (8.0 * 3.141592 * rand(vec2(0.0, float(round + j))))
        );
        particleStart.x *= resolution.x / resolution.y;
        for (int i = 0; i < nParticles; i++) {
            vec2 particleVelocity = vec2(
                1.0 - 2.0 * rand(vec2(float(i + j * nParticles), float(round))), 
                1.0 - 2.0 * rand(vec2(float(round), float(i + j * nParticles)))
            );
            particleVelocity *= 2.0;
            float particleVelocityScale = 1.0 + rand(vec2(float((i + j * nParticles) * 4), 0.0));
            
            vec2 particlePos = particleStart + particleVelocity * t * particleVelocityScale;
            float d = length(p - particlePos);
            float particleDistanceFromStart = length(particleStart - particlePos);
            float life = max (particleMaxLife - t, 0.0);
            float particle = d < particleSize ? pow (((particleSize - d) / particleSize), 4.0) : 0.0;
            particle *= 20.0;
            vec3 particleColor = vec3 (
                rand(vec2(float(i + j * nParticles) * 2.5, 0.0)),
                rand(vec2(float(i + j * nParticles) * 4.5, 0.0)),
                rand(vec2(float(i + j * nParticles) * 6.5, 0.0))
            );
            result += particleColor * particle;
        }
    }
    return result;
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    position.x *= resolution.x / resolution.y;

    vec3 color = particles(position, mod (time, maxTime));

    glFragColor = vec4( color, 1.0 );

}
