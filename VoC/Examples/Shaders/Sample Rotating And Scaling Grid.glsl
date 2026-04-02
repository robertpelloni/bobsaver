#version 420

// original https://www.shadertoy.com/view/Nt3cDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float gridSize = 10.0; //# of rows without transform
float gridP = 0.05;
vec3 bgColor = vec3(0.0,0.1,0.2);
vec3 lineColor = vec3(0.3,0.7,0.8);

void main(void)
{
    //-1 to 1 
    vec2 uv = ( gl_FragCoord.xy - 0.5 * resolution.xy ) / resolution.y;
    
    //Rotate + scale transform
    float s = 0.1 + abs(sin(time/5.0)) * 2.0;
    float a = time/2.0;
    uv = mat2(cos(a),-sin(a),sin(a),cos(a)) * s * uv;
    
    float modX = fract(uv.x*gridSize);
    float modY = fract(uv.y*gridSize);
    
    //Use more smoothing the more the camera is zoomed out
    //Prevents lines from being too thin
    float p = gridP * max(0.1,s);
    
    float smoothX = smoothstep(0.0,p,abs(0.5-modX));
    float smoothY = smoothstep(0.0,p,abs(0.5-modY));
    
    vec3 col = mix(lineColor,bgColor, smoothX * smoothY);

    glFragColor = vec4(col,1.0);
}
