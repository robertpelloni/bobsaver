#version 420

// original https://www.shadertoy.com/view/fsKSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159;

float sdCircle(vec2 st, float r) { 
return length(st) - r; 
} 

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float stroke(float x, float w){ 
    w *= .5; 
    return 1.-smoothstep(w-.01,w+.01,abs(x)); 
} 

float fill(float sdf){
    return 1.-smoothstep(-.01,.01,sdf);
}

mat2 rotate2d(float angle){ 
    mat2 rot = mat2(cos(angle),-sin(angle), sin(angle),cos(angle)); 
    return rot; 
} 

void main(void)
{
    vec3 col = vec3(.4);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    uv = (uv-vec2(1.,.5)) * rotate2d(time * .25);
    uv = fract(uv);
    float zoomMod = 6.;
    uv *= zoomMod;
    
    float timeIndex = mod(time * 1.5, zoomMod);
    for (int i = 0; i < 6; i++){
        float j = float(i);
        float rowIndex = step(j,uv.y) * 1.-step(j+1.,uv.y);
        float colIndex = step(j,uv.x) * 1.-step(j+1.,uv.x);
        
        if (floor(timeIndex) < 3.) {
            if (j == floor(timeIndex)) {
                uv.x += rowIndex * -mod(timeIndex,1.);
            }
            if (mod(j+2.,zoomMod) == floor(timeIndex)) {
                uv.x += rowIndex * mod(timeIndex,1.);
            }
        } else {
            if (j == floor(timeIndex)) {
                uv.y += colIndex * -mod(timeIndex,1.);
            }
            if (mod(j+2.,zoomMod) == floor(timeIndex)) {
                uv.y += colIndex * mod(timeIndex,1.);
            }
        }
    }
    
    vec2 st = (fract(uv)-.5)*2.;
    
    float turnMod = PI * .5;
    for (int i = 0; i < 6; i++){
        float j = float(i);
        float rowIndex = step(j,uv.y) * 1.-step(j+1.,uv.y);
        float colIndex = step(j,uv.x) * 1.-step(j+1.,uv.x);
    
        if (floor(timeIndex) < 3.) {
            if (j == floor(timeIndex)) {
                st = st * rotate2d(mod(timeIndex,1.) * turnMod * rowIndex);
            }
            if (mod(j+2.,zoomMod) == floor(timeIndex)) {
                st = st * rotate2d(-mod(timeIndex,1.) * turnMod * rowIndex);
            }
        } else {
            if (j == floor(timeIndex)) {
                st = st * rotate2d(mod(timeIndex,1.) * turnMod * colIndex);
            }
            if (mod(j+2.,zoomMod) == floor(timeIndex)) {
                st = st * rotate2d(-mod(timeIndex,1.) * turnMod * colIndex);
            }
        }
    }
    
    float ring = abs(sdCircle(st, .4))-.12;
    for(int i = 0; i < 8; i++){
        float j = float(i);
        st = st * rotate2d(PI*.25);
        float square = sdBox(st-vec2(0.,.48),vec2(.07,.1))-.1;
        ring = min(ring, square);
    }
    
    col += fill(ring);
    col = mix(col,vec3(.05),stroke(ring,.1));
    glFragColor = vec4(col,1.0);
}
