#version 420

// original https://www.shadertoy.com/view/ldtXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define animSpeed 0.05

//-----------------------------------------------------------------------------
// Crater in -1.0 to 1.0 space
float crater(in vec2 pos) {
    float len = length(pos);
    float pi = 3.1415926535;
    float x = clamp(pow(len, 4.0) * 8.0, pi*0.5, pi*2.5);
    float t = clamp(len, 0.0, 1.0);
    return sin(-x) + 0.5 - 0.5 * cos(t * pi);
}

//-----------------------------------------------------------------------------
vec2 pseudoRand(in vec2 uv) {
    // from http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
    float noiseX = (fract(sin(dot(uv, vec2(12.9898,78.233)      )) * 43758.5453));
    float noiseY = (fract(sin(dot(uv, vec2(12.9898,78.233) * 2.0)) * 43758.5453));
    return vec2(noiseX, noiseY);}

//-----------------------------------------------------------------------------
float repeatingCraters(in vec2 pos, in float repeat, in float scaleWeight) {
    vec2 pos01 = fract(pos * vec2(repeat));
    vec2 index = (pos * vec2(repeat) - pos01) / repeat;
    vec2 scale = pseudoRand(index);
    float craterY = crater(vec2(2.0) * (pos01 - vec2(0.5)));
    return mix(1.0, pow(0.5*(scale.x + scale.y), 4.0), scaleWeight) * craterY; 
}

//-----------------------------------------------------------------------------
float getY(in vec2 pos) {    
    float y = 0.5;
    for(int i=0;i<int(100);++i) {
        float f01 = float(i) / float(99.0);
        float magnitude = pow(f01, 2.3);
        vec2 offs = pseudoRand(vec2(float(i+2), pow(float(i+7), 3.1)));
        float repeat = 0.5 / (magnitude + 0.0001);

        y += magnitude * repeatingCraters(pos+offs, repeat, 1.0);
    }
    
    return y;
}

//-----------------------------------------------------------------------------
void main(void) {
    vec2 pos = (gl_FragCoord.xy - resolution.xy*0.5) / vec2(resolution.y);
    pos += vec2(1.0); // avoid negative coords

    vec2 offs = vec2(0.001, -0.001);
    
    pos.x += time * animSpeed;
    pos.y -= time * animSpeed * 0.25;
    
    float y = getY(pos);
    float y1 = getY(pos - offs);
    //float y2 = getY(pos + offs);

    vec3 normal = normalize(vec3(0.01, y-y1, 0.01));

    float d = 0.5 + 0.5 * dot(normal, normalize(vec3(2.0, 1.0, 2.0)));
    
    float shadeScale = 1.0;

    /*
    // shadows
    {
        
        for(int i=0;i<int(40);++i) {
            float f01 = float(i+1) / float(40.0);
            f01 = pow(f01, 2.0);

            vec2 posTest = pos - vec2(f01, -f01) * 0.5;

            float yTest = getY(posTest);

            float over = yTest - (y + f01 * 3.0);
            
            if(over > 0.0)
                shadeScale = min(shadeScale, mix(1.0, 0.7, clamp(over*0.5,0.0,1.0)));
        }
    }
    
    d *= shadeScale;
    */

    float c = y * 0.02 - 0.5 + d * 1.3;

    // color ramp
    vec3 rgb = vec3(mix(mix(vec3(0.0,0.0,0.0), vec3(0.8,0.6,0.4), c), vec3(1.0,0.95,0.90), c));
    
    glFragColor = vec4(rgb,1.0);
}

