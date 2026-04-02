#version 420

// original https://www.shadertoy.com/view/3d3BRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 14.11.2020
// Bielsko-Biała, Poland, UE, Earth, Sol, Milky Way, Local Group, Laniakea :)

vec2 cMul(vec2 z, vec2 w)
{
    return vec2 (z.x*w.x - z.y*w.y, z.x*w.y + z.y*w.x);
}

vec2 cDiv(vec2 z, vec2 w)
{
    return vec2 (z.x*w.x + z.y*w.y, -z.x*w.y + z.y*w.x)/(w.x*w.x + w.y*w.y);
}

vec2 cMob(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d)
{
    return cDiv(cMul(a, z) + b, cMul(c, z) + d);
}

vec2 cMobI(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d)
{
    return cDiv(cMul(d, z) - b, -cMul(c, z) + a);
}

float cMod(vec2 z)
{
  float x = abs(z.x);
  float y = abs(z.y);
  float t = min(x, y);
  x = max(x, y);
  t = t / x;
  return x * sqrt(1.0 + t * t);
}

vec2 cSqrt (vec2 z)
{
  float t = sqrt(2.0 * (cMod(z) + (z.x >= 0.0 ? z.x : -z.x)));
  vec2 f = vec2(0.5 * t, abs(z.y) / t);

  if (z.x < 0.0) f.xy = f.yx;
  if (z.y < 0.0) f.y = -f.y;

  return f;
}

vec2 rot(vec2 v, float a)
{
    float ca = cos(a);
    float sa = sin(a);
    
    return vec2(ca*v.x + sa*v.y, -sa*v.x + ca*v.y);
}

vec3 fractal(vec2 p)
{   
    
    //--- basic constants ---//
    
    const vec2 O = vec2(1, 0);
    const vec2 I = vec2(0, -1);
    const float s3d2 = 0.5*sqrt(3.0);

    
    //--- moebius transform coefficients ---//
    
    const vec2 a = vec2(-0.5, -s3d2);
    const vec2 b = vec2(1.5, -s3d2);
    const vec2 c = vec2(0.5, s3d2);
    const vec2 d = vec2(1.5, -s3d2);

    
    //--- horizontal movement ---//
    
    vec2 z = p;
    
    //if (mouse*resolution.xy.z > 0.5)
    //{
    //    z.x += 40.0*(mouse*resolution.xy.x / resolution.x - 0.5);
    //}
    //else
    //{
        z.x += 0.2*time;
    //}

    
    //--- unrolling cardioid (two stages) ---//
    
    z = cMob(z, a, b, c, d);                // stage 1: unrolling disc
    z = 0.25 * (O - cMul(z + O, z + O));    // stage 2: transform cardioid into disc
    

    //--- generating "before unrolling" chessboard ---//
    
    vec2 q = floor(25.3*z);                    // checkboard size
    bool ch = mod(q.x + q.y, 2.0) == 0.0;

    
    //--- calculate fractal ---//
    
    float an = 0.0;
    
    p = z;
      
    for (float i = 0.0; i < 512.0; i++)
    {
        z = cMul(z, z) + p;                    // Mandelbrot formulae

        if (dot(z, z) > 4.0)
        {
            float f = 1.0 - i/512.0;
            f *= f;

            return vec3(f, 0.6*f*(ch?0.0:1.0), 0);    // outside color
        }
        
        an += z.x;
    }

    
    //--- inside color ---//
    
    an += time;
    return vec3(0.5 + 0.5 * sin(4.0*an));
}

void main(void)
{
    
    //--- calculate point coordinates ---//

    float ZOOM = 0.6;
    vec2    p  = ZOOM * (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;

    p.y += 0.26;
    p.x -= 1.0;

    
    //--- set final antialiased pixel color by accumulating samples ---//
    
    float a  = 2.0;                    // improves quality, use carefully (3-4 max), only ints!
    float o  = 1.0 / (4.0*a*a);
    float e  = 0.5 / min(resolution.x, resolution.y);    
    float ea =   e / a * ZOOM;
    
    vec3 fc = vec3(0.0);            // final color
    
    
    //--- that is why "a" variable must be choosen carefully :D ---//
    
    for (float j = -a; j < a; j++)
        for (float i = -a; i < a; i++)

            fc += o*fractal(p + ea*vec2(i, j));
        
    glFragColor = vec4(fc, 1.0); 
    
}
