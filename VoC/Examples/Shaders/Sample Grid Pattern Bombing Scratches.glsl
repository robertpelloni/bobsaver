#version 420

// original https://www.shadertoy.com/view/3dd3Rr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// with respect to https://www.shadertoy.com/view/4syXRD -- though this shader works
// very differently

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

// IQ: https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdLine( in vec2 p, in vec2 a, in vec2 b, float r )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

// IQ: https://www.iquilezles.org/www/articles/functions/functions.htm
float Gain(float x, float k) 
{
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}

// make a scratch in a grid cell
float CellScratch(vec3 cell, vec2 ext, float seed, float waviness)
{
    
    float cellID = cell.x;
    vec2 cellCoord = cell.yz;
    
    float rnd = Random1D(cellID + seed);
    float rnd2 = Random1DB(cellID);
    
    // some cells are empty
    if(rnd > rnd2)
        return 0.0;
        
    // make a random line in this cell
    
    // get a couple of random points we can shape
    vec2 ra = Random2DVector(vec2(cellID,cellID), seed + (cellID * seed));
    vec2 rb = Random2DVector(vec2(cellID,cellID), rnd + (cellID * rnd2));
    
    // let waviness randomly vary, but favor extremes of straighter or more bent
    waviness = Gain(waviness * rnd2,1.4) * 6.28;
    
    // let's make this line mostly horizontal or vertical across the cell
    // compute bending params based on h or v
    vec2 pa,pb;
    vec2 off;
    float rot;
    
    // random pick
    if(ra.x < rb.x)
    {
        // line will be horizontal
        pa = vec2(0.0,ra.y);
        pb = vec2(1.0,rb.y);
        
        
        float waveAmp = pow(0.5,6.28*cellCoord.x);
        float waveFreq = 3.14 * pow(waviness, cellCoord.x);
        off = vec2(0.0, 0.5 + waveAmp * sin(waveFreq));
        
        rot = 1.2 * cos(cellCoord.x+ pa.y + pb.y);
    } else
    {
        // line will be vertical
        pa = vec2(ra.x, 0.0);
        pb = vec2(rb.x, 1.0);
        
        float waveAmp = pow(0.5,6.28*cellCoord.y);
        float waveFreq = 3.14 * pow(waviness, cellCoord.y);
        off = vec2(0.5 + + waveAmp * sin(waveFreq),0.0);
        
        rot = 1.2 * cos(cellCoord.y+ pa.x + pb.x);
    }
       
    // make sure the line is visible
    float pen = 2.0 / (float(resolution.x) * ext.x);
    
    // distort the line for bending    
    cellCoord = Rotate2D(cellCoord, rot);
    cellCoord += off;
    
    // get distance to line
    float dLine = sdLine(cellCoord, pa, pb, pen);
    
    float intensity = pow(clamp(-dLine,0.0,1.0), 0.05);
    return intensity;
}

// apply multiple layers of scratches
float BombScratches(
    vec2 uv, float seed, float waviness,
    int iterations, float lacunarity)
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

        // get a scratch
        float scratch = 
            CellScratch(
                vec3(cellID, cellCoords), 
                extents,
                bombSeed,
                waviness);
        
        // dampen by layer depth
        float depthScratch = scratch / scale;

        intensity = max(depthScratch,intensity);       

        // set up for next iteration
        bombSeed = Random1D(bombSeed + seed +1.618);
        scale *= lacunarity;
    }
                        
    return intensity;
}

vec4 ComputeWaveGradientRGB(float t, vec4 bias, vec4 scale, vec4 freq, vec4 phase)
{
    vec4 rgb = bias + scale * cos(3.14159 * 2.0 * (freq * t + phase));
    return vec4(clamp(rgb.xyz,0.0,1.0), 1.0);
}

// antialias.
float SmoothScratches(
    vec2 uv, 
    float seed,
    int iterations, 
    float lacunarity,
    float waviness,
    float res)
{
    // using AA by Shane:
    // https://www.shadertoy.com/view/4d3SWf
    
    const float AA = 4.0; 
    const int AA2 = int(AA*AA);
    float col = 0.0;
    vec2 pix = 2.0 / vec2(res,res) / AA; 

    for (int i = 0; i < AA2; i++) 
    {

        float k = float(i);
        
        vec2 uvOffs = uv + vec2(floor(k / AA), mod(k, AA)) * pix;
        col += BombScratches(uvOffs,seed,waviness,iterations,lacunarity);
        
    }

    col /= (AA*AA);
    return col;
}

void main(void)
{
    
    vec2 pos = gl_FragCoord.xy / resolution.x;
    pos *= 2.0;
       pos += vec2(1.0);
    
    // scroll right
    pos.x += mod(time/6.0,12.0);
    
    // change random seed 
    const float duration = 6.0;
    float seed = floor(time / duration);
     
    vec3 color;
    
    // shape   
    float cc = SmoothScratches(pos, seed, 8, 1.2, 0.6, resolution.y);
    
    // coloring
    vec4 bias = vec4(0.5, 0.5, 0.5, 1.0);
    vec4 scale = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 freq = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 phase = vec4(0.0, 0.3333, 0.6666, 1.0);
    
    vec4 col = vec4(0.0);
    if(cc > 0.0) 
        col= cc * ComputeWaveGradientRGB(cc,bias,scale,freq,phase);
    
    col = pow(col,vec4(0.6));
    
       
    glFragColor = vec4(col.xyz, 1.0);
}
