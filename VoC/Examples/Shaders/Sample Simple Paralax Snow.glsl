#version 420

// original https://www.shadertoy.com/view/MdXcW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define cc vec2(0.5,0.5)
#define smoothness 1.0
#define SNOW_COL vec4(1.0,1.0,1.0,1.0)
#define N_LAYERS 10.0
#define SNOW_ALPHA 1.0
#define SPEED 0.3
#define bg vec4(0.8,0.8,0.9,1.0)

float smoothCircle(vec2 position,float relativeSize){
    float d = distance(cc,position)*2./relativeSize;
    if (d > 1.0){
        return 0.0;
    }
    else{
        return clamp(smoothness/d-smoothness,-1.0,1.0);
    }
}

// fake random stolen from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float randF(float n){
    return fract(sin(n) * 43758.5453123);
}

// used to determine whether to draw a flake in the grid
// the magic number is just me mashing the keyboard
bool rand2d(float i, float j, float probability){
    return  (randF(i + j*7.8124861) > probability);
}

// create the grid of circles, with a bunch missing, and fanaggle the sizes a bit
float circleGrid(vec2 position, float spacing, float dotSize){
    
    // idx => which dot we are showing in the grid.
    
    // check x and y index to see if we should draw it or not.
    float idx = floor(1./spacing * position.x);
    float yIdx = floor(1./spacing * position.y);

    // much higher than .06 causes the grid to be obvious
    if (rand2d(idx,yIdx,0.06)){
        return 0.0;
    }
    
    // modify the size of the flake a bit
    float relativeSize = (0.5 + 0.5*randF(yIdx))*dotSize / spacing;
    
    return smoothCircle(vec2(
        fract(1./spacing*position.x),
        fract(1./spacing*position.y + yIdx)
    ),relativeSize);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 uvsq = vec2(uv.x* resolution.x/resolution.y,uv.y);
    float amnt = 0.0;
    
    float rotX = 0.0;
    float rotY = 0.0;
    rotX = -2.0*mouse.x*resolution.xy.x / resolution.x;
    rotY = -2.0*mouse.y*resolution.xy.y / resolution.y;
    
    
    for (float i = 0.0; i < N_LAYERS; i ++){
        float p = 0.5 + ((i+1.) / N_LAYERS)*0.4;
        // small flakes in bg drawn first with lower speed
        
        // the only reason we add "i" is so it tweaks the noise called on this position later.
        vec2 fallPosition = vec2(
            rotX * (1.0-p) + uvsq.x + i + p*sin(time/2.+i)/4.*SPEED,
            rotY * (1.0-p) + i * 3.0 + uvsq.y + time*p/1.*SPEED
        );
        amnt = amnt + SNOW_ALPHA * circleGrid(fallPosition, 0.06* p, 0.04* p*p); 
    }
    
    glFragColor = mix(SNOW_COL,bg,1.0-amnt);
    
}
