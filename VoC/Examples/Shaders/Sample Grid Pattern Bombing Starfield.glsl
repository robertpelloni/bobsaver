#version 420

// original https://www.shadertoy.com/view/tstGz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Map( float range_a_point, float a0, float a1, float b0, float b1 )
{
    return (((range_a_point - a0) * (abs(b1-b0)))/abs(a1-a0)) + b0;
}

vec4 ComputeSpiral(
    vec2 p,
    float points,
    float shape,  // def 0.3
    float spiral, // def 1.0
    float angleOffs,
    float ccScale)
{
    shape = clamp(shape, 0.2, 0.8);
    spiral = clamp(spiral, 0.1, 8.0);
    vec2 st = vec2(atan(p.x, p.y), length(p));
    vec2 uv = vec2((st.x  - angleOffs)/ 6.28 + 0.5+(st.y * spiral), st.y);
    

    float x = uv.x * points;
    float m = min(fract(x), fract(1.0 - x)); // sawtooth pattern
    float c = smoothstep(0.0, 0.1,
        m*shape +  // lower saw amp
        0.2 -    // raise saw up
        uv.y);

    return vec4(c, uv.x * ccScale, uv.y * ccScale, m * ccScale);
}

vec4 ComputeWaveGradientRGB(float t, vec4 bias, vec4 scale, vec4 freq, vec4 phase)
{
    vec4 rgb = bias + scale * cos(6.28 * (freq * t + phase));
    return vec4(clamp(rgb.xyz,0.0,1.0), 1.0);
}

vec4 NebulaColor(float t)
{
    return ComputeWaveGradientRGB(
            t,
            vec4(0.607, 0.848, 1.788,1.0), 
            vec4(-0.102, -0.222, 0.854,1.0),
            vec4(0.004, 0.350, 0.763,1.0),
            vec4(-0.023, 0.097, -0.023,1.0));
}

float Random1D(float seed)
{
    return fract(sin(seed)*32767.0);
}

float Random1DB(float seed)
{
    return fract(sin(seed)* (65536.0*3.14159265359));
}

float Random3D(vec3 p)
{
    
    vec3 comparator = vec3(
        fract(123456.34 * p.x), 
        fract(78956.789 * p.y),
        fract(234512.987 * p.z));
    
    float alignment = dot(p, comparator);
    float amplitude = sin(alignment) * 32767.0;
    float random = fract(amplitude + 0.001);
    return random;
}

float Random2D(vec2 p)
{
    vec2 comparator = vec2(
        fract(123456.34 * p.x), 
        fract(78956.789 * p.y));
    
    float alignment = dot(p, comparator);
    float amplitude = sin(alignment) * 32767.0;
    float random = fract(amplitude);
    return random;
}

vec2 Random2DVector(vec2 p, float s)
{
    float x = fract(sin(dot(p,vec2(127.1,311.7)))*18.5453 * (1.0+s));
    float y = fract(sin(dot(p,vec2(113.7,217.1)))*54.1853 * (2.0+s));
    return vec2(x,y);
}

vec2 RandomVector2(float p) 
{
    vec3 p3 = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p3 += dot(p3.xyz, p3.yzx + 19.19);
    return fract(vec2(p3.x * p3.y, p3.z * p3.x));
}

vec2 Rotate2D(vec2 v, float a) 
{
    
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float Star(vec2 p, vec2 tx, float r, float s)
{
    p -= tx;
    float d = (r * 1.0) / dot(p,p);
    d += d * (sin(s*15.0)*0.25+0.5);
    return d;
}

float Star2(vec3 cell, vec2 ext, float seed)
{
    float cellID = cell.x;
    vec2 cellCoord = cell.yz;
    float rnd = Random1D(cellID + seed);
    float rnd2 = Random1DB(cellID);
    
    // some cells are empty
    if(rnd > rnd2)
        return 0.0;
    
    vec2 ra = Random2DVector(vec2(cellID,cellID), seed + (cellID * seed));
    ra = clamp(ra, 0.25, 0.75);
    
    float pen = 2.0 / (float(resolution.x) * ext.x);
    pen = max(pen, 0.001);
    
    float rad = 0.01 * pen;
    return Star(cellCoord, ra, rad, seed);
    
}

// apply multiple layers of scratches
float BombStars(
    vec2 uv, 
    float seed, 
    int iterations, 
    float lacunarity)
{
        
    float intensity = 0.0;
    float bombSeed = seed;
    float scale = 1.0;
    
    for(int it = 0; it < 16; it++) 
    {
        // rotate, scale, and offset a grid for this iteration.
        vec2 pos = uv + vec2(3.0 * float(it) * Random1D(bombSeed));
        float angle = 3.14159 * Random1D(bombSeed);
        pos = Rotate2D(pos, angle);        
        pos = pos * scale;
                
        // get current cell
           vec2 cell = floor(pos);
        float cellID = (10.0*Random2D(cell)) + (Random2D(floor(uv*scale)));
        vec2 cellCoords = fract(pos);
        
        vec2 extents = vec2(1.0/scale);

        // get a star
        float star = 
            Star2(vec3(cellID, cellCoords), extents, bombSeed);
        
        // dampen by layer depth
        float depth = star / scale;

        intensity = max(depth,intensity);       

        // set up for next iteration
        bombSeed = Random1D(bombSeed + seed +1.618);
        scale *= lacunarity;
    }
                        
    return intensity;
}

void main(void)
{
    
    vec2 pos = gl_FragCoord.xy;

    vec2 p =  pos.xy / resolution.x;
    float spin= time;
    vec2 galaxyPos = p - vec2(0.5,0.25);
    galaxyPos *= 1.5;
    
    float dust = Map( clamp(1.0-length(galaxyPos),0.0,0.8), 0.0, 1.0, 0.0, 0.3);
    vec4 dustColor = dust * NebulaColor(0.2);
    
    vec2 starPos = p + vec2(time*0.1,0.0);
    float stars = BombStars(starPos, 1.618, 16, 1.2);
    vec3 starColor = stars * vec3(1.0,1.0,0.82);
        
    vec4 pattern = ComputeSpiral(galaxyPos, 6.0, 0.3, 2.0, spin, 0.4);
    float nebInt =  pattern.x * pattern.w;
        
    vec4 nebColor = pattern.w * pattern.x * NebulaColor(nebInt);
    
    float center = Star(galaxyPos, vec2(0,0), 0.0051, 0.5);
    vec3 centerColor = center * vec3(1.0,1.0,0.82);
    
    vec3 col = dustColor.xyz + starColor + nebColor.xyz + centerColor;
    
    
    // Output to screen
    glFragColor = vec4(
        col,
        1.0);
}
