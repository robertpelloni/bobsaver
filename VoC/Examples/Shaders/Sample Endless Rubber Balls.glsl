#version 420

// original https://www.shadertoy.com/view/ttV3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ground = -0.42;
float bounciness = 0.7;
float loopLength = 6.;
float bounceFrequency = 8.;
float ballCount = 20.;
float randomSeed = 5.;

vec2 uv; //assigned in main

float random(float val){
     return fract(sin(randomSeed+val*219142.349034753957)*54643.624304578);   
}
float randomT2(float val){
    return fract(sin(randomSeed+val*4386.48748530579)*95347.206309475);
}
float randomT3(float val){
    return fract(sin(randomSeed+val*5432.35609374583759)*26467.557573805);
}

float square(float value){
    return value*value;   
}

float ellipse(vec2 position, vec2 size){
    float t = square(uv.x-position.x)/square(size.x) + square(uv.y-position.y)/square(size.y);
    return smoothstep(1., 0.9, t);
}
float bouncingBall(float radius, float bounceWidth, float t){
    //Bouncing
    float potentialEnergy = pow(bounciness, t*bounceWidth); //bounciness determines how much energy is lost in each bounce
    float bounce = abs(sin(t*3.141*bounceWidth))*potentialEnergy; //a sine wave that shortens each half oscillation
    float bounceOffset = (-radius/2.)*potentialEnergy; //based on potentialEnergy the center can get closer to the ground
    vec2 currentPos = vec2(-1.2+2.4*t, ground+radius+bounce+bounceOffset);
    
    //The ball squishes to never overlap the ground
    float compression = min(1., abs(ground - currentPos.y)/radius); //distance to ground / radius
    vec2 deform = vec2(max(1., 1.+0.9*(1.-compression)), min(1., compression)); 
    
    return ellipse(currentPos, radius*deform);
}
vec4 randomBall(float i){
     float time = mod(time + randomT2(i+2.)*loopLength, loopLength)/loopLength; //random offset to avoid overlap, and make them loop
    
    i = i+random(floor((time + randomT2(i+2.)*loopLength)/loopLength)); //i changes with every loop
    vec4 randomColor = vec4(random(i+1.), randomT2(i+1.), randomT3(i), 1.);
    randomColor.rgb = 0.9*randomColor.rgb + 0.1; //lightens it up my making the minimum vec3(0.1)
    float mask = bouncingBall(random(i)*0.1+0.1, (randomT2(i)*0.75 + 0.25)*bounceFrequency, time);
    return mask * randomColor;
}

void main(void)
{
    uv = gl_FragCoord.xy/resolution.xy - 0.5;
    float aspectRatio = resolution.x/resolution.y;
    uv.x *= aspectRatio;

    vec4 col = vec4(0.);
    for(float i = 1.; i <= ballCount; i+=1.){
        col += randomBall(i) * (1.-col.a);
    }
    
    //col += vec4(max(0., 1.-floor(length(uv)+0.995))); //shows the origin
    col.xyz += vec3(smoothstep(0., 0.01, ground - uv.y)); //the ground
    
    glFragColor = col;
}
