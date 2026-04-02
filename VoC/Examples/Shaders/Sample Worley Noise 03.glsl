#version 420

// original https://www.shadertoy.com/view/3dXyRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// worley noise
// dragonyhr https://www.shadertoy.com/view/tldGzr

#define pi 3.141592654

vec2 hash22(vec2 p)//Dave Hoskins https://www.shadertoy.com/view/4djSRW
{
    return fract(cos(p*mat2(-64.2,71.3,81.4,-29.8))*8321.3);
}

int worley_type(vec2 t)
{
     float grid = 3.;
    if(t.y<1.0/3.0) return 2; // worley
    if(t.y<2.0/grid) return 1; // manhattan worley
    if(t.y<3.0/grid) return 0; // chebyshev worley
}
                    
float Worley(vec2 q, float scale, float ftime)
{
    int wt = worley_type(q/resolution.xy);
    int f2t = 0;
    if(q.x/resolution.x > 0.5) f2t = 1;
    q = q/scale + ftime;
    float f1 = 9e9;
    float f2 = f1;
    for(int i = -1; i < 2; i++){
        for(int j = -1; j < 2; j++){
            vec2 p = floor(q) + vec2(i, j);
            vec2 h = hash22(p);
            vec2 g = p + 0.5+ 0.5 * sin(h*12.6);
            float d = f1;
            if(wt == 0) {
                d = distance(g,q);
            }else if(wt == 2) {
                float xx = abs(q.x-g.x);
                float yy = abs(q.y-g.y);
                d = max(xx, yy);
            } else{
                float xx = abs(q.x-g.x);
                float yy = abs(q.y-g.y);
                d = xx + yy;
            }
            if(d < f2){ f2 = d; }
            if(d < f1){f2 = f1; f1 = d; }
        }
    }
    if(f2t == 0)
        return f1;
    else
        return f2 - f1;
}

void main(void)
{
    glFragColor = vec4(vec3(Worley(gl_FragCoord.xy, 32.0f, time)),1.0);
}
