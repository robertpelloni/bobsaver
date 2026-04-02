#version 420

// original https://www.shadertoy.com/view/ttSGz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Layered voronoi
#define VORONOI_NOISE_POW 5.0
#define VORONOI_BRIGHTNESS_ADD 0.05
#define SIZE_MUL 1.5
#define ALPHA_MUL 0.9
#define LAYERS 4

//Colors
#define WATER_COLOR vec4(0.0, 0.8, 0.8, 1.0)

//Image size and displacement
#define UV_MUL 3.0
#define UV_DISPLACEMENT_STRENGTH 0.15
#define UV_DISPLACEMENT_SIZE 5.0

//Animation
#define WATER_SPEED 0.5
#define ANIMATION_SPEED 2.0

float hash1_2(vec2 x)
{
     return fract(sin(dot(x, vec2(52.127, 61.2871))) * 521.582);   
}

vec2 hash2_2(vec2 x)
{
    return fract(sin(x * mat2x2(20.52, 24.1994, 70.291, 80.171)) * 492.194);
}    

//Simple interpolated noise
vec2 noise2_2(vec2 uv)
{
    vec2 f = smoothstep(0.0, 1.0, fract(uv));
    
     vec2 uv00 = floor(uv);
    vec2 uv01 = uv00 + vec2(0,1);
    vec2 uv10 = uv00 + vec2(1,0);
    vec2 uv11 = uv00 + 1.0;
    vec2 v00 = hash2_2(uv00);
    vec2 v01 = hash2_2(uv01);
    vec2 v10 = hash2_2(uv10);
    vec2 v11 = hash2_2(uv11);
    
    vec2 v0 = mix(v00, v01, f.y);
    vec2 v1 = mix(v10, v11, f.y);
    vec2 v = mix(v0, v1, f.x);
    
    return v;
}

vec2 rotate(vec2 point, float deg)
{
     float s = sin(deg);
    float c = cos(deg);
    return mat2x2(s, c, -c, s) * point;
}

//Cell center from point on the grid
vec2 voronoiPointFromRoot(vec2 root, float deg)
{
      vec2 point = hash2_2(root) - 0.5;
    float s = sin(deg);
    float c = cos(deg);
    point = mat2x2(s, c, -c, s) * point;
    point += root + 0.5;
    return point;
}

float degFromRootUV(vec2 uv)
{
     return time * ANIMATION_SPEED * (hash1_2(uv) + 0.2);   
}

//x - voronoi coordinates (grid step = 1)
float voronoi(vec2 uv)
{
    vec2 rootUV = floor(uv);
    float deg = degFromRootUV(rootUV);
    vec2 pointUV = voronoiPointFromRoot(rootUV, deg);
    
    vec2 tempRootUV;    //Used in loop only
    vec2 tempPointUV;    //Used in loop only
    vec2 closestPointUV = pointUV;
    float minDist = 2.0;
    float dist = 2.0;
    for (float x = -1.0; x <= 1.0; x+=1.0)
    {
         for (float y = -1.0; y <= 1.0; y+=1.0)   
        {
             tempRootUV = rootUV + vec2(x, y);
            deg = (time * hash1_2(tempRootUV) * ANIMATION_SPEED);
            tempPointUV = voronoiPointFromRoot(tempRootUV, deg);
            
            dist = distance(uv, tempPointUV);
            if(dist < minDist)
            {
                 closestPointUV = tempPointUV;
                   minDist = dist;
            }
        }
    }
    
    return minDist;
}

//Layered voronoi noise
float fractVoronoi(vec2 uv, float sizeMul, float alphaMul, int layers)
{
     float noise = 0.0;
    float size = 1.0;
    float alpha = 1.0;
    vec2 uvOffset; //Used in loop only
    for(int i = 0; i < layers; i++)
    {
        uvOffset = hash2_2(vec2(size, alpha)) * time * WATER_SPEED;
        noise += pow(voronoi((uv + uvOffset) * size) * alpha + VORONOI_BRIGHTNESS_ADD, VORONOI_NOISE_POW);
        size *= sizeMul;
        alpha *= alphaMul;
    }
    
    noise *= (1.0 - alphaMul)/(1.0 - pow(alphaMul, float(layers)));
    return noise;
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.x; 
    uv *= UV_MUL;
    vec2 noise2D = noise2_2(uv * UV_DISPLACEMENT_SIZE) * UV_DISPLACEMENT_STRENGTH;
    float fractVoro = fractVoronoi(uv + noise2D, SIZE_MUL, ALPHA_MUL, LAYERS);
    float res = smoothstep(-0.2, 0.3, fractVoro);
    glFragColor = vec4(res) * WATER_COLOR + fractVoro;
}
