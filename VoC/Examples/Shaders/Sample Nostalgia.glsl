// original https://www.shadertoy.com/view/ltScDh

#version 420

#extension GL_EXT_gpu_shader4 : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float grid (vec2 screenPos)
{
    float x = mod (screenPos.x - 0.024, 0.2);
    float y = mod (screenPos.y - 0.024, 0.2);
    return (x < 0.15 && y < 0.15) ? 1.0 : 0.0;
}

float background (vec2 screenPos, float t)
{
    float a = cos (3.0 * screenPos.x + 1.75);
    float b = sin (3.0 * screenPos.y);
    float c = cos (a + sin (b + t));
    float d = sin (b + cos (a + t));
    float e = 2.0 * cos (4.0 * c + t) * sin (4.0 * d + t);
    return (c + d) * e * 0.5; //  + 0.1 * grid (screenPos);
}

vec3 palette (float g)
{
    if (g < 0.0)
    {
        return vec3 (0.0, 0.0, 0.0);
    }
    else if (g < 0.5)
    {
        float p = g / 0.5;
        float q = 1.0 - p;
        vec3 c1 = vec3 (1.0, 0.5, 0.0);
        vec3 c2 = vec3 (0.0, 0.0, 1.0);
        return p * c1 + q * c2;
    }
    else
    {
        float p = (g - 0.5) / 0.5;
        float q = 1.0 - p;
        vec3 c1 = vec3 (0.0, 0.0, 1.0);
        vec3 c2 = vec3 (0.5, 1.0, 0.0);
        return p * c1 + q * c2;
    }
}

int LETTER_A[7] = int[](6, 9, 9, 15, 9, 9, 9);
int LETTER_B[7] = int[](14, 9, 9, 14, 9, 9, 14);
int LETTER_C[7] = int[](7, 8, 8, 8, 8, 8, 7);
int LETTER_D[7] = int[](14, 9, 9, 9, 9, 9, 14);
int LETTER_E[7] = int[](15, 8, 8, 14, 8, 8, 15);
int LETTER_F[7] = int[](15, 8, 8, 14, 8, 8, 8);
int LETTER_G[7] = int[](7, 8, 8, 11, 9, 9, 7);
int LETTER_H[7] = int[](9, 9, 9, 15, 9, 9, 9);
int LETTER_I[7] = int[](2, 0, 0, 6, 2, 2, 15);
int LETTER_J[7] = int[](15, 1, 1, 1, 2, 2, 12);
int LETTER_K[7] = int[](9, 10, 12, 12, 10, 9, 9);
int LETTER_L[7] = int[](8, 8, 8, 8, 8, 8, 15);
int LETTER_M[7] = int[](9, 15, 9, 9, 9, 9, 9);
int LETTER_N[7] = int[](9, 13, 11, 9, 9, 9, 9);
int LETTER_O[7] = int[](6, 9, 9, 9, 9, 9, 6);
int LETTER_P[7] = int[](14, 9, 9, 14, 8, 8, 8);
int LETTER_Q[7] = int[](6, 9, 9, 9, 9, 11, 7);
int LETTER_R[7] = int[](14, 9, 9, 14, 9, 9, 9);
int LETTER_S[7] = int[](7, 8, 8, 6, 1, 1, 14);
int LETTER_T[7] = int[](4, 15, 4, 4, 4, 4, 3);
int LETTER_U[7] = int[](9, 9, 9, 9, 9, 9, 6);
int LETTER_V[7] = int[](9, 9, 9, 9, 9, 5, 3);
int LETTER_W[7] = int[](9, 9, 9, 9, 9, 15, 9);
int LETTER_X[7] = int[](9, 9, 9, 6, 9, 9, 9);
int LETTER_Y[7] = int[](9, 9, 5, 6, 2, 2, 12);
int LETTER_Z[7] = int[](15, 1, 2, 6, 4, 8, 15);

float letter (vec2 screenPos, int offset, int arr[7])
{
    float t = mod (time, 26.0);
    float xoff = 1.4 + 0.19 * float (offset) - 0.4 * t;
    float x = (screenPos.x - xoff)*7.0;
    float y = (screenPos.y - 0.03)*7.0;
    
    if (x < 0.0 || x >= 1.0 || y < 0.0 || y >= 1.0)
    {
        return 0.0;
    }
    else
    {
        int px = 3 - int (floor (x * 4.0));
        int py = 6 - int (floor (y * 7.0));
        int val = arr[py];
        int bit = (1 << px) & val;
        return (bit > 0 ? 1.0 : 0.0);
    }
}

void main(void)
{
    vec2 screenPos = gl_FragCoord.xy / resolution.xy;
    float ratio = resolution.y / resolution.x;
    screenPos.x /= ratio;
    screenPos.x -= 0.5 * (resolution.x - resolution.y)
        / resolution.y;
    
    float g =
        letter (screenPos,  0, LETTER_T) +
        letter (screenPos,  1, LETTER_H) +
        letter (screenPos,  2, LETTER_I) +
        letter (screenPos,  3, LETTER_S) +

        letter (screenPos,  5, LETTER_I) +
        letter (screenPos,  6, LETTER_S) +

        letter (screenPos,  8, LETTER_A) +

        letter (screenPos, 10, LETTER_V) +
        letter (screenPos, 11, LETTER_E) +
        letter (screenPos, 12, LETTER_R) +
        letter (screenPos, 13, LETTER_Y) +

        letter (screenPos, 15, LETTER_S) +
        letter (screenPos, 16, LETTER_I) +
        letter (screenPos, 17, LETTER_M) +
        letter (screenPos, 18, LETTER_P) +
        letter (screenPos, 19, LETTER_L) +
        letter (screenPos, 20, LETTER_E) +

        letter (screenPos, 22, LETTER_D) +
        letter (screenPos, 23, LETTER_E) +
        letter (screenPos, 24, LETTER_M) +
        letter (screenPos, 25, LETTER_O) +

        letter (screenPos, 27, LETTER_F) +
        letter (screenPos, 28, LETTER_O) +
        letter (screenPos, 29, LETTER_R) +

        letter (screenPos, 31, LETTER_P) +
        letter (screenPos, 32, LETTER_U) +
        letter (screenPos, 33, LETTER_R) +
        letter (screenPos, 34, LETTER_E) +

        letter (screenPos, 36, LETTER_N) +
        letter (screenPos, 37, LETTER_O) +
        letter (screenPos, 38, LETTER_S) +
        letter (screenPos, 39, LETTER_T) +
        letter (screenPos, 40, LETTER_A) +
        letter (screenPos, 41, LETTER_L) +
        letter (screenPos, 42, LETTER_G) +
        letter (screenPos, 43, LETTER_I) +
        letter (screenPos, 44, LETTER_A);
        
    vec3 c;
    
    if (g > 0.0)
    {
        c = vec3 (g, g, g);
    }
    else
    {
        g = background (screenPos, time);
        c = palette (g);
        c = mix (c, vec3 (
            0.5 + 0.5 * sin (time),
            0.5 + 0.5 * cos (time),
            0.5),
        0.5);

        if (screenPos.y < 0.2 || screenPos.y > 0.8)
        {
            c.x /= 2.0;
            c.y /= 2.0;
            c.z /= 2.0;
        }
    }
    
    glFragColor = vec4 (c, 1.0);
    
}
