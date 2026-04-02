#version 420

// original https://www.shadertoy.com/view/NtS3RD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 N22(vec2 p){
    vec3 a = fract(p.xyx*vec3(123.34,234.34,345.65));
    a+=dot(a,a+100.45);
    return fract(vec2 (a.x*a.y ,a.y*a.z));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec4 col = vec4(1.0);
    //col = texture(iChannel0,uv);
    float m = 0.0;
    float t = time;
    float minDist = 10.0;
    float cellIndex = 0.0 ;
    vec2 uv1  = uv *10.0 ;
    vec2 gv = fract(uv1);
    vec2 id = floor(uv1);

    for(int x =-1 ; x<=1 ; x++){
        for(int y =-1 ; y<=1 ; y++){
         vec2 offs = vec2 (x,y);
            vec2 n = N22(id+offs);
            vec2 p = sin(n*t*5.0)*0.5+0.5+offs;
            float d = length (gv-p);
            if(d<minDist){
                minDist = d;
            }

        }
    }
    col *= minDist;
    // Output to screen
    glFragColor = col;
}
