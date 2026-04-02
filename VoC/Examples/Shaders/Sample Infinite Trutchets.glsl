#version 420

// original https://www.shadertoy.com/view/lfyXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main(void)
{
    float time = mod(-time, 2.0);
    
    float sizeFactor = 0.875/8.0 + pow(0.875/8.0+time*3.275/8.0, 2.0);
    
    vec2 umTileDimensions = vec2(2.0, 1.125);
    vec2 mTileDimensions = umTileDimensions*8.0;
    vec2 tileDimensions = mTileDimensions*8.0;
    vec2 tinyDimensions = tileDimensions*8.0;
    
    vec2 tileMetaRatio = tileDimensions/mTileDimensions;
    vec2 uMetaRatio = mTileDimensions/umTileDimensions;

    vec2 absUV = gl_FragCoord.xy/resolution.xy;
    vec2 uv = gl_FragCoord.xy*sizeFactor/resolution.xy;
    vec2 tinyTile = floor(uv*tinyDimensions);
    vec2 tile = floor(uv*tileDimensions);
    vec2 metaTile = floor(uv*mTileDimensions);
    vec2 uMetaTile = floor(uv*umTileDimensions);
    
    vec2 tinyUV = vec2(mod(uv.x*tinyDimensions.x, 1.0), mod(uv.y*tinyDimensions.y, 1.0));
    vec2 localUV = vec2(mod(uv.x*tileDimensions.x, 1.0), mod(uv.y*tileDimensions.y, 1.0));
    vec2 localTile = vec2(mod(uv.x*mTileDimensions.x, 1.0), mod(uv.y*mTileDimensions.y, 1.0));
    vec2 localMetaTile = vec2(mod(uv.x*umTileDimensions.x, 1.0), mod(uv.y*umTileDimensions.y, 1.0));  
    
    vec3 col = vec3(1.0);
    vec3 lineCol = 0.5 + 0.5*cos(time+absUV.xyx+vec3(0,2,4));
    
    if (random(uMetaTile) <= 0.5) {
        localMetaTile.x = 1.0-localMetaTile.x;
    }
    if (random(metaTile) <= 0.5) {
        localTile.x = 1.0-localTile.x;
    }
    if (random(tile) <= 0.5) {
        localUV.x = 1.0-localUV.x;
    }
    if (random(tinyTile) <= 0.5) {
        tinyUV.x = 1.0-tinyUV.x;
    }
    if (abs(localMetaTile.x - localMetaTile.y) <= 0.25 || abs(localMetaTile.x - localMetaTile.y) >= 0.75 
        && (metaTile.x > 2.0 || metaTile.y > 2.0)) {
        lineCol *= 0.75+0.25*(1.0-smoothstep(0.0, 2.0, time));
    } else if (abs(localTile.x - localTile.y) <= 0.25 || abs(localTile.x - localTile.y) >= 0.75 
        && (tile.x > 2.0 || tile.y > 2.0)) {
        lineCol *= 0.5+0.25*(1.0-smoothstep(0.0, 2.0, time));
    } else if ((abs(localUV.x - localUV.y) <= 0.25 || (abs(localUV.x - localUV.y) >= 0.75) 
        && (uv.x >= 0.002 || uv.y >= 0.004))) {
        lineCol *= 0.25+0.25*(1.0-smoothstep(0.0, 2.0, time));
    } else if ((abs(tinyUV.x - tinyUV.y) <= 0.25 || (abs(tinyUV.x - tinyUV.y) >= 0.75) 
        && (uv.x >= 0.0002 || uv.y >= 0.0004))) {
        lineCol *= 0.25*(1.0-smoothstep(0.0, 2.0, time));;
    } else {
        lineCol *= 0.0;
    }
    col = lineCol;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
