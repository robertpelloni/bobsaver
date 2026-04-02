#version 420

// original https://www.shadertoy.com/view/ltcyDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define CHROMAB

float height(vec2 uv)
{
    float curve = smoothstep(1.,0.,length(uv)) * .5;
    float sinus = .8-length(fract(uv*6.+time*4.)-.5);
    return curve * sinus;
}

float funnysphere(vec3 p)
{
    p.y *= 1.5;
    vec3 n = normalize(p);
    vec2 sg = p.xz / (1. + p.y);

    float offset = length(fract(sg*6.+time*4.)-.5)*.35;

    return length(p+vec3(0,.4,0))-1. + offset;
}

float _smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

float smin( float a, float b)
{
    return _smin(a,b,25.);
}

float metaballs(vec3 p)
{
    p -= vec3(0,.65,0);

    vec3 p0 = p + sin(vec3(2.13, 2.17, 2.37)*time)*.2;
    vec3 p1 = p + sin(vec3(2.15, 2.87, 2.57)*time)*.2;
    vec3 p2 = p + sin(vec3(2.11, 2.47, 2.97)*time)*.2;

    return smin(
        smin(
            length(p0)-.13,
            length(p1)-.13
          ),
          length(p2)-.13
    );
}

float scene(vec3 p)
{
    return smin(
        smin(
            p.y,
            funnysphere(p)
        ),
        metaballs(p)
      );
}

vec2 rotate(vec2 a, float b)
{
      float c = cos(b);
      float s = sin(b);
      return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
      );
}

void main(void) //WARNING - variables void (out vec4 out_color, vec2 gl_FragCoord.xy) need changing to glFragColor and gl_FragCoord
{
    vec4 out_color = glFragColor;
      vec2 uv = (gl_FragCoord.xy / resolution.xy) - .5;
      uv.x *= resolution.x / resolution.y;

#if defined(CHROMAB)
      for (int c = 0; c < 3; ++c)
      {
#endif
          vec3 cam = vec3(0,0,-5);
          vec3 dir = normalize(vec3(uv, 4));

          cam.xz = rotate(cam.xz, time*.2);
          dir.xz = rotate(dir.xz, time*.2);

          cam.y = .45;

        float t = 0.;
        int i = 0;
        for (i = 0; i< 100; ++i)
        {
            float k = scene(cam + dir * t);
            t += k * .3;
            if(k < .001)
                break;
        }
    
          vec3 h = cam + dir * t;
    
          vec2 o = vec2(.001, 0);
          vec3 n = normalize(vec3(
            scene(h+o.xyy)-scene(h-o.xyy),
            scene(h+o.yxy)-scene(h-o.yxy),
            scene(h+o.yyx)-scene(h-o.yyx)
          ));
    
          float fresnel = pow(1.-max(0.,dot(n,-dir)),5.)*.96+.04;
          #if defined(CHROMAB)
              out_color[c] = fresnel;
        #else
              out_color = vec4(fresnel);
        #endif

#if defined(CHROMAB)
        uv *= 1.02;
    }
#endif

    glFragColor = out_color;
}
