#version 420

// original https://www.shadertoy.com/view/fdlGzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float segment(vec2 P, vec2 A, vec2 B, float r) 

{

    vec2 g = B - A;

    vec2 h = P - A;

    float d = length(h - g * clamp(dot(g, h) / dot(g,g), 0.0, 1.0));

    return smoothstep(r, 0.5*r, d);

}

const vec3 backColor  = vec3(0.3);

const vec3 pointColor = vec3(1,0,0.51);

const vec3 lineColor = vec3(0.95,0.95,0.10);

void main(void) {

    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    //uv=gl_FragCoord.xy/resolution.xy;
    vec2 mouse = (mouse*resolution.xy.xy * 2.0 - resolution.xy) / resolution.y;
    //mouse =mouse*resolution.xy.xy/ resolution.y;

    vec3 color = backColor;
    
    
    int iterations=5;
    
    vec2 startPoint=vec2(0,0);
    
    int piece=5;
    
    vec2[] points=vec2[] (vec2(0,0),vec2(0,1),vec2(0,2),vec2(0,3),vec2(0,4),vec2(0,5));

    //vec2[] points=vec2[] (vec2(0,0),vec2(1,1),vec2(2,2),vec2(3,3),vec2(4,4),vec2(5,5));
    
    //vec2[] points=vec2[] (vec2(-5,-5),vec2(-3,-3),vec2(-1,-1),vec2(1,1),vec2(3,3),vec2(5,5));

    //vec2[] points=vec2[] (vec2(0,0),vec2(1,1),vec2(2,-2),vec2(3,3),vec2(4,-4),vec2(5,5));
    
    //vec2[] points=vec2[] (vec2(0,1),vec2(1,0),vec2(0,-1),vec2(-1,0),vec2(0,1),vec2(1,0));

    float[] lenghts=float[](0.3,0.25,0.2,0.15,0.1);
   
    
    for (int j=0;j<=iterations;j++){
        vec2 target=mouse;
        for (int i=piece;i>0;i--){
            points[i]=target;

            vec2 dir;
            dir=(target-points[i-1])/ length(target-points[i-1]);
            points[i-1] = target-(dir*lenghts[i-1]);

            target=points[i-1];
        }
        
        target=startPoint;
        for (int i=0;i<piece;i++){
            points[i]=target;

            vec2 dir;
            dir=(target-points[i+1])/ length(target-points[i+1]);
            points[i+1] = target-(dir*lenghts[i]);

            target=points[i+1];
        }
    }
    
    /*
    
        vec2 target=mouse;
        for (int i=piece;i>0;i--){
            points[i]=target;

            vec2 dir;
            dir=(target-points[i-1])/ length(target-points[i-1]);
            points[i-1] = target-(dir*lenghts[i-1]);

            target=points[i-1];
        }
        
    */
    float intensity;
    for (int i=piece;i>=1;i--){
        intensity = segment(uv, points[i],points[i-1], 0.01);
        color = mix(color, lineColor, intensity);
    }
    for (int i=piece;i>=0;i--){
        intensity = segment(uv, points[i],points[i], 0.02);
        color = mix(color, pointColor, intensity);
    }
    
    glFragColor = vec4(color, 1.0);
}
      
