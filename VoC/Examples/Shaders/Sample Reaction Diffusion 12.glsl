#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

bool inCircle(vec2 position, vec2 offset, float size) {
    float len = length(position*vec2(1.0,resolution.y/resolution.x) - offset*vec2(1.0,resolution.y/resolution.x));
    if (len < size) {
        return true;
    }
    return false;
}

vec2 tex(vec2 uv)
{
    return texture2D(backbuffer, uv).xy;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void ) {

    vec2 uv =  ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel = 1./resolution;

    vec2 cp = tex(uv).xy;
    
    vec2 lap = vec2(0.0, 0.0); 
    lap =
        0.05 * tex(uv + pixel * vec2(-1,  -1)).xy +
        0.20 * tex(uv + pixel * vec2(0, -1)).xy +
        0.05 * tex(uv + pixel * vec2(1, -1)).xy +
        
        0.20 * tex(uv + pixel * vec2(-1, 0)).xy +
        -1.0 * tex(uv + pixel * vec2(0,  0)).xy +
        0.20 * tex(uv + pixel * vec2(1, 0)).xy +
        
        0.05 * tex(uv + pixel * vec2(-1, 1)).xy +
        0.20 * tex(uv + pixel * vec2(0, 1)).xy +
        0.05 * tex(uv + pixel * vec2(1, 1)).xy;
    
    float dA = 1.0;
    float dB = 0.35;
    float f = 0.0355 * (fract(mouse.x) *0.2+0.8);
    float k = 0.0621 * (fract(mouse.y)*0.2+0.8);
    
    //f=.0367, k=.0649
    
    vec2 col = vec2(0);
    col.x = cp.x + (dA * lap.x) - (cp.x * cp.y * cp.y) + (f * (1.0 - cp.x));
        col.y = cp.y + (dB * lap.y) + (cp.x * cp.y * cp.y) - ((k + f) * cp.y); 
    
    if (inCircle (uv, vec2(rand(vec2(time*2.0,time*3.3)),rand(vec2(time*4.0,time*3.0))), 0.03*rand(vec2(time*4.0,0)))) {
        col.y+=0.2;
        }

    glFragColor.x = clamp(col.x, 0.0, 1.0);  
    glFragColor.y = clamp(col.y, 0.0, 1.0);          
    glFragColor.z =  step(col.y,0.5);
    glFragColor.w = 1.0;
    

}
