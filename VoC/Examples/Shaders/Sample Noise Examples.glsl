#version 420

// original https://www.shadertoy.com/view/wslGWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Noise Examples" by Xor (@XorDev).
    
    Value noise (top-left), Perlin noise (top-right).
    Worley noise (bottom-left), Simplex noise (bottom-right).
    
    This shows the different types of noise functions.
    Feel free to get creative and play around with them.
*/

//Simple hash function:
float Hash(vec2 P)
{
    return fract(cos(dot(P,vec2(41.62,75.23)))*459.13);
}
//2D signed hash function:
vec2 Hash2(vec2 P)
{
    return 1.-2.*fract(cos(P.x*vec2(41.62,-75.23)+P.y*vec2(-84.13,59.46))*459.13);
}
//2D value noise.
float Value(vec2 P)
{
    vec2 F = floor(P);
    vec2 S = P-F;
    //Bi-cubic interpolation for mixing the cells.
    vec4 M = (S*S*(3.-S-S)).xyxy;
    M = M*vec4(-1,-1,1,1)+vec4(1,1,0,0);
    
    //Mix between cells.
    return (Hash(F+vec2(0,0))*M.x+Hash(F+vec2(1,0))*M.z)*M.y+
           (Hash(F+vec2(0,1))*M.x+Hash(F+vec2(1,1))*M.z)*M.w;
}
//2D Perlin gradient noise.
float Perlin(vec2 P)
{
    vec2 F = floor(P);
    vec2 S = P-F;
    //Bi-quintic interpolation for mixing the cells.
    vec4 M = (S*S*S*(6.*S*S-15.*S+10.)).xyxy;
    M = M*vec4(-1,-1,1,1)+vec4(1,1,0,0);
    
    //Add up the gradients.
    return (dot(Hash2(F+vec2(0,0)),S-vec2(0,0))*M.x+dot(Hash2(F+vec2(1,0)),S-vec2(1,0))*M.z)*M.y+
           (dot(Hash2(F+vec2(0,1)),S-vec2(0,1))*M.x+dot(Hash2(F+vec2(1,1)),S-vec2(1,1))*M.z)*M.w+.5;
}
//2D Worley noise.
float Worley(vec2 P)
{
    float D = 1.;
    vec2 F = floor(P);
       
    //Find the the nearest point the neigboring cells.
    D = min(length(.5*Hash2(F+vec2( 1, 1))+F-P+vec2( 1, 1)),D);
    D = min(length(.5*Hash2(F+vec2( 0, 1))+F-P+vec2( 0, 1)),D);
    D = min(length(.5*Hash2(F+vec2(-1, 1))+F-P+vec2(-1, 1)),D);
    D = min(length(.5*Hash2(F+vec2( 1, 0))+F-P+vec2( 1, 0)),D);
    D = min(length(.5*Hash2(F+vec2( 0, 0))+F-P+vec2( 0, 0)),D);
    D = min(length(.5*Hash2(F+vec2(-1, 0))+F-P+vec2(-1, 0)),D);
    D = min(length(.5*Hash2(F+vec2( 1,-1))+F-P+vec2( 1,-1)),D);
    D = min(length(.5*Hash2(F+vec2( 0,-1))+F-P+vec2( 0,-1)),D);
    D = min(length(.5*Hash2(F+vec2(-1,-1))+F-P+vec2(-1,-1)),D);
    return D;
}
//2D Simplex gradient noise.
//3D cases will be covered under this patent:
//https://en.wikipedia.org/wiki/Simplex_noise#Legal_status
float Simplex(vec2 P)
{
    //Skewing and "unskewing" constants as decribed here: https://en.wikipedia.org/wiki/Simplex_noise
    #define S (sqrt(.75)-.5)
    #define G (.5-inversesqrt(12.))
   
    //Calculate simplex cells.
    vec2 N = P+S*(P.x+P.y);
    vec2 F = floor(N);
    vec2 T = vec2(1,0)+vec2(-1,1)*step(N.x-F.x,N.y-F.y);
    
    //Distance to the nearest cells.
    vec2 A = F   -G*(F.x+F.y)-P;
    vec2 B = F+T -G*(F.x+F.y)-G-P;
    vec2 C = F+1.-G*(F.x+F.y)-G-G-P;
    
    //Calculate weights and apply quintic smoothing.
    vec3 I = max(.5-vec3(dot(A,A),dot(B,B),dot(C,C)),0.);
    I = I*I*I*(6.*I*I,-15.*I+10.);
    I /= dot(I,vec3(1));
    
    //Add up the gradients.
    return .5+(dot(Hash2(F),A)*I.x+
               dot(Hash2(F+T),B)*I.y+
               dot(Hash2(F+1.),C)*I.z);
}

//Output the noise types.
void main(void)
{
    vec2 Coord = gl_FragCoord.xy;
    vec4 Color = glFragColor;

    //Noise output float.
    float N = 0.;
    
    //Coordinates for the noise.
    vec2 P = Coord + 20.*time;
    
    //Centered coordinates for noise dividers.
    vec2 U = Coord-.5*resolution.xy;
    
    if (U.y>0.)
    {
        if (U.x<0.)
        {
            //Top-left: Fractal value noise.
            N = .4*Value(P/64.)+.3*Value(P/32.)+.2*Value(P/16.)+.1*Value(P/8.);
        }
        else
        {
            //Top-right: Fractal Perlin noise.
            N = .4*Perlin(P/64.)+.3*Perlin(P/32.)+.2*Perlin(P/16.)+.1*Perlin(P/8.);
        }
    }
    else
    {
        if (U.x<0.)
        {
            //Bottom-left: Fractal Worley noise.
            N = .4*Worley(P/64.)+.3*Worley(P/32.)+.2*Worley(P/16.)+.1*Worley(P/8.);
        }
        else
        {
            //Bottom-right: Fractal Simplex noise.
            N = .4*Simplex(P/64.)+.3*Simplex(P/32.)+.2*Simplex(P/16.)+.1*Simplex(P/8.);
        }
    }
    //Add the divider.
    N *= smoothstep(1.,2.,min(abs(U.x),abs(U.y)));
    
    Color = vec4(N,N,N,1);
    
    glFragColor = Color;
}
