#version 420

// original https://www.shadertoy.com/view/slB3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SHAPE_AMOUNT 100.
#define SHAPE_SIZE 0.06
#define BLUR 0.001
#define VERTICAL_TRAVEL 0.1
#define SPEED_TRAVEL 0.6
#define SPEED_ROTATION 1.

// Only applies to the circle and square
#define INNER_CUTOUT_SCALE 0.7

// Colors
#define DARK_BLUE vec3(16./255.,50./255.,66./255.)
#define LIGHT_BLUE vec3(34./255.,76./255.,114./255.)
#define SHAPE_GRAY vec3(93./255.,119./255.,137./255.)

// The taper-off point for the triangle to be equilateral
const float EQUILATERAL_HEIGHT =
        sqrt(pow(SHAPE_SIZE,2.) - pow(SHAPE_SIZE/2.,2.))
        - SHAPE_SIZE/2.;

// Helper functions grabbed from the internet
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233)))
        *43758.5453);
}

// https://gist.github.com/companje/29408948f1e8be54dd5733a74ca49bb9
float map(float value, float min1, float max1,
        float min2, float max2) {
    return min2 + (value - min1)*(max2 -min2)
        /(max1 - min1);
}

mat2 rotate(float angle) {
    return mat2(cos(angle),-sin(angle),
        sin(angle),cos(angle));
}

// Background gradient
vec3 background(vec2 uv) {
    const float GRAD_START = 0.25, GRAD_STOP = 0.95;
    return mix(LIGHT_BLUE,DARK_BLUE,
        smoothstep(GRAD_START,GRAD_STOP,uv.y));
}

// Solid helper shapes
float box(vec2 uv, float left, float right,
        float down, float up, float blur) {
    return smoothstep(left,left+blur,uv.x)
        *smoothstep(right,right-blur,uv.x)
        *smoothstep(down,down+blur,uv.y)
        *smoothstep(up,up-blur,uv.y);
}

float box(vec2 uv, float lowerBound, float upperBound,
        float blur) {
    return box(uv,lowerBound,upperBound,
               lowerBound,upperBound,blur);
}

float triangleSolid(vec2 uv, float size, float height,
        float blur) {
    float sides = map(uv.y,-size/2.,height,size/2.,0.);
    return box(uv,-sides,sides,-size/2.,size/2.,blur);    
}

// Main shapes
float circle(vec2 uv, float size, float blur) {
    float radius = size/2.;
    return smoothstep(radius+blur,radius,length(uv))
        - smoothstep(INNER_CUTOUT_SCALE*radius+blur,
                     INNER_CUTOUT_SCALE*radius,
                     length(uv));
}

float X(vec2 uv, float size, float blur) {
    float lower = -size/2., upper = size/2.;
    return box(uv,lower,upper,lower/5.,upper/5.,blur)
        + box(uv,lower/5.,upper/5.,lower,upper,blur)
        - box(uv,lower/5.,upper/5.,blur);
}

float triangle(vec2 uv, float size, float height,
        float blur) {
    vec2 innerCoord = uv*2.;
    const float BASE_SIZE = 0.05, SCALING_FACTOR = 0.01;
    innerCoord.y += SHAPE_SIZE/BASE_SIZE*SCALING_FACTOR;
    return triangleSolid(uv,size,height,blur)
        - triangleSolid(innerCoord,size,height,blur);
}

float square(vec2 uv, float size, float blur) {
    return box(uv,-size/2.,size/2.,blur)
        - box(uv,-INNER_CUTOUT_SCALE*size/2.,
              INNER_CUTOUT_SCALE*size/2.,blur);
}

vec2 sway(vec2 uv, vec2 start, float vertTravel,
        float timeShift) {
    return vec2(uv.x-start.x,uv.y-start.y
                - vertTravel*sin(SPEED_TRAVEL
                                 *time-timeShift)
                - vertTravel/2.);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float ASPECT_RATIO = resolution.x/resolution.y;
    uv.x *= ASPECT_RATIO;

    vec3 col = background(uv);

    for(float i = 0.; i < SHAPE_AMOUNT; i++) {
        vec2 seed = vec2(i,i);
        vec2 cord = vec2(rand(seed),rand(-.5*seed));
        cord.x *= ASPECT_RATIO;
        vec2 xy = sway(uv,cord,VERTICAL_TRAVEL,i);
        switch(int(mod(i,4.))) {
            case 0:
                xy *= rotate(sin(SPEED_ROTATION*time-i));
                col = mix(col,SHAPE_GRAY,
                          X(xy,SHAPE_SIZE,BLUR));
                break;
            case 1:
                col = mix(col,SHAPE_GRAY,
                          circle(xy,SHAPE_SIZE,BLUR));
                break;
            case 2:
                xy *= rotate(sin(SPEED_ROTATION*time-i));
                col = mix(col,SHAPE_GRAY,
                          triangle(xy,SHAPE_SIZE,
                                   EQUILATERAL_HEIGHT,
                                   BLUR));
                break;
            case 3:
            default:
                xy *= rotate(sin(SPEED_ROTATION*time-i));
                col = mix(col,SHAPE_GRAY,
                          square(xy,SHAPE_SIZE,BLUR));
                break;
        }
    }
    glFragColor = vec4(col,1.0);
}
