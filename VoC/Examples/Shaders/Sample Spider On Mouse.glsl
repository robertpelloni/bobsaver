#version 420

// original https://www.shadertoy.com/view/NdsGRB

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

const vec3 pointColor = vec3(0.15,0.1,0.1);

const vec3 targetsColor = vec3(0.9,0.9,1);

const vec3 lineColor = vec3(0,0,0);

void main(void) {

    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    //uv=gl_FragCoord.xy/resolution.xy;
    vec2 mouse = (mouse*resolution.xy.xy * 2.0 - resolution.xy) / resolution.y;
    //mouse =mouse*resolution.xy.xy/ resolution.y;

    vec3 color = backColor;
    
    vec2 targets[]=vec2[] (
                            vec2(.3,0),vec2(.4,.2),vec2(.7,.1),vec2(.2,-.6),vec2(-.8,.1),vec2(-.1,.2),
                            vec2(.5,.2),vec2(.1,.7),vec2(.7,.6),vec2(.3,-.2),vec2(.4,.1),vec2(-.6,.5),
                            vec2(.4,0),vec2(.2,.4),vec2(-.7,-.3),vec2(.2,-.6),vec2(-.8,.1),vec2(-.1,.2),
                            vec2(-.6,.2),vec2(-.4,.7),vec2(-.6,-.7),vec2(-.4,-.2),vec2(-.2,.1),vec2(-.1,.4)
                          
                          );
    
    float radius=.08;
    
    float dalte=3.1415926*2.0/8.0;
    for (float k=0.0;k<3.1415926*2.0;k+=dalte){
        float angle = k;
        vec2 pos;
        pos.x =cos(angle)*radius;
        pos.y = sin(angle)*radius;
        
        int iterations=6;

        vec2 startPoint=mouse+pos;
        
        float reach=3.5;
        
        float closestLength=10.0;
        vec2 closestPoint;
        for (int i=targets.length()-1;i>=0;i--)
        {
            if(closestLength>length(targets[i]-(mouse+pos*reach)))
            {
                closestLength=length(targets[i]-(mouse+pos*reach));
                closestPoint=targets[i];
            }
        }
        
        
        vec2 endPoint=closestPoint;
        
        int piece=3;

        vec2[] points=vec2[] (vec2(1,1),vec2(2,2),vec2(3,3),vec2(4,4));

        float[] lenghts=float[](0.3,0.25,0.1);

        for (int j=0;j<=iterations;j++){
            vec2 target=endPoint;
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
        
        for (int i=targets.length()-1;i>=0;i--){
            intensity = segment(uv, targets[i],targets[i], 0.02);
            color = mix(color, targetsColor, intensity);
        }
        for (int i=piece;i>=1;i--){
            intensity = segment(uv, points[i],points[i-1], 0.01);
            color = mix(color, lineColor, intensity);
        }
        
        for (int i=piece;i>=0;i--){
            intensity = segment(uv, points[i],points[i], 0.02);
            color = mix(color, pointColor, intensity);
        }
        
        
        intensity = segment(uv, mouse,mouse, radius+0.02);
        color = mix(color, pointColor, intensity);
        
    }
    glFragColor = vec4(color, 1.0);
}

    
