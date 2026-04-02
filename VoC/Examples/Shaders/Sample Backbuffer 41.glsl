#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float aVoid = 0.9;
float aWire = 0.8;
float aGrowL = 0.7;
float aGrowR = 0.6;
float aGrowU = 0.5;
float aGrowD = 0.4;

bool is(vec4 px, float material) {
    // Test for specific material
    return (abs(px.a - material) < 0.045);
}

vec4 px(int dx, int dy) {
    // Fetch pixel RGBA at relative location
    vec2 pos = vec2(gl_FragCoord.x - float(dx), gl_FragCoord.y - float(dy));
    if ((pos.x < 0.0) || (pos.y < 0.0) || (pos.x >= resolution.x) || (pos.y >= resolution.y)) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    return texture2D(backbuffer, pos / resolution);
}

float rand(int seed) {
    // Random float based on time, location and seed
    return fract(sin(time*23.254 + float(seed)*438.5345 - gl_FragCoord.x*37.2342 + gl_FragCoord.y * 73.25423)*3756.234);
}

bool CanGo(int dx, int dy) {
    if (!is(px(dx, dy), aVoid)) {return false;}
    if (!is(px(dx*2, dy*2), aVoid)) {return false;}
    if (!is(px(dx+dy, dy+dx), aVoid)) {return false;}
    if (!is(px(dx-dy, dy-dx), aVoid)) {return false;}
    if (!is(px(dx*2+dy, dy*2+dx), aVoid)) {return false;}
    if (!is(px(dx*2-dy, dy*2-dx), aVoid)) {return false;}
    
    return true;
}

void main( void ) {
    vec2 position = gl_FragCoord.xy / resolution.xy;
    position -= 0.5;
    position.x *= resolution.x/resolution.y;

    // MAZE PROPERTIES
    float twistiness = 0.05;
    float branch_chance = 0.001;
    
    // Scan surroundings
    vec4 here = px(0,0);
    vec4 pxl = px(-1,0);
    vec4 pxr = px(1,0);
    vec4 pxu = px(0,1);
    vec4 pxd = px(0,-1);
    vec4 pxrd = px(1,-1);
    bool even = ((mod(gl_FragCoord.x, 2.0) < 1.0) && (mod(gl_FragCoord.y, 2.0) < 1.0));
    float centerX = floor(resolution.x/4.0)*2.0;
    float centerY = floor(resolution.y/4.0)*2.0;
    
    if (is(here, aWire) || is(here, aGrowL) || is(here, aGrowR) || is(here, aGrowU) || is(here, aGrowD)) {
        // existing path
        here.b = max(0.2, here.b - 1.1 / 255.0);
        glFragColor.rgb = here.rgb;
        glFragColor.a = aWire;
        if ((here.b == 0.2) && even && rand(5) < branch_chance) {
            float dir = rand(2);
            if (dir < 0.25) {
                if (CanGo(-1, 0)) {glFragColor.a = aGrowL;}
            } else if (dir < 0.5) {
                if (CanGo(0, -1)) {glFragColor.a = aGrowD;}
            } else if (dir < 0.75) {
                if (CanGo(1, 0)) {glFragColor.a = aGrowR;}
            } else {
                if (CanGo(0, 1)) {glFragColor.a = aGrowU;}
            }
        }
    } else if (is(pxr, aGrowL) || is(pxl, aGrowR) || is(pxu, aGrowD) || is(pxd, aGrowU)) {
        // growing path
        if (!even) twistiness = 0.0;

        float wGrowL = CanGo(-1, 0) ? (is(pxr, aGrowL) ? 1.0 : twistiness) : 0.0;
        float wGrowR = CanGo(1, 0) ? (is(pxl, aGrowR) ? 1.0 : twistiness) : 0.0;
        float wGrowD = CanGo(0, -1) ? (is(pxu, aGrowD) ? 1.0 : twistiness) : 0.0;
        float wGrowU = CanGo(0, 1) ? (is(pxd, aGrowU) ? 1.0 : twistiness) : 0.0;
        glFragColor.rgb = vec3(1.0, 0.9, 0.4);
        float max = wGrowL + wGrowR + wGrowD + wGrowU;
        if (max > 0.0) {
            float choice = rand(51) * max;
            if (choice < wGrowL) {
                glFragColor.a = aGrowL;
            } else if (choice < wGrowL + wGrowR) {
                glFragColor.a = aGrowR;
            } else if (choice < wGrowL + wGrowR + wGrowD) {
                glFragColor.a = aGrowD;
            } else {
                glFragColor.a = aGrowU;
            }
        } else {
            glFragColor.a = aWire;
        }

    } else {
        // Initialize
        if ( (floor(gl_FragCoord.x) == centerX+2.0) && (floor(gl_FragCoord.y) == centerY) ) {
            glFragColor.rgb = vec3(1.0, 0.9, 0.4);
            glFragColor.a = aGrowL;
        } else if ( (floor(gl_FragCoord.x) == centerX-2.0) && (floor(gl_FragCoord.y) == centerY) ) {
            glFragColor.rgb = vec3(1.0, 0.9, 0.4);
            glFragColor.a = aGrowR;
        } else if ( (floor(gl_FragCoord.x) == centerX) && (floor(gl_FragCoord.y) == centerY+2.0) ) {
            glFragColor.rgb = vec3(1.0, 0.9, 0.4);
            glFragColor.a = aGrowD;
        } else if ( (floor(gl_FragCoord.x) == centerX) && (floor(gl_FragCoord.y) == centerY-2.0) ) {
            glFragColor.rgb = vec3(1.0, 0.9, 0.4);
            glFragColor.a = aGrowU;
        } else if (abs(floor(gl_FragCoord.x)-centerX) + abs(floor(gl_FragCoord.y)-centerY) <= 1.0) {
            glFragColor.rgb = vec3(1.0, 0.9, 0.4);
            glFragColor.a = aWire;
        } else {
            // empty green
            glFragColor.rgb = vec3(0.25, 0.4, 0.2);
            if (! is(pxr, aVoid)) {glFragColor.rgb *= 0.9;}
            if (! is(pxd, aVoid)) {glFragColor.rgb *= 0.9;}
            if (! is(pxrd, aVoid)) {glFragColor.rgb *= 0.9;}
            glFragColor.a = aVoid;
        }
    }
}
