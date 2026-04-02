#version 420

// original https://www.shadertoy.com/view/3syXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float scale = 10.;

float circ(vec2 uv, float r){
    float d = length(uv);
    float c = smoothstep(d, (d+2.*scale/resolution.x), r);
    return c;
}

float circ2(vec2 uv, float r){
    float d = length(uv);
    float c = smoothstep(d-.4, (d+2.*scale/resolution.x), r- .2);
    return c;
}

float celticShit(vec2 uv){
    float r1 = .38;
    
    float r2 = .45;
    
    // used for Mix
    float c1 = circ(uv, r1);
    float c6 = circ2(uv, r1);
    
    // Add the following
    float c5 = circ(uv, r2);
    
    vec2 uvs = vec2(.5, -.288675);
    float c2 = circ(uv + uvs, r2);
    
    vec2 uvm = vec2(-.5, -.288675);
    float c3 = circ(uv + uvm, r2);
    
    vec2 uvv = vec2(0, .57735);
    float c4 = circ(uv + uvv, r2);
    
    float d = c5 - c2 - c3 - c4;
    d = d * c6;
   
    return mix(0., d, c1);

}

void main(void)
{

    // uv1
    vec2 uv1 = gl_FragCoord.xy/resolution.x;
    uv1.x *= 1.;
    uv1.y *= 1.155;
    uv1 *= scale;
    float m = mod(uv1.y, 2.);
    uv1.x += step(1., m)*.5;
    uv1 = fract(uv1);    
    uv1.y /= 1.155;
    uv1.x -=1.155/2.;
    uv1.y -=.5;
    
    
    
    // uv2
    vec2 uv2 = gl_FragCoord.xy/resolution.x;
    uv2.x *= 1.;
    uv2.y *= 1.155;
    uv2 *= scale;
    uv2.x -= .5;
    uv2.y -= .65/2.;
    float n = mod(uv2.y, 2.);
    uv2.x += step(1., n)*.5;
    uv2 = fract(uv2);    
    uv2.y /= 1.155;
    uv2.x -=1.155/2.;
    uv2.y -=.5;
    

    // uv3
    vec2 uv3 = gl_FragCoord.xy/resolution.x;
    uv3.x *= 1.;
    uv3.y *= 1.155;
    uv3 *= scale;
    uv3.x += 1.;
    uv3.y -= .65;
    float o = mod(uv3.y, 2.);
    uv3.x += step(1., o)*.5;
    uv3 = fract(uv3);    
    uv3.y /= 1.155;
    uv3.x -=1.155/2.;
    uv3.y -=.5;
    
    float f = celticShit(uv1);
    float g = celticShit(uv2);
    float h = celticShit(uv3);
    
    // Isolate f, g, h, to see ind. uv
    float i = f + g + h;
    

    // Output to screen
    glFragColor = vec4(i, i, i, 1.0);
    //glFragColor = vec4(f, 0, 0, 1.);
}
