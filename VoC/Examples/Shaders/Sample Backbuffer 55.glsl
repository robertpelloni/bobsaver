#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D bb;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void ) {
    vec2 uv = gl_FragCoord.xy / resolution;
    
    if(mouse.x == 0.0 || time < 1.0){
        glFragColor = vec4(rand(uv + vec2(0.6,-0.2) * time), rand(fract(uv * time)), rand(uv + vec2(0.5,0.2) * time), 1);
    }else{
        vec4 old = texture2D(bb, uv);
        vec2 v = (old.zw - 0.4);
        mat2 M = mat2(
            v, vec2(-v.y, v.x)
        );
        M[0][0] += 0.4 * (old.x - 0.5);
        M[1][1] += 0.8 * (old.y - 0.5);
        M[1][0] += 0.01 * (old.w - 0.5);
        M[0][1] += 0.4 * (old.z - 0.5);
        
    vec2 offset = 0.5 / resolution;
    glFragColor = vec4(0);
    const int r = 1;

    for(int x = -r; x <= r; x++){
        for(int y = -r; y <= r; y++){
            glFragColor += smoothstep(float(r) * 1.1, 0.0, length(vec2(x,y))) * texture2D(bb, fract(uv + vec2(x,y) * offset));
        }
    }
    glFragColor /= float((2*r+1) * (2*r+1));   
        glFragColor += 
            0.25 * texture2D(bb, fract(uv + M * vec2(2,1) * offset)) + 
            0.25 * texture2D(bb, fract(uv + M * vec2(-1,2) * offset)) + 
            0.25 * texture2D(bb, fract(uv - M * vec2(2,1) * offset)) + 
            0.25 * texture2D(bb, fract(uv - M * vec2(-1,2) * offset)) - 
            0.25 * texture2D(bb, fract(uv - M * vec2(3,0) * offset)) - 
            0.25 * texture2D(bb, fract(uv - M * vec2(0,3) * offset)) - 
            0.25 * texture2D(bb, fract(uv + M * vec2(0,3) * offset)) -
            0.25 * texture2D(bb, fract(uv + M * vec2(3,0) * offset));
        glFragColor *= 1.1;
    }
}
