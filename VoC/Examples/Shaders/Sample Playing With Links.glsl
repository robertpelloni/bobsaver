#version 420

// original https://www.shadertoy.com/view/3t2XW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592;
const float SQRT3 = 1.73205; 
const float VW = SQRT3/(10.0*SQRT3);

float Random1D(float seed)
{
    return fract(sin(seed)*32767.0);
}

float Random1DB(float seed)
{
    return fract(sin(seed)* (65536.0*3.141592));
}

float Random2D(vec2 p)
{
    vec2 comparator = vec2(
        12.34 * Random1D(p.x), 
        56.789 * Random1DB(p.y));
    float alignment = dot(p, comparator);
    float amplitude = sin(alignment) * 32767.0;
    float random = fract(amplitude);
    return random;
}

vec4 ComputeWaveGradientRGB(float t, vec4 bias, vec4 scale, vec4 freq, vec4 phase)
{
    vec4 rgb = bias + scale * cos(PI * 2.0 * (freq * t + phase));
    return vec4(clamp(rgb.xyz,0.0,1.0), 1.0);
}

float sdCircle( highp vec2 p, float r )
{
  return length(p) - r;
}

float Map(float value, float old_lo, float old_hi, float new_lo, float new_hi)
{
    float old_range = old_hi - old_lo;
    float new_range = new_hi - new_lo;
    return (((value - old_lo) * new_range) / old_range) + new_lo;
}

    
// cvcc = convex / concave:
// link shape control, ranging from -1 (concave) to 1 (convex)
float sdLink(in highp vec2 p, float cvcc)
{
    float rv = 0.0;
    
    
    float md = sdCircle(p, 1.0);
    
    
    float rs = 0.0;
    float disp = 0.0;
    float dist = 0.0;
    
    // side circle radii
    rs = (2.0 * abs(cvcc))+1.0; 
    
    // compute displacement of side circles
    if(sign(cvcc) > 0.0)
    {
         // hack to keep vesica length about same.
         // just a linear mapping between the 
         // extremes of the convexity to to side circle displacement,
         // bent with a power function to adapt to the non-linearity 
         // of the result. 
         float inp = pow(1.0-cvcc,2.1);
         float xl = Map(inp, 0.0, 1.0, SQRT3*VW,  VW * PI * SQRT3);
        
         disp = rs - xl;
    } else
    {
        // cut into about half the middle circle 
        disp = rs + 0.5;
    }
    
    // our shape is either the intersection of two circles (vesica),
    // or the subtraction of two circles from a center one (axehead) ...
    // since intersection is max(a,b) and subtraction is max(a,-b),
    // we can use the sign of our argument to control 
    // which we're doing ...
    float ld = sdCircle(vec2(p.x + disp, p.y),rs) * sign(cvcc);
    float rd = sdCircle(vec2(p.x - disp, p.y),rs) * sign(cvcc);
    
    dist = max(md, ld);
    dist = max(dist, rd);
    
    return dist;
}

highp vec4 GridTile(vec2 uv, float rep)
{
    highp float sp = 1.0 / rep;
    highp vec2 div = uv / sp;
    highp vec2 grid = floor(div);
    
    // cell coordinates, with origin in the center
    // of the cell.
    highp vec2 gc = 2.0*fract(div) - vec2(1.0,1.0) ;
    return vec4(grid,gc);
}

highp vec2 Rotate2D(highp vec2 v, float a) 
{
    
    float s = sin(a);
    float c = cos(a);
    highp mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float XNor(vec2 p)
{
    return abs(p.x + p.y - 1.0f);
}

vec2 RotateGridLink(highp vec2 pos, vec2 grid, bool linkAngled, highp float scaleFactor)
{
    highp vec2 shpCoord = scaleFactor * pos;
    
    if(linkAngled) // either rotate by 45 degrees or 90 degrees, 
        // depending on both grid position and "linkAngled" argument
        shpCoord = Rotate2D(shpCoord, (2.0*mod(grid.x + grid.y,2.0)-1.0) * (PI/4.0));
    else
        shpCoord = Rotate2D(shpCoord, XNor(grid) * (PI/2.0));
    
    return shpCoord;
        
}

highp vec3 ComputeDispLink(
    highp vec2 coord, 
    highp vec2 grid, 
    float rep,
    highp vec2 disp,
    highp float scaleFactor, 
    float cvcc, 
    bool linkAngled)
{
   
    
    highp vec2 gridB = grid + disp;
    highp vec2 tXcoord = coord - (2.0 * disp);
    
    highp vec2 s = RotateGridLink(tXcoord, gridB, linkAngled, scaleFactor);
    
    highp float distB = sdLink(s, cvcc);
    
    return vec3(distB, gridB);
}

highp vec3 MinDist(highp vec3 a, highp vec3 b)
{
    if(a.x<b.x)return a;
    return b;
}
    

vec4 ComputeLinkGrid(
    highp vec2 uv, 
    float cvcc, 
    float rep, 
    float gridAngle, 
    bool linkAngled,
    float softness)
{
    vec4 rv;
    uv = Rotate2D(uv,-gridAngle);
    
    
    highp vec4 gridInfo = GridTile(uv, rep);
    highp vec2 grid = gridInfo.xy;
    highp vec2 cellCoord = gridInfo.zw;
    
    highp float scaleFactor = 0.7;
    highp vec2 s = RotateGridLink(cellCoord, grid, linkAngled, scaleFactor);
    highp float dist =  sdLink(s, cvcc);
    highp vec3 tzz = vec3(dist,grid);
   
    
    // union all surrounding tiles, since they overlap this one
    highp vec3 tnn = ComputeDispLink(cellCoord, grid, rep, vec2(-1.0,-1.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tzn = ComputeDispLink(cellCoord, grid, rep, vec2(0.0,-1.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tpn = ComputeDispLink(cellCoord, grid, rep, vec2(1.0,-1.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tnz = ComputeDispLink(cellCoord, grid, rep, vec2(-1.0,0.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tpz = ComputeDispLink(cellCoord, grid, rep, vec2(1.0,0.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tnp = ComputeDispLink(cellCoord, grid, rep, vec2(-1.0,1.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tzp = ComputeDispLink(cellCoord, grid, rep, vec2(0.0,1.0),scaleFactor,cvcc,linkAngled);
    highp vec3 tpp = ComputeDispLink(cellCoord, grid, rep, vec2(1.0,1.0),scaleFactor,cvcc,linkAngled);
    
    highp vec3 winner;
    winner = MinDist(tzz,tnn);
    winner = MinDist(winner,tzn);
    winner = MinDist(winner,tpn);
    winner = MinDist(winner,tnz);
    winner = MinDist(winner,tpz);
    winner = MinDist(winner,tnp);
    winner = MinDist(winner,tzp);
    winner = MinDist(winner,tpp);
            
    highp float minDist = winner.x;
    highp vec2 minGrid = winner.yz;
 
    // 4d color control out, as is my convention
    float intensity = pow(clamp(-minDist,0.0,1.0), softness);
    rv = vec4(intensity,minGrid.x, minGrid.y,minDist);
    return rv;
}

void main(void)
{
    highp vec2 uv = gl_FragCoord.xy/float(resolution.y);
    // uv.y *= float(resolution.y) / float(resolution.x);
    // uv = 2.0*uv - vec2(1.0,1.0);
       
    // animation control
    float switchSeconds = 10.0;
    float tm= sin(mod(time,switchSeconds));
    float frm = step(0.5,mod(time,switchSeconds) /switchSeconds);
    float rot = step(0.5,mod(time,switchSeconds * 10.0) / (switchSeconds*10.0)) * PI/4.0;
    float softness = Map(sin(time / 10.0),-1.0,1.0, 0.25, 0.75);

    
    // shaping
    vec4 cc = ComputeLinkGrid(uv, tm, 8.0, rot, frm==0.0, softness);
    
    // coloration
    vec2 grid = cc.yz; // which cell controls color
        
    vec4 bias = vec4(0.5f, 0.5f, 0.5f, 1.0f);
    vec4 scale = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    vec4 freq = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    vec4 phase = vec4(0.0f, 0.3333f, 0.6666f, 1.0f);
    float t = Random2D(grid);
    vec4 col = ComputeWaveGradientRGB(t,bias,scale,freq,phase);
    
    // use intensity shape info
    col *=  cc.x;
    
    
    /*
    float dist = sdLink(uv,tm);
    float intensity = pow(clamp(-dist,0.0,1.0), softness);
    vec3 col = intensity * vec3(0.4,0.4,1.0);
    */
    
    glFragColor = vec4(col.xyz,1.0);
}
