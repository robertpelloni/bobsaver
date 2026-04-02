#version 420

//---------------------------------------------------------
// UNIFORMS
//---------------------------------------------------------

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//---------------------------------------------------------
// DEFINES
//---------------------------------------------------------

#define NONE         0.0
#define EARTH        0.1
#define FIRE         0.2
#define WATER        0.3
#define HOT_EARTH     0.4

vec2 pos, uv, uvUnit;
float r, g, b;

float circle (vec2 center, float radius) {
  return distance(center, pos) < radius ? 1.0 : 0.0;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float heat(vec2 p) {
    float totalHeat = 0.0;
    
    #define STEP 2
    for (int x = -STEP; x <= STEP; x++) {
        for (int y = -STEP; y <= STEP; y++) {
            vec2 testP = vec2(uv.x + float(x)*uvUnit.x, uv.y + float(y)*uvUnit.y);
            totalHeat += texture2D(backbuffer, testP).r;
        }
    }
    return totalHeat / float(STEP * STEP);
}

vec4 s(float x, float y) {
    return floor(texture2D(backbuffer, vec2(uv.x + x * uvUnit.x, uv.y + y * uvUnit.y)) * 10.0 + 0.5) / 10.0;
}

void main(void) {
    float aspect = resolution.x/resolution.y;
      uv = gl_FragCoord.xy / resolution.xy;
    uvUnit = 1.0 / resolution.xy;
      pos = (uv-0.5);
      pos.x *= aspect;
    vec2 pmouse = mouse - vec2(0.5);
    pmouse.x *= aspect;
    
    // Matrix of previous land samples
    mat3 lm = mat3(    s(1.0,  1.0).a, s(0.0,  1.0).a, s(-1.0,  1.0).a,
            s(1.0,  0.0).a, s(0.0,  0.0).a, s(-1.0,  0.0).a,
            s(1.0, -1.0).a, s(0.0, -1.0).a, s(-1.0, -1.0).a
               );
    
    // Center of matrix is current land sample
    float land = lm[1][1];
    
    // Add some fire in the center
    if (circle(vec2(0.0, 0.0), 0.05) == 1.0) {
        land = FIRE;
    }
    
    // Add some land at the mouse
    land = circle(pmouse, 0.02) == 1.0 ? EARTH : land;
    
    if (land == NONE) {
        // Become fire if fire is below it
        if (lm[2][1] == FIRE) {
            land = FIRE;
        }
    }
    
    if (land == FIRE) {
        // Decay over time
        land = rand(uv*time) > 0.6 ? NONE : land;
    }
    
    if (land == WATER) {
        
    }
    
    if (land == EARTH) {
        bool bottomRow = lm[2][1] == FIRE || lm[2][0] == FIRE || lm[2][2] == FIRE;
        bool sideRow = lm[1][1] == FIRE || lm[1][0] == FIRE || lm[1][2] == FIRE;
        bool topRow = lm[0][1] == FIRE || lm[0][0] == FIRE || lm[0][2] == FIRE;
        if (bottomRow || sideRow || topRow) {
            land = HOT_EARTH;
        }
    }
    
    if (land == HOT_EARTH) {
        if (rand(uv*time) > 0.9) {
            land = FIRE;
        }
    }
    
    // Clear
    //land = NONE;
    
    vec3 colorOut = vec3(0.0, 0.0, 0.0);
    
    if (land == FIRE) {
        colorOut.r = 1.0;
    } else if (land == EARTH) {
        colorOut.g = 1.0;
    } else if (land == WATER) {
        colorOut.b = 1.0;
    } else if (land == HOT_EARTH) {
        colorOut = vec3(0.7, 0.4, 0.0);    
    }
    
    glFragColor = vec4(colorOut, land);
}
