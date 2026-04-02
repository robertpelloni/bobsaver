#version 420

// original https://www.shadertoy.com/view/XtBBDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define WATER_HEIGHT 0.5
#define SAND_MAX_HEIGHT 0.53
#define GRASS_MAX_HEIGHT 0.6
#define SNOW_MIN_HEIGHT 0.7
#define FROZENLAVA_MIN_HEIGHT 0.8
#define OX -4.1523
#define OY -5.1928
#define MAP_ITERATIONS 8
#define MAP_START_ITERATIONS 0.3
#define ZOOM_MOD 0.6

float getRandom(vec2 seed)
{
    return fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 getRandomVec(vec2 seed)
{
  float s = getRandom(seed);
  return vec2(s,getRandom(vec2(s,s+3.0)));
}

float fade(float t) {
    //Don't interpolate for now
    return t;//mix(t,(cos(1.5708*2.0 + 1.5708*2.0*t)/2.0 + 0.5),0.1);
}

float getNoiseAt(float x,float y)
{
    vec2 loc = vec2(x, y);
    vec2 tl = floor(loc);
    vec2 tr = tl + vec2(1.0,0.0);
    vec2 bl = tl + vec2(0.0,1.0);
    vec2 br = tl + vec2(1.0,1.0);
    
    float a = dot(normalize(getRandomVec(tl)),loc.xy-tl.xy);
    float b = dot(normalize(getRandomVec(tr)),loc.xy-tr.xy);
    float c = dot(normalize(getRandomVec(bl)),loc.xy-bl.xy);
    float d = dot(normalize(getRandomVec(br)),loc.xy-br.xy);
    
    vec2 weight = loc.xy-tl.xy;
    
    return mix(mix(a,c,fade(weight.y)),mix(b,d,fade(weight.y)),fade(weight.x));
}

float getHeightAt(float x, float y, int iterations, float start)
{
    float height = 0.0;
    float depth = pow(2.0,start);
    
    for(int i = 0; i < iterations; i++)
    {
        float noise = getNoiseAt(x*depth,y*depth);
        height = mix(height, noise , 1.0/depth);
        depth *= 2.0;
    }
    
    return (height*3.0)+0.5;
}

float getShadow(float x, float y, int iterations, float start, vec3 sunDirection)
{
    float size = 1.0/pow(2.0,float(iterations)+start);
    vec2 cc = vec2(x,y);
    vec2 t = cc+vec2(0,-size);
    vec2 r = cc+vec2(-size,0);
    vec2 b = cc+vec2(0,size);
    vec2 l = cc+vec2(size,0);
    
    float top = getHeightAt(t.x,t.y, iterations, start);
    float bottom = getHeightAt(b.x,b.y, iterations, start);
    float left = getHeightAt(l.x,l.y, iterations, start);
    float right = getHeightAt(r.x,r.y, iterations, start);
    
    float n = size*2.0;
    
    vec3 or = normalize(-vec3(right-left,bottom-top,n));
    
    return dot(or,sunDirection);
}

float getCloud(float x, float y)
{
    x += time/23.25 + sin(time/10.0);
    y += time/31.20;
    float cloud = getHeightAt(x+2.232,y+3.1027,6,3.0);
    float cloudDensity = getHeightAt(-x+0.21,y-1.121,5,0.5)-0.1;
    return (min(cloud,cloudDensity)-0.5) * 4.0 + sin(time/6.5)/5.0;
}

float getCloudShadow(float x, float y, float h, vec3 sunDir)
{
    vec3 dist = sunDir * ((1.0-h)/sunDir.z);
    return getCloud(x+0.1,y+0.01);
}

vec3 getHeightColor(float height, float x, float y)
{
    vec3 color = vec3(0,0,0);
    
    //Trees and tree density
    float treeDensity = getHeightAt(x+323.1, y+225.5, 2, 3.0);
    float treeDetailing = getHeightAt(x,y, 2, 6.0);
    
    float td = min(treeDensity,treeDetailing);
    
    //Water tides
    float wt = (getHeightAt(x+2.12 + sin(time/10.0),y*2.98+0.21, 4, 0.25) - 0.5)*0.1;
    
    //Grass irregularities
    
    float gi = (getHeightAt(-x+2.12,-y*1.68+0.71, 4, 0.25) - 0.5)*0.1;
    
    //Stone irregularities
    float si = (getHeightAt(x-2.42,y*3.03-0.21, 4, 0.25) - 0.5)*0.1;
    
    if(height < WATER_HEIGHT + wt)
    {color = vec3(height*0.7,height*0.9,height*1.1);}
    else if(height < SAND_MAX_HEIGHT+gi)
    {color = vec3(height*1.1,height*1.1,height*0.95);}
    else if(height < GRASS_MAX_HEIGHT+si)
    {
        color = vec3(height*0.6,height*0.9,height*0.2);
        if(td > 0.5)
            color.rgb *= 0.7;
    }
    else if(height < SNOW_MIN_HEIGHT)
    {
        color = vec3(height/1.2,height/1.2,height/1.2);
        if(td > 0.5)
            color.rb *= 0.0;
    }
    else
    {
        color = vec3(height,height,height);
        if(td > 0.5)
            color.rgb *= 0.95;
    }
    
    if(height > FROZENLAVA_MIN_HEIGHT && td > 0.5)
        {
            color.r *= 0.7;
            color.b *= 1.0;
            color.g *= 0.85;
        }
    
    return color;
}

void main(void)
{
    float s = time;
    float aspect = resolution.y/resolution.x;
    vec2 texCoord = gl_FragCoord.xy/resolution.xy*2.0 - 1.0;
    texCoord.y *= aspect;
    float zoom = sin(s/2.1243)/8.0 + 0.55;
    vec2 offset = vec2(0,0);
    offset.x = sin(s/7.2374)/2.0;
    offset.y = cos(s/10.7412)/2.0;
    
    texCoord += offset;
    
    texCoord *= zoom / ZOOM_MOD;
    
       float centerDist = texCoord.x*texCoord.x + texCoord.y*texCoord.y;
    
    texCoord.x += OX;
    texCoord.y += OY;
    
    float height = getHeightAt(texCoord.x, texCoord.y, MAP_ITERATIONS, MAP_START_ITERATIONS);
    
    float t = time/8.0;
    height = max(0.3,height-centerDist*centerDist*0.2);
    if(centerDist < 0.025) height = mix(1.0,height,centerDist*40.0);
    vec3 col = getHeightColor(height, texCoord.x, texCoord.y);
    
    float underwater = height>WATER_HEIGHT?1.0:0.2;
    
    vec3 sunDir = normalize(vec3(-2.0,sin(t),cos(t)*0.5));
    
    float shadow = getShadow(texCoord.x, texCoord.y, MAP_ITERATIONS, MAP_START_ITERATIONS, sunDir);
    
    shadow += 1.0;
    
    shadow += getCloudShadow(texCoord.x,texCoord.y ,height, sunDir);
    
    float cloud = getCloud(texCoord.x, texCoord.y);
    
    if(shadow <= 1.0)col = mix(col,vec3(0),(shadow - 1.0)/4.0*underwater);
    if(cos(t) < 0.0)col = mix(vec3(0.05,0.0,0.1),col,1.0+cos(t)/1.4);
    
    if(cloud > 0.0)col = mix(vec3(1.0,1.0,1.0),col,1.0-cloud);
    
    glFragColor = vec4(col.xyz,1.0);
}
