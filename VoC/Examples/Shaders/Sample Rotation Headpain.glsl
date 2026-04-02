#version 420

// original https://www.shadertoy.com/view/3tlGRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIZE 15.0 
#define HPI 1.5707963 
#define COL1 vec3(32, 43, 51) / 255.0 
#define COL2 vec3(235, 241, 245) / 255.0 
 
void main(void)
 { 
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.x;
    float sm = 1.0 / resolution.y * SIZE * 1.2; // Smooth factor
    
    uv *= SIZE; // Make grid
    vec2 id = floor(uv);
    uv = fract(uv) - 0.5;
    
    float angle = time; // Prepare rotation matrix
    float ca = cos(angle);
    float sa = sin(angle);
    mat2 rot = mat2(ca, - sa, sa, ca);
    
    float phase = mod(floor(angle / HPI), 2.0); // Determine what phase is right now
    
    float mask = 0.0;
    for(float y =- 1.0; y <= 1.0; y++ ) { // Loop to draw neighbour cells
        for(float x =- 1.0; x <= 1.0; x++ ) {
            vec2 ruv = uv + vec2(x, y);
            vec2 rid = id + vec2(x, y);
            
            ruv *= rot; // rotate
            
            float maskX = smoothstep(-0.5, -0.5 + sm, ruv.x) * smoothstep(0.5 + sm, 0.5, ruv.x);
            maskX *= smoothstep(-0.5, -0.5 + sm, ruv.y) * smoothstep(0.5 + sm, 0.5, ruv.y);
            
            float draw = (mod(rid.x, 2.0) * mod(rid.y, 2.0) + mod(rid.x + 1.0, 2.0) * mod(rid.y + 1.0, 2.0));
            draw = abs(draw - phase); // Flip depending on phase
            
            mask += maskX * draw;
        }
    }
    
    vec3 col = vec3(1.0);
    col = mix(COL1, COL2, abs(mask - phase)); // Color flip depending on phase
    
    glFragColor = vec4(col, 1.0);
}
