#version 420

// original https://www.shadertoy.com/view/7dsXRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float s32 = sqrt(3.)/2.;

float lineDistance(in vec2 p, in vec2 a, in vec2 b)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba) / dot(ba,ba), 0., 1.);    
    return length(pa - ba * h);
}

bool rightSide(in vec2 p, in vec2 a, in vec2 b)
{
    return (p.x-a.x)*(b.y-a.y)-(p.y-a.y)*(b.x-a.x) > 0.;
}

void main(void)
{
    float t = ( (1.-cos(2.*time)) )/2.;
    
    // 4. factor so we see more triangles in the viewport.
    // 0.2*time for the diagonal drift
    vec2 uv = 4.*(gl_FragCoord.xy-resolution.xy/2.)/resolution.y + 0.2*time;
    
    // Tile vertically~diagonally along a triangle edge:
    // uv.y/s32 is the V coordinate in a UV frame shaped like /_
    uv -= floor(uv.y/s32)*vec2(0.5, s32);
    // And tile by 1 horizontally
    uv.x = uv.x - floor(uv.x);
    
    // Look at the three triangle edges individually.
    // Here's the horizontal _ one that becomes / when t==1
    vec2 orig = vec2(0., 0.);
    vec2 end = t*vec2(0.5, s32) + vec2(1.-t, 0.);
    
    // Distance to the line, and are we on its right side
    float dist1 = lineDistance(uv, orig, end);
    bool right1 = rightSide(uv, orig, end);
 
    // Transform uv into the second edge's local frame
    vec2 uv2 = uv - vec2(1.0, 0.0);
    uv2 = vec2(-0.5*uv2.x + s32*uv2.y, -s32*uv2.x - 0.5*uv2.y);
    // Then same computation
    float dist2 = lineDistance(uv2, orig, end);
    bool right2 = rightSide(uv2, orig, end);

    // Transform into the third edge's frame
    vec2 uv3 = uv - vec2(0.5, s32);
    uv3 = vec2(-0.5*uv3.x - s32*uv3.y, s32*uv3.x - 0.5*uv3.y);
    // And again
    float dist3 = lineDistance(uv3, orig, end);
    bool right3 = rightSide(uv3, orig, end);
 
    // Background
    glFragColor = vec4(1.0);

    // Inside triangles
    if (right1 && right2 && right3)
        glFragColor = vec4(1.0, 0.0, 0.0, 1.0);
    if (!right1 && !right2 && !right3)
        glFragColor = vec4(0.0, 0.0, 1.0, 1.0);
  
    // Triangle edges
    // Truncated
    dist1 = (!right3 && right2) ? 10.0 : dist1;
    dist2 = (!right1 && right3) ? 10.0 : dist2;
    dist3 = (!right2 && right1) ? 10.0 : dist3;

    float distToTriangle = min(min(dist1, dist2), dist3);
    // Anti-aliasing
    glFragColor = mix( glFragColor, vec4(0.), smoothstep(6./resolution.y, 0., distToTriangle) );
}
