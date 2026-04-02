#version 420

// original https://www.shadertoy.com/view/XtGcWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float y){
    return fract(sin(y)*100.123);
}

float fade(float t){
    return t*t*t*(t*(t*6.-15.)+10.);
}

float noise1(float x){
   
    float s = floor(x);
    float e = fade(fract(x));
    
    return mix(
        mix(hash(s),hash(s-1.),e),
        mix(hash(s-1.),hash(s+1.),e),
        e
    );
}
    

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    
    float speed = 0.8;
    float y = noise1(gl_FragCoord.x*0.001 + time*speed);
    float y2 = noise1(gl_FragCoord.x*0.001 + time *speed*0.8);
    float y3 = noise1(gl_FragCoord.x*0.001 + time*speed*0.6);
    float y4 = noise1(gl_FragCoord.x*0.001 + time*speed*0.4);
    vec3 col = vec3(1.);
    
    
    col = vec3( pow(1.-distance(uv.y,y) ,10.) )*vec3(.9,.2,.3);
    col += vec3( pow(1.-distance(uv.y,y2) , 10.) )*vec3(.2,.9,.3);
    col += vec3( pow(1.-distance(uv.y,y3) , 10.) )*vec3(.4,.5,.9);
    col += vec3( pow(1.-distance(uv.y,y4) , 10.) )*vec3(.7,.4,.3);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
