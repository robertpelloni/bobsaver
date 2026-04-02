#version 420

// original https://www.shadertoy.com/view/WlsyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14
#define TARGET_COUNT 15
#define GRID_CELL_SIZE 0.1
#define RED vec3(1.0,0.0,0.0);
#define GREEN vec3(0.0,1.0,0.0);
#define BLUE vec3(0.0,0.0,1.0);

vec2 getGridPosition(in vec2 uv)
{
    return vec2((uv.x / GRID_CELL_SIZE), (uv.y / GRID_CELL_SIZE));
}

void main(void)
{
    // Normalized frag coordinates
    vec2 uv = (gl_FragCoord.xy - (0.5 * resolution.xy)) / resolution.y;
    
    vec2 gridBoundUV = getGridPosition(uv);

    vec2 cellBoundUV = gridBoundUV - round(gridBoundUV);
    
    float redIntensity = 0.0;
    float blueIntensity = 0.0;
 
    for (int targetIndex = 0; targetIndex < TARGET_COUNT; ++targetIndex)
    {
        float f_targetIndex = float(targetIndex);

        float trigOffset = (PI / float(TARGET_COUNT)) * f_targetIndex;
        vec2 targetPosition = vec2(sin(time + trigOffset) * 0.51 + tan(f_targetIndex + trigOffset), cos(time + trigOffset) * 0.1 + sin(f_targetIndex + trigOffset));
        vec2 gridBoundTargetPosition = getGridPosition(targetPosition);
        vec2 edgeBoundPosition = vec2(gridBoundTargetPosition.x, gridBoundTargetPosition.y);

        // change the op between the lengths to subtraction for some extreme strobe effects
        float distanceToTarget = length(gridBoundUV - round(gridBoundTargetPosition)) + length((gridBoundUV) - (edgeBoundPosition));

        redIntensity += length(GRID_CELL_SIZE / (distanceToTarget * 9.5)  / cellBoundUV) * GRID_CELL_SIZE;
    
    }

    for (int targetIndex = 0; targetIndex < TARGET_COUNT; ++targetIndex)
    {
        float f_targetIndex = float(targetIndex);

        float trigOffset = (PI / float(TARGET_COUNT)) * f_targetIndex;

        vec2 targetPosition = vec2(sin(time + trigOffset) * 0.51 + sin(f_targetIndex + trigOffset), tan(time + trigOffset) * 0.1 + sin(f_targetIndex + trigOffset));
        vec2 gridBoundTargetPosition = getGridPosition(targetPosition);
        vec2 edgeBoundPosition = vec2(gridBoundTargetPosition.x, gridBoundTargetPosition.y);

        float distanceToTarget = length(gridBoundUV - round(gridBoundTargetPosition)) + length((gridBoundUV) - (edgeBoundPosition));

        blueIntensity += length(GRID_CELL_SIZE / (distanceToTarget * 15.5)  / cellBoundUV) * GRID_CELL_SIZE;
    
    }

    vec3 col = vec3(smoothstep(0.2, 1.0, redIntensity + blueIntensity));

    col += redIntensity * GREEN;
    col += blueIntensity * BLUE;
   
    // Output to screen
    glFragColor = vec4(col,1.0);
}
