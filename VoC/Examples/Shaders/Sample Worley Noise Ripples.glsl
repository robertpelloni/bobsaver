#version 420

// original https://www.shadertoy.com/view/wslBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random1(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                 dot(p, vec2(269.5,183.3))))
                 * 43758.5453);
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p, vec2(324.1, 21.7)),
                 dot(p, vec2(45.5,234.3))))
                 * 345.098);
}

float WorleyNoise1(vec2 uv) {
    const float dimen = 10.0; // dimension
    uv[0] *= dimen;
    float ratio = resolution.y / resolution.x;
    uv[1] *= dimen * ratio; // Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0; // Minimum distance initialized to max.
        
        for(int y = -1; y <= 1; ++y) {
            for(int x = -1; x <= 1; ++x) {
                vec2 neighbor = vec2(float(x), float(y)); // Direction in which neighbor cell lies
                vec2 point = random1(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec2 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    
    return minDist;
}

float WorleyNoise2(vec2 uv) {
    const float dimen = 10.0; // dimension
    uv[0] *= dimen;
    float ratio = resolution.y / resolution.x;
    uv[1] *= dimen * ratio; // Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0; // Minimum distance initialized to max.
        
        for(int y = -1; y <= 1; ++y) {
            for(int x = -1; x <= 1; ++x) {
                vec2 neighbor = vec2(float(x), float(y)); // Direction in which neighbor cell lies
                vec2 point = random2(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec2 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    
    return minDist;
}

float WorleyNoise3(vec2 uv) {
    const float dimen = 8.0; // dimension
    uv[0] *= dimen;
    float ratio = resolution.y / resolution.x;
    uv[1] *= dimen * ratio; 
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0; // Minimum distance initialized to max.
        
        for(int y = -1; y <= 1; ++y) {
            for(int x = -1; x <= 1; ++x) {
                vec2 neighbor = vec2(float(x), float(y)); // Direction in which neighbor cell lies
                vec2 point = random2(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec2 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    
    return minDist;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec2 uvInt;
    vec2 temp = vec2(0., 2.);
    vec3 col;
    float noise1 = WorleyNoise1(uv);
    float noise2 = WorleyNoise2(uv);
    float noise3 = WorleyNoise3(uv);
    float diam1 = 0.1 * (sin((time + 9.) * 0.5) / cos((time + 9.) * 0.5));
    float diam2 = 0.1 * (sin(time * 0.5) / cos(time * 0.5));
    float diam3 = 0.1 * (sin((time + 4.) * 0.5) / cos((time + 4.) * 0.5));
    float diam4 = 0.1 * (sin((time - 5.) * 0.5) / cos((time - 5.) * 0.5));
    
    float diam5 = 0.1 * (sin((time + 2.) * 0.5) / cos((time + 2.) * 0.5));
    float diam6 = 0.1 * (sin(time - 9. * 0.5) / cos(time - 9. * 0.5));

    if (noise1 >= diam1 && noise1 <= diam1 + 0.016) {
        col = vec3(1.0);
    } else {
        col = vec3(0.);
    }
    
    if (noise1 >= diam2 && noise1 <= diam2 + 0.015) {
        col += vec3(1.0);
    } else {
        col += vec3(0.);
    }
    
    if (noise2 >= diam3 && noise2 <= diam3 + 0.013) {
        col += vec3(1.0);
    } else {
        col += vec3(0.);
    }
    
    if (noise2 >= diam4 && noise2 <= diam4 + 0.014) {
        col += vec3(1.0);
    } else {
        col += vec3(0.);
    }
    
    if (noise3 >= diam5 && noise3 <= diam5 + 0.01) {
        col += vec3(1.0);
    } else {
        col += vec3(0.);
    }
    if (noise3 >= diam6 && noise3 <= diam6 + 0.01) {
        col += vec3(1.0);
    } else {
        col += vec3(0.);
    }
        
    // Output to screen
    col *= 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    glFragColor += vec4(col,1.0);
}
