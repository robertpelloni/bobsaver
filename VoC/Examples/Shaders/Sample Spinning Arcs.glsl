#version 420

// original https://www.shadertoy.com/view/7scBR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI     3.14159265

struct Arc {
    float innerRadiusSqr;
    float outerRadiusSqr;
    float startingAngle;
    float endingAngle;
};

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    vec2 origin = resolution.xy / 2.0;
    vec2 dst = vec2(gl_FragCoord.xy.x - origin.x, gl_FragCoord.xy.y - origin.y);
    float dstSqr = pow(dst.x, 2.0) + pow(dst.y, 2.0);
    
    Arc arcs[10] = Arc[10](
      Arc(pow(90.0, 2.0), pow(100.0, 2.0), 0.0, mod(time * 100.0, 360.0)),
      Arc(pow(100.0, 2.0), pow(110.0, 2.0), 0.0, mod(time * 95.0, 360.0)),
      Arc(pow(110.0, 2.0), pow(120.0, 2.0), 0.0, mod(time * 90.0, 360.0)),
      Arc(pow(120.0, 2.0), pow(130.0, 2.0), 0.0, mod(time * 85.0, 360.0)),
      Arc(pow(130.0, 2.0), pow(140.0, 2.0), 0.0, mod(time * 80.0, 360.0)),
      Arc(pow(140.0, 2.0), pow(150.0, 2.0), 0.0, mod(time * 75.0, 360.0)),
      Arc(pow(150.0, 2.0), pow(160.0, 2.0), 0.0, mod(time * 70.0, 360.0)),
      Arc(pow(160.0, 2.0), pow(170.0, 2.0), 0.0, mod(time * 65.0, 360.0)),
      Arc(pow(170.0, 2.0), pow(180.0, 2.0), 0.0, mod(time * 60.0, 360.0)),
      Arc(pow(180.0, 2.0), pow(190.0, 2.0), 0.0, mod(time * 55.0, 360.0))
    );
    
    for (int i = 0; i < 10; i++) {
      Arc arc = arcs[i];
      
      if (dstSqr > arc.innerRadiusSqr && dstSqr < arc.outerRadiusSqr) {
        float radian = atan(dst.x, dst.y);
        
        if (radian < 0.0) {
          radian = PI + PI + radian;
        }
        
        float angle = radian * (180.0 / PI);
        
        if (angle >= arc.startingAngle && angle <= arc.endingAngle) {
          glFragColor = vec4(col,1.0);    
        } else {
          glFragColor = vec4(0.0);
        }
      }
    }
}
