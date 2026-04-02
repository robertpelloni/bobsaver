#version 420

// original https://www.shadertoy.com/view/WdXfRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Research for http://senin.world
// Idea: https://youtu.be/hsA1UfGwIHs?t=828

#define PI 3.141592653589793

// Maticals core functions
float box_sin(float angle){
    if(angle < 0.)
        angle = -1. * ( - PI * 2. - angle);
    angle = mod(angle, PI * 2.);
    
    if(angle <= PI * 0.75)
        return min(angle / (PI * 0.25), 1.);
 
    if(angle <= PI * 1.75)
        return max(-1., 1. - (angle - PI * 0.75) / (PI * 0.25));
    
    if(angle <= PI * 2.)
        return -1. + (angle - PI * 1.75) / (PI * 0.25);

    return 0.;
}

float box_cos(float angle){
    if(angle < 0.)
        angle = -1. * ( - PI * 2. - angle);
    angle = mod(angle, PI * 2.);

    if(angle <= PI * 0.25)
        return 1.;
    if(angle <= PI * 0.75)
        return 1. - (angle - PI * 0.25) / (PI * 0.25);
    if(angle <= PI * 1.25)
        return -1.;
    if(angle <= PI * 1.75)
        return -1. + (angle - (PI * 1.25)) / (PI * 0.25);
    if(angle <= PI * 2.)
        return 1.;

    return 0.;
}

float ms_angle(float angle){
    if(angle < 0.)
        angle = -1. * ( - PI * 2. - angle);
    angle = mod(angle, PI * 2.);

    if(angle <= PI * 0.5)
        return angle / (PI * 0.5);
    
    if(angle <= PI * 1.5)
        return 1. - (angle - PI * 0.5) / (PI * 0.5);
    
    if(angle <= PI * 2.)
        return -1. + (angle - PI * 1.5) / (PI * 0.5);

    return 0.;
}

// From 0 to 2 PI
float GetAngle(vec2 point){
    if(point.y >= 0.)
        if(point.x > 0.)
            return atan(point.x / point.y);
        else
            return atan(-point.y / point.x) + PI * 1.5;
    else
        if(point.x > 0.)
            return atan(-point.y / point.x) + PI * .5;
        else
            return atan(point.x / point.y) + PI;
}

float addVawe(float v, float m){
    return 1. + v * m;
}

// Flower structure
struct Flower{
    float count;
    float spin;
    //float scale;
};
    
Flower flo[] = Flower[](
    Flower(4., 2.),
    Flower(8., .5),
    Flower(8., -1.),
    Flower(16., -.5),
    Flower(16., 1.)//,
    //Flower(32., .5)
);

float allCall(int id, float v){
    switch(id){
        default:
        case 0: return sin(v);   
        case 1: return cos(v);
        case 2: return box_sin(v);
        case 3: return box_cos(v);
        case 4: return ms_angle(v);
    }
}

float allCall(float v){
    int id = int(mod(time * .5, 5.));
    float t = mod(time * .5, 1.);
    
    return allCall(id, v) * (1. - t) + allCall(id + 1, v) * t;    
}

// Configure it <--------------------------------------------- CONFIG Flowers type
// Use: sin, cos, box_sin, box_cos, ms_angle, allCall, any else.
#define FLOVER_CALL(v)    allCall(v)

// Mouse reaction: click to center

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uc = gl_FragCoord.xy/resolution.xy - 0.5;
    vec2 mc = mouse*resolution.xy.xy/resolution.xy - 0.5;
    
    // Configure it <--------------------------------------------------------------------- CONFIG Scale & color
    float gscale = 16. + 4.; // Global scale
    vec3 fcol = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4)); // Flowers color
    
    // Go
    float scale = 1.;
    vec3 col = vec3(0., 0., 0.);
    float opt = 1.;
    
    for(int i = 0; i < flo.length(); i ++){
        // Mouse reaction
        if(length(mc) <= 0.3)
            opt = sin(mod(time * flo[i].spin, PI * 2.));
        
        // Get angle
        float a = GetAngle(uc) - mod(time * flo[i].spin, PI * 2.);
        
        // Get len
        float fc = length(uc) * scale * gscale * opt; //(float(i) / float(flo.length()) * 1.);
    
        // Add vawe
        float v = addVawe(FLOVER_CALL(a * flo[i].count), .1);
    
        // Mult
        fc *= v;

        // Crop
          if(fc > 1.)
          fc = 1. - (fc - 1.) * 40.1;
        
        // Result color
        if(fc > 0.1)
            col = col + fcol * fc;
        
        // Next flower scale
        scale *= .6;        
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
