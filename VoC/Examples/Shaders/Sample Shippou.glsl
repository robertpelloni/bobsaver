#version 420

// original https://www.shadertoy.com/view/wtG3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265357989

vec2 rotate(vec2 pos, float angle)
{
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c) * pos;
}

float hash(vec2 n)
{
    return fract(sin(dot(n, vec2(123.0, 458.0))) * 43758.5453);
}

float cubicInOut(float time) {
  return (time < 0.5) ? (4.0 * time * time * time) : (1.0 - 4.0 * pow(1.0 - time, 3.0));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    uv += vec2(1,-1) * time * 0.05;
    
    float uvScale = 2.5;
    vec2 uvID = floor(uv * uvScale);
    vec2 uvID2 = floor(uv * uvScale + vec2(0.5));
    vec2 uvLocal = fract(uv * uvScale);

    float time = time * 1.0;
    float timef = cubicInOut(fract(time));
    float timei = floor(time);
    time = (timef + timei) * 0.5;
    
    // animation 1
    float rotDir = (0.0 == mod(uvID.y, 2.0) ? 1.0 : -1.0);
    vec2 rotCenter = vec2(0.5, 0.5);
    vec2 uvAnim1 = uvLocal;
    uvAnim1 = rotate(uvAnim1 - rotCenter, time * PI * rotDir);
    uvAnim1 += rotCenter;
    
    // animation 2
    vec2 uvAnim2 = uvLocal;
    float uvAnim2Corner = floor(uvLocal.x);
    uvAnim2 += vec2((0.5 < uvAnim2.x ? -0.5 : 0.5), (0.5 < uvAnim2.y ? -0.5 : 0.5));
    uvAnim2 = rotate(uvAnim2 - rotCenter, time * PI);
    uvAnim2 += rotCenter;
    
    // animation
    uvLocal = (fract(time) < 0.5) ? uvAnim1 : uvAnim2;
    
    // distance
    float neighborDist = 1e+4;
    for(float x=-1.0; x<=1.0; x+=2.0)
        for(float y=-1.0; y<=1.0; y+=2.0)
            neighborDist = min(neighborDist, distance(uvLocal, vec2(x,y) * 0.5 + vec2(0.5)));
    
    float dist = 1e+4;
    dist = distance(uvLocal, vec2(0.5));
    dist = max(dist, neighborDist);
    
    // color
    float smoothness = 0.05;
    float thickness = 0.03;
    float center = 0.45;
    float density = smoothstep(center - thickness, center + thickness, dist);
    density = smoothstep(1.0, 1.0 - smoothness, density) * (smoothstep(0.0, 0.0 + smoothness, density));
    
    float colorID = (fract(time) < 0.5) ? hash(uvID) : hash(uvID2);
    float colorVariation = 0.3;
    float colorOffset = -0.7;
    vec3 color = vec3(0,1,2) * PI * 0.5 + colorID * colorVariation + colorOffset;
    color = max(sin(color), cos(color)) + 0.4;
    
    float colorBgWave = (sin((uv.x - uv.y) * 2.0 + time * 3.0) + sin((uv.x - uv.y * 0.5) * 1.5 + time)) * 0.5;
    vec3 colorBg = vec3(1.0, 0.8, 0.5) * mix(0.65, 1.0, colorBgWave);
    glFragColor.rgb = vec3(density) * color * (colorBgWave * 0.75 + 0.25);
    glFragColor.rgb = mix(colorBg, glFragColor.rgb, density);
    glFragColor.rgb = clamp(glFragColor.rgb * (1.2 + sin(time) * 0.1), 0.0, 1.0);
}
