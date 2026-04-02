#version 420

// original https://www.shadertoy.com/view/MlByRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash2D(vec2 x) {
    return fract(sin(dot(x, vec2(13.454, 7.405)))*12.3043);
}

float voronoi2D(vec2 uv) {
    vec2 fl = floor(uv);
    vec2 fr = fract(uv);
    float res = 1.0;
    for( int j=-1; j<=1; j++ ) {
        for( int i=-1; i<=1; i++ ) {
            vec2 p = vec2(i, j);
            float h = hash2D(fl+p);
            vec2 vp = p-fr+h;
            float d = dot(vp, vp);
            
            res +=1.0/pow(d, 8.0);
        }
    }
    return pow( 1.0/res, 1.0/16.0 );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    
    
    float up = voronoi2D(uv * vec2(sin(time*1.5)+10.0, sin(time*1.2)+7.0) + vec2(-time/.7,sin(time*4.0)/10.0)  );

    float finalMask = up + (sin(time*10.0)*0.02) - (abs(uv.y - 0.5));
   
    
    
    vec3 dark = mix( vec3( 1.0, 0.2, 0), vec3( 1.0, 0.4, .0),  step(0.2,finalMask) ) ;
    vec3 light = mix( dark, vec3( 0.9, 0, .0),  step(0.3, finalMask) ) ;
    
    
    glFragColor.xyz = light;
}
