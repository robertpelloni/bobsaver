#version 420

// original https://www.shadertoy.com/view/3sj3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TWO_PI = 6.28;
const float PI = 3.14;

vec4 drawShape(vec2 uv, vec2 position, int sides,float size, vec3 color) {
    uv -= vec2(position.x,position.y);
    // Angle from current pixel
      float a = atan(uv.x,uv.y)+PI;
    // radius from current pixel
     float r = 2.0*PI/float(sides);
      // modulate the distance
      float d = cos(floor(.5+a/r)*r-a)*length(uv);
    //define the edges, and make smooth
      vec4 shape = vec4(smoothstep(size+.01,size,d));
      //color the shape
    shape.rgb*=color;
    return shape;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),
           -sin(_angle),
            sin(_angle),
            cos(_angle));
}

void main(void)
{
    // normailze and adjsut for ratio
    vec2 res = resolution.xy,
    uv = (gl_FragCoord.xy*2.0-res ) / res.y;
    
    // rotate the space
    //uv = rotate2d(radians(180.0) ) * uv;
    uv = rotate2d( (time) ) * uv;
    
    //background color
       vec4 background = vec4(0.0);
      
    // draw shape
    float pathRadius = 1.0;
    float numberToPlot = 30.0;
    
    glFragColor=background;
    
    for(float i=0.0;i<TWO_PI;i+=TWO_PI/numberToPlot){
        uv = rotate2d( (time*.1) ) * uv+ i*.1;
        vec3 color = vec3(.3,.5*sin(i),.9);
          int sides = 3;
        float size = .05;
        vec2 position = vec2(cos(i+time*.5),sin(i+time));
        position*=pathRadius * (sin(time));
        
        vec4 shape = drawShape(uv,position,sides,size,color);    
        glFragColor += mix(background, shape, shape.a);
    
    }
    
    
}
