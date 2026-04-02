#version 420

// original https://www.shadertoy.com/view/wlBGWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SQUARE_SIZE .2
#define EDGE_SIZE .005
#define SPEED 15.

#define PI_2 1.5707963
#define PI_4 0.7853981
#define PINK_COL vec3(136,105,121)/255.

#define sinp(v) (sin(v) * .2 + .4)

vec3 addEdgeCol(vec3 squareCol, float side, float time){
    float edge = step(EDGE_SIZE + side, SQUARE_SIZE);    
    vec3 edgeCol = vec3(sinp(time));
    return mix(edgeCol, squareCol, edge);
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    uv *= mat2(1,-1,1,1) * 0.7; // PI/4 rotation
    
    float t = time * SPEED;
        
    float m = step(max(abs(uv.x),abs(uv.y)), SQUARE_SIZE );                  
            
    float time1 = t + PI_2;
    float time2 = t - PI_2;  
    
    vec3 squareCol = PINK_COL;  
            
    // top-left edge
    squareCol = addEdgeCol(squareCol, -uv.x, time1);        
    // top-right edge
    squareCol = addEdgeCol(squareCol, +uv.y, time1);       
    // bottom-right edge
    squareCol = addEdgeCol(squareCol, +uv.x, time2);           
    // bottom-left edge
    squareCol = addEdgeCol(squareCol, -uv.y, time2);        
    
    vec3 backCol = vec3(sinp(t));
    
    vec3 col = mix(backCol, squareCol, m);
    
    glFragColor = vec4(col,1.0);
}
