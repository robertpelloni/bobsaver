#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NtSGzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// I thought, color pickers nowadays are
// pretty lame. There's always one color
// axis hidden under a slider, be it hue
// or saturation or something else.

// So I made this rectangle, which given
// enough resolution, is able to show
// every sRGB color at once.

// This shader maps each point on the 2D
// viewpoint onto a point on the 1D
// Hilbert line, then maps that point
// into 3D RGB space.

// The transposeToAxes part might be
// broken, so some parts of the colors
// do not transition propertly.

// (C) 2021 Xing Liu, GPL 3.

// transposeToAxes & axesToTranspose
// are based off of public domain code
// by John Skilling

ivec4 transposeToAxes(ivec4 A, int b, int n)    // position, #bits, dimension
{
    int N = 2 << (b - 1), P, Q, t;
    int i;
    // Gray decode by H ^ (H/2)
    t = A[n - 1] >> 1;
    for (i = n - 1; i > 0; i--) A[i] ^= A[i - 1];
    A[0] ^= t;
    // Undo excess work
    for (Q = 2; Q != N; Q <<= 1)
    {
        P = Q - 1;
        for (i = n - 1; i >= 0; i--)
            if ((A[i] &Q) == 1) A[0] ^= P;    // invert
            else
            {
                t = (A[0] ^ A[i]) &P;
                A[0] ^= t;
                A[i] ^= t;
            }
    }    // exchange
    return A;
}
ivec4 axesToTranspose(ivec4 A, int b, int n)    // position, #bits, dimension
{
    int M = 1 << (b - 1), P, Q, t;
    int i;
    // Inverse undo
    for (Q = M; Q > 1; Q >>= 1)
    {
        P = Q - 1;
        for (i = 0; i < n; i++)
            if ((A[i] &Q) == 1) A[0] ^= P;    // invert
            else
            {
                t = (A[0] ^ A[i]) &P;
                A[0] ^= t;
                A[i] ^= t;
            }
    }    // exchange
    // Gray encode
    for (i = 1; i < n; i++) A[i] ^= A[i - 1];
    t = 0;
    for (Q = M; Q > 1; Q >>= 1)
        if ((A[n - 1] &Q) == 1) t ^= Q - 1;
    for (i = 0; i < n; i++) A[i] ^= t;
    return A;
}
int transposeToInt(ivec4 A, int b, int n)
{
    int x = 0, i, j;
    for (i = 0; i < b; i++)
        for (j = 0; j < n; j++)
            x += (A[j] >> i &1) << ((i + 1) *n - (j + 1));    // digit << place
    return x;
}
ivec4 intToTranspose(int x, int b, int n)
{
    ivec4 A = ivec4(0,0,0,0);
    int i, j;
    for (i = 0; i < b; i++)
        for (j = 0; j < n; j++)
            A[n - j - 1] += ((x >> (i *n + j)) &1) << i; // I have no idea how I solved this inverse
    return A;
}
void main(void)
{
    int bits = 16;
    float scale = float(1<<bits);
    vec2 position = gl_FragCoord.xy/resolution.xy;
        
    ivec4 uv = ivec4(position*float(bits*bits),0,0);
    
    vec3 col = vec3(
        transposeToAxes(
            intToTranspose(
                transposeToInt(
                    axesToTranspose(
                        uv, bits, 2
                    ), bits, 2
                ), bits, 3
            ), bits, 3
        )
    ) / scale;

    glFragColor = vec4(col, 1.0);
}
