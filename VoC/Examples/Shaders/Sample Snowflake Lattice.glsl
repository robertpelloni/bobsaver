#version 420

// original https://www.shadertoy.com/view/7sG3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DEPTH 21
#define PHI ((1. + sqrt(5.)) / 2.)
#define PI 3.141592653589
//#define DEPTH int(round(16. - 7. * cos(time / 5.)))

#define S(M, O) (0.5 + 0.5 * sin(O + M * pos.x)) / 6.
#define C(M, O) (0.5 + 0.5 * cos(O + M * pos.y)) / 6.

vec2 rotate(vec2 v, float a)
{
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

bool onRight(vec2 a, vec2 b, vec2 x)
{
    return cross(vec3(a - b, 0), vec3(x - b, 0)).z > 0.;
}

float cr(vec2 a, vec2 b)
{
    return a.x * b.y - b.x * a.y;
}

float cr(vec2 a, vec2 b, vec2 c)
{
    return cr(b - a, c - b);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 pos = gl_FragCoord.xy / resolution.xx;
    
    float scale = 72. + 18. * sin(time / 10.) + 20. * sin(4. + time / 15.) + 30. * sin(time / 6.);
    vec2 camPos = vec2(0.5, 0.5);
    float SF = 1. / pow(scale, 0.3);
    camPos += vec2(0.02 * sin(time / 15.), -0.07 * cos(time / 19.)) * SF;
    camPos += vec2(-0.1 * sin(3. + time / 37.), -0.1 * cos(4. + time / 27.)) * SF;
    camPos += vec2(0.07 * sin(9. + time / 47.), -0.08 * cos(20. + time / 31.)) * SF;
    camPos += vec2(0.04 * sin(19. + time / 7.), 0.06 * cos(25. + time / 5.)) * SF;
    
    pos -= vec2(0.5, 0.5);
    pos = rotate(pos, time / 30. + PI * cos(time / 37.) + 2. * PI * sin(time / 87. + 10.));
    pos /= scale;
    pos += camPos;
    
    vec2 ota = vec2(-1., 0.);
    vec2 otb = vec2(2., 0.);
    
    vec2 ta = ota;
    vec2 tb = otb;
    vec2 tc;
    bool gn = true;
    float fl = -1.;
    
    float f = 0.;
    
    // vec2 otc;
    
    float nDark = 0.;
    
    for(int i = 0; i < DEPTH; i++)
    {
        vec2 next;
        if(gn)
            tc = ta + rotate(tb - ta, fl * PI / 5.) / PHI;
        else
            tc = ta + rotate(tb - ta, fl * 2. * PI / 5.) * PHI;
            
        if(!(gn && min(length(pos - ta), length(pos - tb)) > length(ta - tb) / 3. || \
          !gn && length(pos - tb) <= length(tc - tb) * PHI / 3.5))
        {
            nDark += 1.;
        }
        
        
        if(gn)
        {
            next = tb + (ta - tb) / PHI;
            if(abs(cr(next, tc, pos)) * float(i + 1) < 0.000001)
                f = 1.;
            if(cr(next, tc, pos) * cr(next, tc, tb) > 0.)//onRight(next, tc, pos))
            {
                gn = false;
                ta = next;
                tb = tc;
                fl *= -1.;
                i--;
            }
            else
            {
                gn = true;
                tb = ta;
                ta = tc;
            }
        }
        else
        {
            next = tc + (tb - tc) / PHI;
            if(abs(cr(ta, next, pos)) * float(i + 1) < 0.000001)
                f = 1.;
            if(cr(ta, next, pos) * cr(ta, next, tb) > 0.)//onRight(ta, next, pos))
            {
                gn = false;
                ta = tb;
                tb = next;
            }
            else
            {
                gn = true;
                tb = ta;
                ta = tc;
            }
        }
        //if(i == 0)
        //    otc = tc;
    }
    /*
    glFragColor =
        (1. - nDark / float(DEPTH)) * vec4(
            S(30., 0.) + C(10., 1.) + S(50., 6.) + S(99., 5.),
            C(90., 0.) + S(70., 2.) + C(73., 8.) + C(67., 19.),
            S(70., 0.5) + C(31., 7.) + S(55., 35.) + C(123., 5.),
            1.
        ) * 1.8 +
        (nDark / float(DEPTH)) * vec4(
            S(30., 10.) + C(10., 11.) + S(50., 16.) + S(99., 15.),
            C(20., 10.) + S(70., 12.) + C(23., 18.) + C(67., 119.),
            S(70., 10.5) + C(31., 17.) + S(55., 135.) + C(123., 15.),
            1.
        ) / 2.;
    */
    glFragColor =
        (nDark / float(DEPTH)) * vec4(
            0.10 + S(30., 10.) + C(10., 11.) + S(50., 16.) + S(99., 15.) + S(1., 42.) + C(1.5, 73.),
            0.10 + C(20., 10.) + S(70., 12.) + C(23., 18.) + C(67., 119.) + S(1.2, 49.) + C(0.9, 79.),
            0.15 + S(70., 10.5) + C(31., 17.) + S(55., 135.) + C(123., 15.) + S(0.7, 13.) + C(0.11, 31.),
            1.
        ) * 1.5;

    /*
    if(gn)
        tc = ta + rotate(tb - ta, fl * PI / 5.) / PHI;
    else
        tc = ta + rotate(tb - ta, fl * 2. * PI / 5.) * PHI;
    
    if(gn && min(length(pos - ta), length(pos - tb)) > length(ta - tb) / 3. || \
      !gn && length(pos - tb) <= length(tc - tb) * PHI / 3.5)
    {
        glFragColor = vec4(
            S(30., 0.) + C(10., 1.) + S(50., 6.) + S(99., 5.),
            C(90., 0.) + S(70., 2.) + C(73., 8.) + C(67., 19.),
            S(70., 0.5) + C(31., 7.) + S(55., 35.) + C(123., 5.),
            1.
        );
    }
    else
        glFragColor = vec4(
            S(30., 10.) + C(10., 11.) + S(50., 16.) + S(99., 15.),
            C(20., 10.) + S(70., 12.) + C(23., 18.) + C(67., 119.),
            S(70., 10.5) + C(31., 17.) + S(55., 135.) + C(123., 15.),
            1.
        ) / 2.;
        */
    
    // if(f > 0.) glFragColor = vec4(1, 0, 0, 1);
    
    /*
    if(length(uv - ota) <= 0.01)
        glFragColor += vec4(0.5, -0.5, -0.5, 0.0);
    if(length(uv - otb) <= 0.01)
        glFragColor += vec4(-0.5, 0.5, -0.5, 0.0);
    if(length(uv - otc) <= 0.01)
        glFragColor += vec4(-0.5, -0.5, 0.5, 0.0);
    */
}
