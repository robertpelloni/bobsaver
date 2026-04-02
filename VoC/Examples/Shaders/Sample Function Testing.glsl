#version 420

// original https://www.shadertoy.com/view/XscBz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Working through https://thebookofshaders.com/05/
#define pi 3.14159265359

float plot(vec2 uv, float pct) {
    return smoothstep( pct - 0.02, pct, uv.y ) -
           smoothstep( pct, pct + 0.02, uv.y );
}

float step2(float a, float b, float v) {
    return step(a,v) - step(b,v);    
}

float smoothstep2(float a, float b, float w, float v) {
    return smoothstep(a-w, a, v) - smoothstep(b, b+w, v);
}

float sqr(float x) { return x*x; }

vec2 tile(vec2 uv, float scale) { return fract(uv*scale); }

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float t = time;
    
    // How many tiles we want to create.
    float tiles = 6.;
    
    // Get the integer part of our tiled coordinates
    vec2 uvIntPart; modf(tiles * uv, uvIntPart);
    
    // Get the index for the tile [0, ..., tiles]
    int tileIndex = int(uvIntPart.y * tiles + uvIntPart.x);
    
    // Get normalized coordinates [0, 1] for each tile.
    vec2 coord = tile(uv, tiles);
    
    // Function x, y
    float x, y; x = coord.x; 

    // Select each tile to render a different function.
    switch(tileIndex) {
        // Basic functions
        case 0: y = x;                                break;
        case 1: y = sqr(x);                         break;
        case 2: y = sqrt(x);                        break;
        case 3: y = log(x) + 1.;                     break;
        case 4: y = pow(x, 5.);                        break;
        case 5: y = .5*sin(x * pi * 2.) + .5;         break;
        
        // Other functions
        case 6: y = fract(3.*x);                     break;
        case 7: y = ceil(5.*x)/5.;                  break;
        case 8: y = floor(5.*x)/5.;                  break;
        case 9: y = atan(x*pi/2.);                     break;
        case 10: y = asin(x*pi/4.);                    break;
        case 11: y = 1.-sqr(x);                     break;
        
        // Step examples
        case 12: y = step(.5,x);                    break;
        case 13: y = step(.4,x) - step(.6,x);         break;
        case 14: y = x * step2(.4, .6, x);            break;
        case 15: y = step2(.0, .2, fract(4.*x));    break;
        case 16: y = x * step2(.0, .2, fract(4.*x));break;
        case 17: y = sin(x*pi) 
                 * (1.-step(.2, fract(12.*x)))
              + 0.2 * (step2(.2, 1., fract(12.*x)));break;
        
        // Smoothstep examples
        case 18: y = smoothstep(.0,1.,x);             break;
        case 19: y = smoothstep2(.4,.6,.2,x);         break;
        case 20: y = x * smoothstep2(.4,.6,.1,x);    break;
        case 21: y = x * smoothstep2(fract(4.*x), 
                                     fract(4.*x+0.1)
                                     , 0.2, x);     break;
        //case 22: y = 0.5 * smoothstep2(mod(4.*x,.5),
        //                              mod(4.*x+0.1,.5)
        //                              , 0.2, x)+.2;    break;
        
        // Clamp examples
        case 24: y = clamp(x,0.,1.);                 break;
        case 25: y = clamp(x,.5,1.);                 break;
        case 26: y = clamp(x,0.,.5);                 break;
        case 27: y = 1.-clamp(x,.5,1.);             break;
        case 28: y = 1.-clamp(x,0.,1.);                break;
        
        // Misc. examples
        case 30: y = fract(sin(x*pi*4.));             break;
        case 31: y = fract(abs(sin(x*pi*4.)));         break;
        case 32: y = mod(x, .25);                     break;
        case 33: y = sin(x*pi);                        break;
        case 34: y = 0.5 + .05 * ( sin(29.*x+8.*t)
                                    + sin(38.*x+8.*t) 
                                   + sin(17.*x+8.*t));break;
    }
    
    // Set color
    vec3 col = vec3(y);
    
    // Line
    float pct = plot(coord, y);
    col = (1.0-pct)*col+pct*vec3(0,1,0);
    
    // Grid
    float gridWidth = 0.01;
    col = mix(col, vec3(0), 1.-step(gridWidth, coord.x));
    col = mix(col, vec3(0), 1.-step(gridWidth, coord.y));
   
    // Output to screen
    glFragColor = vec4(col,1.0);
}
