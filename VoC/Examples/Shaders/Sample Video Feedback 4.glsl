#version 420

// GLSL Video Feedback by Tim Scaffidi

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = 3.141592656;
const ivec2 kernelSize = ivec2(5);

// Bilinear texture filtering from https://www.codeproject.com/Articles/236394/Bi-Cubic-and-Bi-Linear-Interpolation-with-GLSL#GLSLLinear
vec4 tex2DBiLinear( sampler2D textureSampler_i, vec2 texCoord_i, vec2 textureSize)
{
    float texelSizeX = 1.0 / textureSize.x;
    float texelSizeY = 1.0 / textureSize.y;
    
    vec4 p0q0 = texture2D(textureSampler_i, texCoord_i);
    vec4 p1q0 = texture2D(textureSampler_i, texCoord_i + vec2(texelSizeX, 0));

    vec4 p0q1 = texture2D(textureSampler_i, texCoord_i + vec2(0, texelSizeY));
    vec4 p1q1 = texture2D(textureSampler_i, texCoord_i + vec2(texelSizeX , texelSizeY));

    float a = fract( texCoord_i.x * textureSize.x ); // Get Interpolation factor for X direction.
                    // Fraction near to valid data.

    vec4 pInterp_q0 = mix( p0q0, p1q0, a ); // Interpolates top row in X direction.
    vec4 pInterp_q1 = mix( p0q1, p1q1, a ); // Interpolates bottom row in X direction.

    float b = fract( texCoord_i.y * textureSize.y );// Get Interpolation factor for Y direction.
    return mix( pInterp_q0, pInterp_q1, b ); // Interpolate in Y direction.
}

float noise2d(vec2 uv) {
    return fract(sin(dot(uv.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void minMaxAvgKernelSample(sampler2D tex, vec2 uv, vec2 textureSize, out vec4 minS, out vec4 maxS, out vec4 avgS) {
    minS = vec4(1.0);
    maxS = vec4(0.0);
    avgS = vec4(0.0);
    const float avgScale = 1.0 / float((kernelSize.x*2+1) * (kernelSize.x*2+1));
    for(int y = 0; y < kernelSize.y; y++) {
        for(int x = 0; x < kernelSize.x; x++) {
            vec2 offset = (vec2(x,y) - vec2(kernelSize)) / textureSize;
            
            vec4 sample = tex2DBiLinear(tex, uv + offset, textureSize);
            minS = min(minS, sample);
            maxS = max(maxS, sample);
            avgS += sample * avgScale;
        }
    }
    
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy ) + mouse / 4.0;
    
    vec4 noise = vec4(
        noise2d(position + vec2(time)*0.015645645),
        noise2d(position + vec2(time)*0.013123123),
        noise2d(position + vec2(time)*0.01342342342),
        1.0
    );
    
    vec2 feedbackPos = (gl_FragCoord.xy / resolution.xy );
    feedbackPos = feedbackPos + vec2(0.5 / resolution.xy);
    feedbackPos += (sin(time*0.242))*1.59*(vec2(cos(feedbackPos.x*PI*0.5),sin(feedbackPos.y*PI*0.5))  / resolution.xy);
    feedbackPos -= (sin(time*0.456))*1.59*(vec2(sin(feedbackPos.x*PI*0.5),cos(feedbackPos.y*PI*0.5))  / resolution.xy);
    feedbackPos += (sin(time*0.743))*1.59*(vec2(sin(feedbackPos.y*PI*0.5),sin(feedbackPos.x*PI*0.5))  / resolution.xy);
    feedbackPos -= (sin(time*0.175))*1.59*(vec2(cos(feedbackPos.y*PI*0.5),cos(feedbackPos.x*PI*0.5))  / resolution.xy);
    
    vec4 feedback = tex2DBiLinear(backbuffer, feedbackPos, resolution.xy);
    
    vec4 color = feedback;
    
    vec4 minS,maxS,avgS;
    minMaxAvgKernelSample(backbuffer, feedbackPos, resolution.xy, minS, maxS, avgS);
    maxS += (1.0 - avgS) * 0.35;
             
    color = (color - minS) / (maxS - minS) * 0.55 + noise * 0.05 * max(0.0, pow(1.0-distance(feedbackPos, vec2(0.5)),10.0)) + avgS * 0.5;
    
    glFragColor = color;
}
